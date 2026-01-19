# Availability Group Listener Submodule

This submodule manages [Availability Group Listeners](https://learn.microsoft.com/en-us/azure/azure-sql/virtual-machines/windows/availability-group-listener-powershell-configure) (`Microsoft.SqlVirtualMachine/sqlVirtualMachineGroups/availabilityGroupListeners`) for SQL Server Always On Availability Groups running on Azure Virtual Machines.

An availability group listener provides client connectivity to a SQL Server Always On availability group. The listener enables automatic failover and load balancing across replicas.

## Features

- Configure listener name and port
- Set up load balancer configurations for connectivity
- Configure availability group settings
- Optionally create a default availability group if one doesn't exist
