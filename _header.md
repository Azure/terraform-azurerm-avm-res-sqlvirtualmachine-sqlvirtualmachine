# terraform-azurerm-avm-res-sqlvirtualmachine-sqlvirtualmachine

Terraform Azure Verified Resource Module to manage [Azure SQL Virtual Machine](https://learn.microsoft.com/en-us/azure/azure-sql/virtual-machines/windows/sql-server-on-azure-vm-iaas-what-is-overview) (`Microsoft.SqlVirtualMachine/sqlVirtualMachines`).

Azure SQL Virtual Machine enables you to use full versions of SQL Server in the cloud hosted on Windows Server virtual machines. Registering your SQL Server VM with the SQL IaaS Agent Extension unlocks features such as automated patching, automated backup, and simplified license management.

## Features

This module supports the following capabilities:

- **SQL Server License Types**: Configure Azure Hybrid Benefit (AHUB), Pay-As-You-Go (PAYG), or Disaster Recovery (DR) licensing.
- **SQL Management Modes**: Full, LightWeight, or NoAgent management modes for different feature and overhead requirements.
- **SQL Server Editions**: Support for Developer, Express, Standard, Enterprise, and Web SKUs.
- **Managed Identities**: System-assigned and user-assigned managed identity support.
- **Resource Locks**: CanNotDelete or ReadOnly locks to protect the resource.
- **Role Assignments**: Azure RBAC role assignments directly on the SQL Virtual Machine resource.
- **AVM Telemetry**: Optional telemetry to help improve Azure Verified Modules.

## Prerequisites

- An existing Azure Virtual Machine with SQL Server installed (from Azure Marketplace SQL Server images).
- The VM must be running a supported Windows Server version.
