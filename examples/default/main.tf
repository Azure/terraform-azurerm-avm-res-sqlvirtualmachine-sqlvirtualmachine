terraform {
  required_version = "~> 1.5"

  required_providers {
    azapi = {
      source  = "Azure/azapi"
      version = "~> 2.4"
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

provider "azurerm" {
  features {}
}

provider "azapi" {}

## Section to provide a random Azure region for the resource group
# This allows us to randomize the region for the resource group.
module "regions" {
  source  = "Azure/avm-utl-regions/azurerm"
  version = "0.9.3"

  enable_telemetry       = var.enable_telemetry
  has_availability_zones = true
  is_recommended         = true
  use_cached_data        = true
}

# This allows us to randomize the region for the resource group.
resource "random_integer" "region_index" {
  max = length(module.regions.regions) - 1
  min = 0
}
## End of section to provide a random Azure region for the resource group

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

# Create a Windows VM with SQL Server
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
        imageReference = {
          publisher = "MicrosoftSQLServer"
          offer     = "sql2019-ws2019"
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
}

# This is the module call for SQL Virtual Machine
module "test" {
  source = "../../"

  location                    = azapi_resource.resource_group.location
  name                        = azapi_resource.windows_virtual_machine.name
  resource_group_name         = azapi_resource.resource_group.name
  virtual_machine_resource_id = azapi_resource.windows_virtual_machine.id
  enable_telemetry            = var.enable_telemetry
  sql_image_offer             = "SQL2019-WS2019"
  sql_image_sku               = "Developer"
  sql_management              = "Full"
  sql_server_license_type     = "PAYG"
}

