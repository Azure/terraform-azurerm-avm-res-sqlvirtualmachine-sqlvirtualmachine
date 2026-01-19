# Availability Group Listener Submodule

This submodule creates an Azure Availability Group Listener for SQL Server Always On availability groups.

## Usage

```hcl
module "ag_listener" {
  source = "../../modules/availability_group_listener"

  name                          = "my-ag-listener"
  sql_virtual_machine_group_id  = module.sql_vm_group.resource_id
  availability_group_name       = "MyAvailabilityGroup"
  port                          = 1433
  
  load_balancer_configurations = [{
    private_ip_address = {
      ip_address         = "10.0.0.10"
      subnet_resource_id = "/subscriptions/.../subnets/default"
    }
    probe_port                    = 59999
    sql_virtual_machine_instances = [
      "/subscriptions/.../sqlVirtualMachines/sqlvm1",
      "/subscriptions/.../sqlVirtualMachines/sqlvm2"
    ]
  }]
}
```

## Features

- Creates Availability Group Listeners for SQL Server Always On
- Supports load balancer configuration
- Configurable listener port
- Supports multiple SQL Virtual Machine instances
