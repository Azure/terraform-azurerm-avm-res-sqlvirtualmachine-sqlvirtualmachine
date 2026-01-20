# Availability Group Listener resource
resource "azapi_resource" "this" {
  name      = var.name
  parent_id = var.sql_virtual_machine_group_id
  type      = "Microsoft.SqlVirtualMachine/sqlVirtualMachineGroups/availabilityGroupListeners@2023-10-01"
  body = {
    properties = {
      availabilityGroupName                    = var.availability_group_name
      port                                     = var.port
      createDefaultAvailabilityGroupIfNotExist = var.create_default_availability_group_if_not_exist
      loadBalancerConfigurations               = var.load_balancer_configurations
      availabilityGroupConfiguration           = var.availability_group_configuration
    }
  }
}
