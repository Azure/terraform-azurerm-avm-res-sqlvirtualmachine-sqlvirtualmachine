terraform {
  required_version = "~> 1.5"

  required_providers {
    azapi = {
      source  = "Azure/azapi"
      version = "~> 2.4"
    }
  }
}

# Availability Group Listener resource
resource "azapi_resource" "this" {
  type      = "Microsoft.SqlVirtualMachine/sqlVirtualMachineGroups/availabilityGroupListeners@2023-10-01"
  name      = var.name
  parent_id = var.sql_virtual_machine_group_id

  body = {
    properties = {
      availabilityGroupName = var.availability_group_name
      port                  = var.port
      createDefaultAvailabilityGroupIfNotExist = var.create_default_availability_group_if_not_exist
      loadBalancerConfigurations = var.load_balancer_configurations
      availabilityGroupConfiguration = var.availability_group_configuration
    }
  }
}
