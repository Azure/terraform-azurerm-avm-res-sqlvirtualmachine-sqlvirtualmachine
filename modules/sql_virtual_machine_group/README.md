# SQL Virtual Machine Group Submodule

This submodule creates an Azure SQL Virtual Machine Group resource for configuring Windows Server Failover Cluster (WSFC) for SQL Server Always On availability groups.

## Usage

```hcl
module "sql_vm_group" {
  source = "../../modules/sql_virtual_machine_group"

  name                = "my-sql-vm-group"
  location            = "eastus"
  resource_group_name = "my-resource-group"
  subscription_id     = "00000000-0000-0000-0000-000000000000"
  sql_image_offer     = "SQL2019-WS2019"
  sql_image_sku       = "Enterprise"
  
  wsfc_domain_profile = {
    domain_fqdn                  = "contoso.com"
    cluster_bootstrap_account    = "domain\\account"
    cluster_operator_account     = "domain\\operator"
    sql_service_account          = "domain\\sqlservice"
    storage_account_url          = "https://mystorageaccount.blob.core.windows.net/"
    storage_account_primary_key  = "storage-key"
  }
  
  tags = {
    environment = "production"
  }
}
```

## Features

- Creates SQL Virtual Machine Groups for Always On availability groups
- Supports Windows Server Failover Cluster (WSFC) configuration
- Configurable cluster subnet types (SingleSubnet or MultiSubnet)
