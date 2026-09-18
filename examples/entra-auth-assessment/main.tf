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

# Assign Directory Readers role to the managed identity for Microsoft Graph API access
# This is required for Azure AD authentication in SQL Server
# The Directory Readers role allows the identity to read directory data from Microsoft Entra ID
data "azuread_directory_roles" "directory_readers" {}

locals {
  directory_readers_role_id = [for role in data.azuread_directory_roles.directory_readers.roles : role.object_id if role.display_name == "Directory Readers"][0]
}

resource "azuread_directory_role_assignment" "sql_identity_directory_readers" {
  principal_object_id = azapi_resource.user_assigned_identity.output.properties.principalId
  role_id             = local.directory_readers_role_id
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

# Create a Key Vault for SQL Server integration using AVM module
module "keyvault" {
  source  = "Azure/avm-res-keyvault-vault/azurerm"
  version = "0.10.2"

  location            = azapi_resource.resource_group.location
  name                = module.naming.key_vault.name_unique
  resource_group_name = azapi_resource.resource_group.name
  tenant_id           = data.azapi_client_config.current.tenant_id
  enable_telemetry    = var.enable_telemetry
  # Access policies for SQL Server integration
  legacy_access_policies = {
    # Access policy for the user-assigned identity (SQL Server)
    sql_identity = {
      object_id          = azapi_resource.user_assigned_identity.output.properties.principalId
      key_permissions    = ["Get", "List", "WrapKey", "UnwrapKey"]
      secret_permissions = ["Get", "List"]
    }
    # Access policy for the Key Vault service principal
    keyvault_sp = {
      object_id          = azuread_service_principal.keyvault_sp.object_id
      key_permissions    = ["Get", "List", "WrapKey", "UnwrapKey"]
      secret_permissions = ["Get", "List"]
    }
  }
  legacy_access_policies_enabled = true
  purge_protection_enabled       = false
  sku_name                       = "standard"
  soft_delete_retention_days     = 7
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
    type = "SystemAssigned, UserAssigned"
    identity_ids = [
      azapi_resource.user_assigned_identity.id
    ]
  }
}

# Install the AADLoginForWindows extension to enable Microsoft Entra sign-in to the VM
# This allows users to RDP to the VM using their Entra ID credentials
# Reference: https://learn.microsoft.com/en-us/entra/identity/devices/howto-vm-sign-in-azure-ad-windows
resource "azapi_resource" "aad_login_extension" {
  location  = azapi_resource.resource_group.location
  name      = "AADLoginForWindows"
  parent_id = azapi_resource.windows_virtual_machine.id
  type      = "Microsoft.Compute/virtualMachines/extensions@2024-03-01"
  body = {
    properties = {
      publisher               = "Microsoft.Azure.ActiveDirectory"
      type                    = "AADLoginForWindows"
      typeHandlerVersion      = "2.0"
      autoUpgradeMinorVersion = true
    }
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
  automatic_upgrade_enabled = true
  enable_telemetry          = var.enable_telemetry
  # Azure Key Vault integration using the service principal credentials
  # The service principal password is write-only and ephemeral
  key_vault_credential_settings = {
    enable                   = true
    azure_key_vault_url      = module.keyvault.uri
    credential_name          = "SqlKeyVaultCredential"
    service_principal_name   = azuread_application.keyvault_sp.client_id
    service_principal_secret = azuread_application_password.keyvault_sp.value
  }
  # Enable least privilege mode for better security
  least_privilege_mode = "Enabled"
  # SQL Server configuration settings
  # NOTE: Azure AD authentication cannot be enabled during initial SQL VM provisioning.
  # It must be configured after the SQL VM is created using azapi_update_resource.
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
  # Reference the user-assigned identity from the underlying VM for SQL Server to use
  virtual_machine_identity_settings = {
    type        = "UserAssigned"
    resource_id = azapi_resource.user_assigned_identity.id
  }
}

# Enable Microsoft Entra (Azure AD) authentication after SQL VM is created
# Azure does not support enabling Azure AD authentication during initial provisioning
# This update resource enables it after the SQL VM is successfully created
resource "azapi_update_resource" "enable_entra_auth" {
  name      = module.test.name
  parent_id = "/subscriptions/${data.azapi_client_config.current.subscription_id}/resourceGroups/${azapi_resource.resource_group.name}"
  type      = "Microsoft.SqlVirtualMachine/sqlVirtualMachines@2023-10-01"
  body = {
    properties = {
      serverConfigurationsManagementSettings = {
        azureAdAuthenticationSettings = {
          # Use empty string "" for system-assigned identity, or specify the client ID of a user-assigned identity
          clientId = azapi_resource.user_assigned_identity.output.properties.clientId
        }
      }
    }
  }

  depends_on = [module.test]
}
