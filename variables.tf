# SQL Virtual Machine specific variables

variable "location" {
  type        = string
  description = "Azure region where the resource should be deployed."
  nullable    = false
}

variable "name" {
  type        = string
  description = "The name of the SQL Virtual Machine."

  validation {
    condition     = can(regex("^[a-zA-Z0-9-]{1,128}$", var.name))
    error_message = "The name must be between 1 and 128 characters long and can only contain letters, numbers, and hyphens."
  }
}

# This is required for most resource modules
variable "resource_group_name" {
  type        = string
  description = "The resource group where the resources will be deployed."
}

variable "virtual_machine_resource_id" {
  type        = string
  description = "The resource ID of the Azure Virtual Machine that this SQL Virtual Machine will be associated with."
  nullable    = false
}

variable "assessment_settings" {
  type = object({
    enable          = optional(bool)
    run_immediately = optional(bool)
    schedule = optional(object({
      day_of_week        = optional(string)
      enable             = optional(bool)
      monthly_occurrence = optional(number)
      start_time         = optional(string)
      weekly_interval    = optional(number)
    }))
  })
  default     = null
  description = <<DESCRIPTION
SQL best practices assessment settings for the SQL Virtual Machine.

- `enable` - (Optional) Enable or disable SQL best practices Assessment feature on SQL virtual machine.
- `run_immediately` - (Optional) Run SQL best practices Assessment immediately on SQL virtual machine.
- `schedule` - (Optional) Schedule for the assessment:
  - `day_of_week` - Day of the week to run assessment. Possible values: 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'.
  - `enable` - Enable or disable assessment schedule on SQL virtual machine.
  - `monthly_occurrence` - Occurrence of the DayOfWeek day within a month to schedule assessment. Takes values: 1,2,3,4 and -1. Use -1 for last DayOfWeek day of the month.
  - `start_time` - Time of the day in HH:mm format. Eg. 17:30.
  - `weekly_interval` - Number of weeks to schedule between 2 assessment runs. Takes value from 1-6.
DESCRIPTION
}

variable "auto_backup_settings" {
  type = object({
    enable                   = bool
    backup_schedule_type     = optional(string)
    backup_system_dbs        = optional(bool)
    days_of_week             = optional(list(string))
    enable_encryption        = optional(bool)
    full_backup_frequency    = optional(string)
    full_backup_start_time   = optional(number)
    full_backup_window_hours = optional(number)
    log_backup_frequency     = optional(number)
    password                 = optional(string)
    retention_period         = optional(number)
    storage_access_key       = optional(string)
    storage_account_url      = optional(string)
    storage_container_name   = optional(string)
  })
  default     = null
  description = <<DESCRIPTION
Automated backup settings for the SQL Virtual Machine.

- `enable` - (Required) Enable or disable autobackup on SQL virtual machine.
- `backup_schedule_type` - (Optional) Backup schedule type. Possible values: 'Manual', 'Automated'.
- `backup_system_dbs` - (Optional) Include or exclude system databases from auto backup.
- `days_of_week` - (Optional) Days of the week for the backups when full_backup_frequency is set to Weekly.
- `enable_encryption` - (Optional) Enable or disable encryption for backup on SQL virtual machine.
- `full_backup_frequency` - (Optional) Frequency of full backups. Possible values: 'Daily', 'Weekly'.
- `full_backup_start_time` - (Optional) Start time of a given day during which full backups can take place. 0-23 hours.
- `full_backup_window_hours` - (Optional) Duration of the time window of a given day during which full backups can take place. 1-23 hours.
- `log_backup_frequency` - (Optional) Frequency of log backups. 5-60 minutes.
- `password` - (Optional) Password for encryption on backup. This is a write-only property.
- `retention_period` - (Optional) Retention period of backup: 1-90 days.
- `storage_access_key` - (Optional) Storage account key where backup will be taken to. This is a write-only property.
- `storage_account_url` - (Optional) Storage account url where backup will be taken to.
- `storage_container_name` - (Optional) Storage container name where backup will be taken to.
DESCRIPTION
}

