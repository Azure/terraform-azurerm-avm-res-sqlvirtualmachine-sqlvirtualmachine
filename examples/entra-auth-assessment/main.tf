terraform {
  required_version = "~> 1.5"

  required_providers {
    azapi = {
      source  = "Azure/azapi"
      version = "~> 2.4"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 3.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }
}

provider "azapi" {}

provider "azuread" {}

provider "azurerm" {
  features {}
}

## Section to provide a random Azure region for the resource group
module "regions" {
  source  = "Azure/avm-utl-regions/azurerm"
  version = "0.9.3"

  enable_telemetry       = var.enable_telemetry
  has_availability_zones = true
  is_recommended         = true
  use_cached_data        = true
}

resource "random_integer" "region_index" {
  max = length(module.regions.regions) - 1
  min = 0
}

# This ensures we have unique CAF compliant names for our resources.
module "naming" {
  source  = "Azure/naming/azurerm"
  version = "0.4.3"
}

# Generate a random password for the VM admin
resource "random_password" "admin_password" {
  length           = 22
  min_lower        = 2
  min_numeric      = 2
  min_special      = 2
  min_upper        = 2
  override_special = "!@#$%&*()-_=+[]{}:?"
  special          = true
}

# This is required for resource modules
resource "azapi_resource" "resource_group" {
  location = module.regions.regions[random_integer.region_index.result].name
  name     = module.naming.resource_group.name_unique
  type     = "Microsoft.Resources/resourceGroups@2024-03-01"
}

# Create a virtual network for the example
resource "azapi_resource" "virtual_network" {
  location  = azapi_resource.resource_group.location
  name      = module.naming.virtual_network.name_unique
  parent_id = azapi_resource.resource_group.id
  type      = "Microsoft.Network/virtualNetworks@2024-01-01"
  body = {
    properties = {
      addressSpace = {
        addressPrefixes = ["10.0.0.0/16"]
      }
      subnets = [
        {
          name = "subnet-default"
          properties = {
            addressPrefix = "10.0.1.0/24"
          }
        }
      ]
    }
  }
  response_export_values = ["properties.subnets"]
}

# Create a network interface for the VM
resource "azapi_resource" "network_interface" {
  location  = azapi_resource.resource_group.location
  name      = module.naming.network_interface.name_unique
  parent_id = azapi_resource.resource_group.id
  type      = "Microsoft.Network/networkInterfaces@2024-01-01"
  body = {
    properties = {
      ipConfigurations = [
        {
          name = "internal"
          properties = {
            privateIPAllocationMethod = "Dynamic"
            subnet = {
              id = "${azapi_resource.virtual_network.id}/subnets/subnet-default"
            }
          }
        }
      ]
    }
  }
}

# Create a user-assigned managed identity for Microsoft Entra authentication
resource "azapi_resource" "user_assigned_identity" {
  location  = azapi_resource.resource_group.location
  name      = module.naming.user_assigned_identity.name_unique
  parent_id = azapi_resource.resource_group.id
  type      = "Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31"
}

# Create an Azure AD Application and Service Principal for Key Vault integration
resource "azuread_application" "keyvault_sp" {
  display_name = "sql-kv-integration-${module.naming.unique-seed}"
}

resource "azuread_service_principal" "keyvault_sp" {
  client_id = azuread_application.keyvault_sp.client_id
}

# Create a service principal password for Key Vault access
# The password value is write-only and ephemeral - it can only be used during apply
resource "azuread_application_password" "keyvault_sp" {
  application_id = azuread_application.keyvault_sp.id
  display_name   = "SQL Key Vault Integration"
  end_date       = timeadd(timestamp(), "8760h") # 1 year from now

  lifecycle {
    ignore_changes = [end_date]
  }
}

# Create a Key Vault for SQL Server integration (using azurerm for better integration)
resource "azurerm_key_vault" "this" {
  location                   = azapi_resource.resource_group.location
  name                       = module.naming.key_vault.name_unique
  resource_group_name        = azapi_resource.resource_group.name
  sku_name                   = "standard"
  tenant_id                  = data.azapi_client_config.current.tenant_id
  rbac_authorization_enabled = false
  soft_delete_retention_days = 7
  purge_protection_enabled   = false
}

# Access policy for the user-assigned identity (SQL Server)
resource "azurerm_key_vault_access_policy" "sql_identity" {
  key_vault_id = azurerm_key_vault.this.id
  tenant_id    = data.azapi_client_config.current.tenant_id
  object_id    = azapi_resource.user_assigned_identity.output.properties.principalId

  key_permissions = [
    "Get", "List", "WrapKey", "UnwrapKey"
  ]
  secret_permissions = [
    "Get", "List"
  ]
}

# Access policy for the Key Vault service principal
resource "azurerm_key_vault_access_policy" "keyvault_sp" {
  key_vault_id = azurerm_key_vault.this.id
  tenant_id    = data.azapi_client_config.current.tenant_id
  object_id    = azuread_service_principal.keyvault_sp.object_id

  key_permissions = [
    "Get", "List", "WrapKey", "UnwrapKey"
  ]
  secret_permissions = [
    "Get", "List"
  ]
}

data "azapi_client_config" "current" {}

# Create a Windows VM with SQL Server 2022 (required for Microsoft Entra authentication)
resource "azapi_resource" "windows_virtual_machine" {
  location  = azapi_resource.resource_group.location
  name      = module.naming.virtual_machine.name_unique
  parent_id = azapi_resource.resource_group.id
  type      = "Microsoft.Compute/virtualMachines@2024-03-01"
  body = {
    zones = ["1"]
    properties = {
      hardwareProfile = {
        vmSize = "Standard_D2s_v3"
      }
      osProfile = {
        computerName  = module.naming.virtual_machine.name_unique
        adminUsername = "adminuser"
        adminPassword = random_password.admin_password.result
        windowsConfiguration = {
          provisionVMAgent       = true
          enableAutomaticUpdates = true
        }
      }
      networkProfile = {
        networkInterfaces = [
          {
            id = azapi_resource.network_interface.id
            properties = {
              primary = true
            }
          }
        ]
      }
      storageProfile = {
        # SQL Server 2022 is required for Microsoft Entra authentication
        imageReference = {
          publisher = "MicrosoftSQLServer"
          offer     = "sql2022-ws2022"
          sku       = "sqldev-gen2"
          version   = "latest"
        }
        osDisk = {
          createOption = "FromImage"
          caching      = "ReadWrite"
          managedDisk = {
            storageAccountType = "Premium_LRS"
          }
        }
      }
    }
  }

  identity {
    type = "UserAssigned"
    identity_ids = [
      azapi_resource.user_assigned_identity.id
    ]
  }
}

# This is the module call for SQL Virtual Machine with Microsoft Entra auth and Assessment
module "test" {
  source = "../../"

  location                    = azapi_resource.resource_group.location
  name                        = azapi_resource.windows_virtual_machine.name
  resource_group_name         = azapi_resource.resource_group.name
  virtual_machine_resource_id = azapi_resource.windows_virtual_machine.id
  # SQL best practices assessment settings
  # Runs SQL Assessment to identify potential issues and best practice recommendations
  assessment_settings = {
    enable          = true
    run_immediately = true
    schedule = {
      enable          = true
      day_of_week     = "Sunday"
      start_time      = "02:00"
      weekly_interval = 1
    }
  }
  # Enable automatic upgrade for SQL IaaS Agent
  enable_automatic_upgrade = true
  enable_telemetry         = var.enable_telemetry
  # Azure Key Vault integration using the service principal credentials
  # The service principal password is write-only and ephemeral
  key_vault_credential_settings = {
    enable                   = true
    azure_key_vault_url      = azurerm_key_vault.this.vault_uri
    credential_name          = "SqlKeyVaultCredential"
    service_principal_name   = azuread_application.keyvault_sp.client_id
    service_principal_secret = azuread_application_password.keyvault_sp.value
  }
  # Enable least privilege mode for better security
  least_privilege_mode = "Enabled"
  # Reference the user-assigned identity from the underlying VM for SQL Server to use
  virtual_machine_identity_settings = {
    type        = "UserAssigned"
    resource_id = azapi_resource.user_assigned_identity.id
  }
  # Microsoft Entra authentication settings (requires SQL Server 2022+)
  # IMPORTANT: Azure AD authentication cannot be enabled during initial SQL VM provisioning.
  # It must be enabled after the SQL VM is created. To enable it:
  # 1. First apply without azure_ad_authentication_settings
  # 2. Then uncomment and apply again to enable Entra authentication
  # azure_ad_authentication_settings = {
  #   client_id = azapi_resource.user_assigned_identity.output.properties.clientId
  # }
  server_configurations_management_settings = {
    sql_instance_settings = {
      max_dop              = 4
      max_server_memory_mb = 2048
      min_server_memory_mb = 256
    }
    sql_connectivity_update_settings = {
      connectivity_type = "PRIVATE"
      port              = 1433
    }
  }
  # SQL Server 2022 configuration
  sql_image_offer         = "SQL2022-WS2022"
  sql_image_sku           = "Developer"
  sql_management          = "Full"
  sql_server_license_type = "PAYG"
}
