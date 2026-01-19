# SQL Virtual Machine Group Submodule

This submodule manages [SQL Virtual Machine Groups](https://learn.microsoft.com/en-us/azure/azure-sql/virtual-machines/windows/availability-group-az-commandline-configure) (`Microsoft.SqlVirtualMachine/sqlVirtualMachineGroups`) for SQL Server Always On Availability Groups.

A SQL Virtual Machine Group represents a Windows Server Failover Cluster (WSFC) that hosts SQL Server VMs participating in an Always On Availability Group. This resource configures the cluster domain profile and SQL Server image settings.

## Features

- Configure Windows Server Failover Cluster (WSFC) domain profile
- Set SQL Server image offer and SKU
- Define cluster operator, bootstrap, and storage accounts
- Configure cluster subnet type and domain FQDN