variable "auto_patching_settings" {
  type = object({
    enable                           = bool
    day_of_week                      = optional(string)
    maintenance_window_duration      = optional(number)
    maintenance_window_starting_hour = optional(number)
    additional_vm_patch              = optional(string)
  })
  default     = null
  description = <<DESCRIPTION
Automated patching settings for the SQL Virtual Machine.

- `enable` - (Required) Enable or disable autopatching on SQL virtual machine.
- `day_of_week` - (Optional) Day of week to apply the patch on. Possible values: 'Everyday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'.
- `maintenance_window_duration` - (Optional) Duration of patching in minutes.
- `maintenance_window_starting_hour` - (Optional) Hour of the day when patching is initiated. Local VM time. 0-23.
- `additional_vm_patch` - (Optional) Additional Patch to be enabled on the SQL Virtual Machine. Possible values: 'NotSet', 'MicrosoftUpdate'.
DESCRIPTION
}

# required AVM interfaces
# remove only if not supported by the resource
# tflint-ignore: terraform_unused_declarations
variable "customer_managed_key" {
  type = object({
    key_vault_resource_id = string
    key_name              = string
    key_version           = optional(string, null)
    user_assigned_identity = optional(object({
      resource_id = string
    }), null)
  })
  default     = null
  description = <<DESCRIPTION
A map describing customer-managed keys to associate with the resource. This includes the following properties:
- `key_vault_resource_id` - The resource ID of the Key Vault where the key is stored.
- `key_name` - The name of the key.
- `key_version` - (Optional) The version of the key. If not specified, the latest version is used.
- `user_assigned_identity` - (Optional) An object representing a user-assigned identity with the following properties:
  - `resource_id` - The resource ID of the user-assigned identity.
DESCRIPTION
}

# tflint-ignore: terraform_unused_declarations
variable "diagnostic_settings" {
  type = map(object({
    name                                     = optional(string, null)
    log_categories                           = optional(set(string), [])
    log_groups                               = optional(set(string), ["allLogs"])
    metric_categories                        = optional(set(string), ["AllMetrics"])
    log_analytics_destination_type           = optional(string, "Dedicated")
    workspace_resource_id                    = optional(string, null)
    storage_account_resource_id              = optional(string, null)
    event_hub_authorization_rule_resource_id = optional(string, null)
    event_hub_name                           = optional(string, null)
    marketplace_partner_resource_id          = optional(string, null)
  }))
  default     = {}
  description = <<DESCRIPTION
A map of diagnostic settings to create on the Key Vault. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.

- `name` - (Optional) The name of the diagnostic setting. One will be generated if not set, however this will not be unique if you want to create multiple diagnostic setting resources.
- `log_categories` - (Optional) A set of log categories to send to the log analytics workspace. Defaults to `[]`.
- `log_groups` - (Optional) A set of log groups to send to the log analytics workspace. Defaults to `["allLogs"]`.
- `metric_categories` - (Optional) A set of metric categories to send to the log analytics workspace. Defaults to `["AllMetrics"]`.
- `log_analytics_destination_type` - (Optional) The destination type for the diagnostic setting. Possible values are `Dedicated` and `AzureDiagnostics`. Defaults to `Dedicated`.
- `workspace_resource_id` - (Optional) The resource ID of the log analytics workspace to send logs and metrics to.
- `storage_account_resource_id` - (Optional) The resource ID of the storage account to send logs and metrics to.
- `event_hub_authorization_rule_resource_id` - (Optional) The resource ID of the event hub authorization rule to send logs and metrics to.
- `event_hub_name` - (Optional) The name of the event hub. If none is specified, the default event hub will be selected.
- `marketplace_partner_resource_id` - (Optional) The full ARM resource ID of the Marketplace resource to which you would like to send Diagnostic LogsLogs.
DESCRIPTION
  nullable    = false

  validation {
    condition     = alltrue([for _, v in var.diagnostic_settings : contains(["Dedicated", "AzureDiagnostics"], v.log_analytics_destination_type)])
    error_message = "Log analytics destination type must be one of: 'Dedicated', 'AzureDiagnostics'."
  }
  validation {
    condition = alltrue(
      [
        for _, v in var.diagnostic_settings :
        v.workspace_resource_id != null || v.storage_account_resource_id != null || v.event_hub_authorization_rule_resource_id != null || v.marketplace_partner_resource_id != null
      ]
    )
    error_message = "At least one of `workspace_resource_id`, `storage_account_resource_id`, `marketplace_partner_resource_id`, or `event_hub_authorization_rule_resource_id`, must be set."
  }
}

variable "enable_automatic_upgrade" {
  type        = bool
  default     = null
  description = "Enable automatic upgrade of SQL IaaS extension Agent."
}

