terraform {
  required_version = "~> 1.5"

  required_providers {
    azapi = {
      source  = "Azure/azapi"
      version = "~> 2.4"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }
}

provider "azapi" {}

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

# Create a Key Vault for SQL Server integration
resource "azapi_resource" "key_vault" {
  location  = azapi_resource.resource_group.location
  name      = module.naming.key_vault.name_unique
  parent_id = azapi_resource.resource_group.id
  type      = "Microsoft.KeyVault/vaults@2023-07-01"
  body = {
    properties = {
      sku = {
        family = "A"
        name   = "standard"
      }
      tenantId                     = data.azapi_client_config.current.tenant_id
      enabledForDeployment         = true
      enabledForTemplateDeployment = true
      enableSoftDelete             = true
      softDeleteRetentionInDays    = 7
      accessPolicies = [
        {
          tenantId = data.azapi_client_config.current.tenant_id
          objectId = azapi_resource.user_assigned_identity.output.properties.principalId
          permissions = {
            keys    = ["Get", "List", "WrapKey", "UnwrapKey"]
            secrets = ["Get", "List"]
          }
        }
      ]
    }
  }
  response_export_values = ["properties.vaultUri"]
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
          sku       = "sqldev"
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
  # Azure Key Vault integration settings
  # Allows SQL Server to connect to Azure Key Vault for encryption keys and secrets
  key_vault_credential_settings = {
    enable              = true
    azure_key_vault_url = azapi_resource.key_vault.output.properties.vaultUri
    credential_name     = "SqlKeyVaultCredential"
    # Note: In production, use a service principal or managed identity
    # service_principal_name and service_principal_secret would be set here
  }
  # Enable least privilege mode for better security
  least_privilege_mode = "Enabled"
  # Reference the user-assigned identity from the underlying VM for SQL Server to use
  # This is used for Microsoft Entra authentication and Key Vault integration
  virtual_machine_identity_settings = {
    type        = "UserAssigned"
    resource_id = azapi_resource.user_assigned_identity.id
  }
  # Microsoft Entra authentication settings (requires SQL Server 2022+)
  # Uses the user-assigned managed identity to query Microsoft Graph API
  server_configurations_management_settings = {
    azure_ad_authentication_settings = {
      # Use empty string "" for system-assigned identity, or specify the client ID of a user-assigned identity
      client_id = azapi_resource.user_assigned_identity.output.properties.clientId
    }
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