variable "enable_telemetry" {
  type        = bool
  default     = true
  description = <<DESCRIPTION
This variable controls whether or not telemetry is enabled for the module.
For more information see <https://aka.ms/avm/telemetryinfo>.
If it is set to false, then no telemetry will be collected.
DESCRIPTION
  nullable    = false
}

variable "key_vault_credential_settings" {
  type = object({
    enable                   = bool
    azure_key_vault_url      = optional(string)
    credential_name          = optional(string)
    service_principal_name   = optional(string)
    service_principal_secret = optional(string)
  })
  default     = null
  description = <<DESCRIPTION
Azure Key Vault integration settings for the SQL Virtual Machine. This allows SQL Server to connect to Azure Key Vault.

- `enable` - (Required) Enable or disable Key Vault credential setting.
- `azure_key_vault_url` - (Optional) Azure Key Vault URL (e.g., https://myvault.vault.azure.net/).
- `credential_name` - (Optional) Credential name to store in SQL Server.
- `service_principal_name` - (Optional) Service principal name (Application/Client ID) to access Key Vault.
- `service_principal_secret` - (Optional) Service principal secret to access Key Vault. This is a write-only property.
DESCRIPTION
}

variable "least_privilege_mode" {
  type        = string
  default     = null
  description = "SQL IaaS Agent least privilege mode. Possible values are 'Enabled' and 'NotSet'."

  validation {
    condition     = var.least_privilege_mode == null || contains(["Enabled", "NotSet"], var.least_privilege_mode)
    error_message = "The least_privilege_mode must be one of: 'Enabled' or 'NotSet'."
  }
}

variable "lock" {
  type = object({
    kind = string
    name = optional(string, null)
  })
  default     = null
  description = <<DESCRIPTION
Controls the Resource Lock configuration for this resource. The following properties can be specified:

- `kind` - (Required) The type of lock. Possible values are `\"CanNotDelete\"` and `\"ReadOnly\"`.
- `name` - (Optional) The name of the lock. If not specified, a name will be generated based on the `kind` value. Changing this forces the creation of a new resource.
DESCRIPTION

  validation {
    condition     = var.lock != null ? contains(["CanNotDelete", "ReadOnly"], var.lock.kind) : true
    error_message = "The lock level must be one of: 'None', 'CanNotDelete', or 'ReadOnly'."
  }
}

# tflint-ignore: terraform_unused_declarations
variable "managed_identities" {
  type = object({
    system_assigned            = optional(bool, false)
    user_assigned_resource_ids = optional(set(string), [])
  })
  default     = {}
  description = <<DESCRIPTION
Controls the Managed Identity configuration on this resource. The following properties can be specified:

- `system_assigned` - (Optional) Specifies if the System Assigned Managed Identity should be enabled.
- `user_assigned_resource_ids` - (Optional) Specifies a list of User Assigned Managed Identity resource IDs to be assigned to this resource.
DESCRIPTION
  nullable    = false
}

variable "role_assignments" {
  type = map(object({
    role_definition_id_or_name             = string
    principal_id                           = string
    description                            = optional(string, null)
    skip_service_principal_aad_check       = optional(bool, false)
    condition                              = optional(string, null)
    condition_version                      = optional(string, null)
    delegated_managed_identity_resource_id = optional(string, null)
    principal_type                         = optional(string, null)
  }))
  default     = {}
  description = <<DESCRIPTION
A map of role assignments to create on this resource. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.

- `role_definition_id_or_name` - The ID or name of the role definition to assign to the principal.
- `principal_id` - The ID of the principal to assign the role to.
- `description` - The description of the role assignment.
- `skip_service_principal_aad_check` - If set to true, skips the Azure Active Directory check for the service principal in the tenant. Defaults to false.
- `condition` - The condition which will be used to scope the role assignment.
- `condition_version` - The version of the condition syntax. Valid values are '2.0'.
- `principal_type` - (Optional) The type of the `principal_id`. Possible values are `User`, `Group` and `ServicePrincipal`.

> Note: only set `skip_service_principal_aad_check` to true if you are assigning a role to a service principal.
DESCRIPTION
  nullable    = false
}

variable "server_configurations_management_settings" {
  type = object({
    additional_features_server_configurations = optional(object({
      is_r_services_enabled = optional(bool)
    }))
    azure_ad_authentication_settings = optional(object({
      client_id = optional(string)
    }))
    sql_connectivity_update_settings = optional(object({
      connectivity_type         = optional(string)
      port                      = optional(number)
      sql_auth_update_password  = optional(string)
      sql_auth_update_user_name = optional(string)
    }))
    sql_instance_settings = optional(object({
      collation                                = optional(string)
      is_ifi_enabled                           = optional(bool)
      is_lpim_enabled                          = optional(bool)
      is_optimize_for_ad_hoc_workloads_enabled = optional(bool)
      max_dop                                  = optional(number)
      max_server_memory_mb                     = optional(number)
      min_server_memory_mb                     = optional(number)
    }))
    sql_storage_update_settings = optional(object({
      disk_configuration_type = optional(string)
      disk_count              = optional(number)
      starting_device_id      = optional(number)
    }))
    sql_workload_type_update_settings = optional(object({
      sql_workload_type = optional(string)
    }))
  })
  default     = null
  description = <<DESCRIPTION
Server configurations management settings for the SQL Virtual Machine.

- `additional_features_server_configurations` - Additional features server configurations:
  - `is_r_services_enabled` - Enable or disable R services (SQL 2016 onwards).
- `azure_ad_authentication_settings` - Azure AD/Entra authentication settings:
  - `client_id` - The client Id of the Managed Identity to query Microsoft Graph API. Empty string for system assigned.
- `sql_connectivity_update_settings` - SQL connectivity update settings:
  - `connectivity_type` - SQL Server connectivity option. Possible values: 'LOCAL', 'PRIVATE', 'PUBLIC'.
  - `port` - SQL Server port.
  - `sql_auth_update_password` - SQL Server sysadmin login password. Write-only.
  - `sql_auth_update_user_name` - SQL Server sysadmin login to create. Write-only.
- `sql_instance_settings` - SQL instance settings:
  - `collation` - SQL Server Collation.
  - `is_ifi_enabled` - SQL Server IFI (Instant File Initialization).
  - `is_lpim_enabled` - SQL Server LPIM (Lock Pages in Memory).
  - `is_optimize_for_ad_hoc_workloads_enabled` - SQL Server Optimize for Adhoc workloads.
  - `max_dop` - SQL Server MAXDOP.
  - `max_server_memory_mb` - SQL Server maximum memory.
  - `min_server_memory_mb` - SQL Server minimum memory.
- `sql_storage_update_settings` - SQL storage update settings:
  - `disk_configuration_type` - Disk configuration to apply. Possible values: 'NEW', 'EXTEND', 'ADD'.
  - `disk_count` - Virtual machine disk count.
  - `starting_device_id` - Device id of the first disk to be updated.
- `sql_workload_type_update_settings` - SQL workload type update settings:
  - `sql_workload_type` - SQL Server workload type. Possible values: 'GENERAL', 'OLTP', 'DW'.
DESCRIPTION
}

variable "sql_image_offer" {
  type        = string
  default     = null
  description = "The SQL Server image offer. Possible values include 'SQL2019-WS2019', 'SQL2017-WS2019', 'SQL2016SP2-WS2019', etc."
}

variable "sql_image_sku" {
  type        = string
  default     = null
  description = "The SQL Server image SKU. Possible values include 'Developer', 'Express', 'Standard', 'Enterprise', 'Web'."

  validation {
    condition     = var.sql_image_sku == null || contains(["Developer", "Express", "Standard", "Enterprise", "Web"], var.sql_image_sku)
    error_message = "The sql_image_sku must be one of: 'Developer', 'Express', 'Standard', 'Enterprise', or 'Web'."
  }
}

variable "sql_management" {
  type        = string
  default     = "Full"
  description = "The SQL Server management mode. Possible values are 'Full', 'LightWeight', and 'NoAgent'."

  validation {
    condition     = contains(["Full", "LightWeight", "NoAgent"], var.sql_management)
    error_message = "The sql_management must be one of: 'Full', 'LightWeight', or 'NoAgent'."
  }
}

variable "sql_server_license_type" {
  type        = string
  default     = "PAYG"
  description = "The SQL Server license type. Possible values are 'AHUB' (Azure Hybrid Benefit), 'PAYG' (Pay-As-You-Go), and 'DR' (Disaster Recovery)."

  validation {
    condition     = contains(["AHUB", "PAYG", "DR"], var.sql_server_license_type)
    error_message = "The sql_server_license_type must be one of: 'AHUB', 'PAYG', or 'DR'."
  }
}

variable "sql_virtual_machine_group_resource_id" {
  type        = string
  default     = null
  description = "ARM resource id of the SQL virtual machine group this SQL virtual machine is or will be part of. Used for Always On Availability Groups."
}

variable "storage_configuration_settings" {
  type = object({
    disk_configuration_type     = optional(string)
    storage_workload_type       = optional(string)
    sql_system_db_on_data_disk  = optional(bool)
    enable_storage_config_blade = optional(bool)
    sql_data_settings = optional(object({
      default_file_path = optional(string)
      luns              = optional(list(number))
      use_storage_pool  = optional(bool)
    }))
    sql_log_settings = optional(object({
      default_file_path = optional(string)
      luns              = optional(list(number))
      use_storage_pool  = optional(bool)
    }))
    sql_temp_db_settings = optional(object({
      data_file_count     = optional(number)
      data_file_size      = optional(number)
      data_growth         = optional(number)
      default_file_path   = optional(string)
      log_file_size       = optional(number)
      log_growth          = optional(number)
      luns                = optional(list(number))
      persist_folder      = optional(bool)
      persist_folder_path = optional(string)
      use_storage_pool    = optional(bool)
    }))
  })
  default     = null
  description = <<DESCRIPTION
Storage configuration settings for the SQL Virtual Machine.

- `disk_configuration_type` - (Optional) Disk configuration type. Possible values: 'NEW', 'EXTEND', 'ADD'.
- `storage_workload_type` - (Optional) Storage workload type. Possible values: 'GENERAL', 'OLTP', 'DW'.
- `sql_system_db_on_data_disk` - (Optional) SQL Server SystemDb Storage on DataPool if true.
- `enable_storage_config_blade` - (Optional) Enable SQL IaaS Agent storage configuration blade in Azure Portal. Write-only.
- `sql_data_settings` - (Optional) SQL Server data settings:
  - `default_file_path` - SQL Server default data file path.
  - `luns` - Logical Unit Numbers for the disks.
  - `use_storage_pool` - Use storage pool to build a drive if true.
- `sql_log_settings` - (Optional) SQL Server log settings:
  - `default_file_path` - SQL Server default log file path.
  - `luns` - Logical Unit Numbers for the disks.
  - `use_storage_pool` - Use storage pool to build a drive if true.
- `sql_temp_db_settings` - (Optional) SQL Server TempDB settings:
  - `data_file_count` - SQL Server tempdb data file count.
  - `data_file_size` - SQL Server tempdb data file size in MB.
  - `data_growth` - SQL Server tempdb data file autoGrowth size in MB.
  - `default_file_path` - SQL Server default tempdb file path.
  - `log_file_size` - SQL Server tempdb log file size in MB.
  - `log_growth` - SQL Server tempdb log file autoGrowth size in MB.
  - `luns` - Logical Unit Numbers for the disks.
  - `persist_folder` - SQL Server tempdb persist folder choice.
  - `persist_folder_path` - SQL Server tempdb persist folder location.
  - `use_storage_pool` - Use storage pool to build a drive if true.
DESCRIPTION
}

# tflint-ignore: terraform_unused_declarations
variable "tags" {
  type        = map(string)
  default     = null
  description = "(Optional) Tags of the resource."
}

variable "virtual_machine_identity_settings" {
  type = object({
    type        = optional(string)
    resource_id = optional(string)
  })
  default     = null
  description = <<DESCRIPTION
Identity settings for the virtual machine. Used to configure managed identity for SQL VM.

- `type` - (Optional) Identity type of the virtual machine. Possible values: 'None', 'SystemAssigned', 'UserAssigned'.
- `resource_id` - (Optional) ARM Resource Id of the identity. Only required when UserAssigned identity is selected.
DESCRIPTION
}

variable "wsfc_domain_credentials" {
  type = object({
    cluster_bootstrap_account_password = optional(string)
    cluster_operator_account_password  = optional(string)
    sql_service_account_password       = optional(string)
  })
  default     = null
  description = <<DESCRIPTION
Windows Server Failover Cluster domain credentials. Used for Always On Availability Groups.

- `cluster_bootstrap_account_password` - (Optional) Cluster bootstrap account password.
- `cluster_operator_account_password` - (Optional) Cluster operator account password.
- `sql_service_account_password` - (Optional) SQL service account password.
DESCRIPTION
  sensitive   = true
}

variable "wsfc_static_ip" {
  type        = string
  default     = null
  description = "Domain credentials for setting up Windows Server Failover Cluster for SQL availability group."
}
