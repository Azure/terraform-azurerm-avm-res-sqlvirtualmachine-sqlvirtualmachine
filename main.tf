# Main SQL Virtual Machine resource
resource "azapi_resource" "this" {
  location  = var.location
  name      = var.name
  parent_id = "/subscriptions/${data.azapi_client_config.current.subscription_id}/resourceGroups/${var.resource_group_name}"
  type      = "Microsoft.SqlVirtualMachine/sqlVirtualMachines@2023-10-01"
  body = {
    properties = {
      virtualMachineResourceId = var.virtual_machine_resource_id
      sqlServerLicenseType     = var.sql_server_license_type
      sqlManagement            = var.sql_management
      sqlImageSku              = var.sql_image_sku
      sqlImageOffer            = var.sql_image_offer
      keyVaultCredentialSettings = var.key_vault_credential_settings != null ? {
        enable                 = var.key_vault_credential_settings.enable
        azureKeyVaultUrl       = var.key_vault_credential_settings.azure_key_vault_url
        credentialName         = var.key_vault_credential_settings.credential_name
        servicePrincipalName   = var.key_vault_credential_settings.service_principal_name
        servicePrincipalSecret = var.key_vault_credential_settings.service_principal_secret
      } : null
      autoBackupSettings = var.auto_backup_settings != null ? {
        enable                = var.auto_backup_settings.enable
        backupScheduleType    = var.auto_backup_settings.backup_schedule_type
        backupSystemDbs       = var.auto_backup_settings.backup_system_dbs
        daysOfWeek            = var.auto_backup_settings.days_of_week
        enableEncryption      = var.auto_backup_settings.enable_encryption
        fullBackupFrequency   = var.auto_backup_settings.full_backup_frequency
        fullBackupStartTime   = var.auto_backup_settings.full_backup_start_time
        fullBackupWindowHours = var.auto_backup_settings.full_backup_window_hours
        logBackupFrequency    = var.auto_backup_settings.log_backup_frequency
        password              = var.auto_backup_settings.password
        retentionPeriod       = var.auto_backup_settings.retention_period
        storageAccessKey      = var.auto_backup_settings.storage_access_key
        storageAccountUrl     = var.auto_backup_settings.storage_account_url
        storageContainerName  = var.auto_backup_settings.storage_container_name
      } : null
      autoPatchingSettings = var.auto_patching_settings != null ? {
        enable                        = var.auto_patching_settings.enable
        dayOfWeek                     = var.auto_patching_settings.day_of_week
        maintenanceWindowDuration     = var.auto_patching_settings.maintenance_window_duration
        maintenanceWindowStartingHour = var.auto_patching_settings.maintenance_window_starting_hour
        additionalVmPatch             = var.auto_patching_settings.additional_vm_patch
      } : null
      storageConfigurationSettings = var.storage_configuration_settings != null ? {
        diskConfigurationType    = var.storage_configuration_settings.disk_configuration_type
        storageWorkloadType      = var.storage_configuration_settings.storage_workload_type
        sqlSystemDbOnDataDisk    = var.storage_configuration_settings.sql_system_db_on_data_disk
        enableStorageConfigBlade = var.storage_configuration_settings.enable_storage_config_blade
        sqlDataSettings = var.storage_configuration_settings.sql_data_settings != null ? {
          defaultFilePath = var.storage_configuration_settings.sql_data_settings.default_file_path
          luns            = var.storage_configuration_settings.sql_data_settings.luns
          useStoragePool  = var.storage_configuration_settings.sql_data_settings.use_storage_pool
        } : null
        sqlLogSettings = var.storage_configuration_settings.sql_log_settings != null ? {
          defaultFilePath = var.storage_configuration_settings.sql_log_settings.default_file_path
          luns            = var.storage_configuration_settings.sql_log_settings.luns
          useStoragePool  = var.storage_configuration_settings.sql_log_settings.use_storage_pool
        } : null
        sqlTempDbSettings = var.storage_configuration_settings.sql_temp_db_settings != null ? {
          dataFileCount     = var.storage_configuration_settings.sql_temp_db_settings.data_file_count
          dataFileSize      = var.storage_configuration_settings.sql_temp_db_settings.data_file_size
          dataGrowth        = var.storage_configuration_settings.sql_temp_db_settings.data_growth
          defaultFilePath   = var.storage_configuration_settings.sql_temp_db_settings.default_file_path
          logFileSize       = var.storage_configuration_settings.sql_temp_db_settings.log_file_size
          logGrowth         = var.storage_configuration_settings.sql_temp_db_settings.log_growth
          luns              = var.storage_configuration_settings.sql_temp_db_settings.luns
          persistFolder     = var.storage_configuration_settings.sql_temp_db_settings.persist_folder
          persistFolderPath = var.storage_configuration_settings.sql_temp_db_settings.persist_folder_path
          useStoragePool    = var.storage_configuration_settings.sql_temp_db_settings.use_storage_pool
        } : null
      } : null
      serverConfigurationsManagementSettings = var.server_configurations_management_settings != null ? {
        additionalFeaturesServerConfigurations = var.server_configurations_management_settings.additional_features_server_configurations != null ? {
          isRServicesEnabled = var.server_configurations_management_settings.additional_features_server_configurations.is_r_services_enabled
        } : null
        azureAdAuthenticationSettings = var.server_configurations_management_settings.azure_ad_authentication_settings != null ? {
          clientId = var.server_configurations_management_settings.azure_ad_authentication_settings.client_id
        } : null
        sqlConnectivityUpdateSettings = var.server_configurations_management_settings.sql_connectivity_update_settings != null ? {
          connectivityType      = var.server_configurations_management_settings.sql_connectivity_update_settings.connectivity_type
          port                  = var.server_configurations_management_settings.sql_connectivity_update_settings.port
          sqlAuthUpdatePassword = var.server_configurations_management_settings.sql_connectivity_update_settings.sql_auth_update_password
          sqlAuthUpdateUserName = var.server_configurations_management_settings.sql_connectivity_update_settings.sql_auth_update_user_name
        } : null
        sqlInstanceSettings = var.server_configurations_management_settings.sql_instance_settings != null ? {
          collation                          = var.server_configurations_management_settings.sql_instance_settings.collation
          isIfiEnabled                       = var.server_configurations_management_settings.sql_instance_settings.is_ifi_enabled
          isLpimEnabled                      = var.server_configurations_management_settings.sql_instance_settings.is_lpim_enabled
          isOptimizeForAdHocWorkloadsEnabled = var.server_configurations_management_settings.sql_instance_settings.is_optimize_for_ad_hoc_workloads_enabled
          maxDop                             = var.server_configurations_management_settings.sql_instance_settings.max_dop
          maxServerMemoryMB                  = var.server_configurations_management_settings.sql_instance_settings.max_server_memory_mb
          minServerMemoryMB                  = var.server_configurations_management_settings.sql_instance_settings.min_server_memory_mb
        } : null
        sqlStorageUpdateSettings = var.server_configurations_management_settings.sql_storage_update_settings != null ? {
          diskConfigurationType = var.server_configurations_management_settings.sql_storage_update_settings.disk_configuration_type
          diskCount             = var.server_configurations_management_settings.sql_storage_update_settings.disk_count
          startingDeviceId      = var.server_configurations_management_settings.sql_storage_update_settings.starting_device_id
        } : null
        sqlWorkloadTypeUpdateSettings = var.server_configurations_management_settings.sql_workload_type_update_settings != null ? {
          sqlWorkloadType = var.server_configurations_management_settings.sql_workload_type_update_settings.sql_workload_type
        } : null
      } : null
      assessmentSettings = var.assessment_settings != null ? {
        enable         = var.assessment_settings.enable
        runImmediately = var.assessment_settings.run_immediately
        schedule = var.assessment_settings.schedule != null ? {
          dayOfWeek         = var.assessment_settings.schedule.day_of_week
          enable            = var.assessment_settings.schedule.enable
          monthlyOccurrence = var.assessment_settings.schedule.monthly_occurrence
          startTime         = var.assessment_settings.schedule.start_time
          weeklyInterval    = var.assessment_settings.schedule.weekly_interval
        } : null
      } : null
      enableAutomaticUpgrade = var.enable_automatic_upgrade
      leastPrivilegeMode     = var.least_privilege_mode
    }
  }
  create_headers         = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  delete_headers         = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  read_headers           = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  response_export_values = ["*"]
  tags                   = var.tags
  update_headers         = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null

  dynamic "identity" {
    for_each = local.managed_identities.system_assigned_user_assigned

    content {
      type         = identity.value.type
      identity_ids = identity.value.user_assigned_resource_ids
    }
  }
}

data "azapi_client_config" "current" {}

resource "azapi_resource" "management_lock" {
  count = var.lock != null ? 1 : 0

  name      = coalesce(var.lock.name, "lock-${var.lock.kind}")
  parent_id = azapi_resource.this.id
  type      = "Microsoft.Authorization/locks@2020-05-01"
  body = {
    properties = {
      level = var.lock.kind
      notes = var.lock.kind == "CanNotDelete" ? "Cannot delete the resource or its child resources." : "Cannot delete or modify the resource or its child resources."
    }
  }
  create_headers = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  delete_headers = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  read_headers   = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  update_headers = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
}

resource "azapi_resource" "role_assignment" {
  for_each = var.role_assignments

  name      = uuid()
  parent_id = azapi_resource.this.id
  type      = "Microsoft.Authorization/roleAssignments@2022-04-01"
  body = {
    properties = {
      principalId                        = each.value.principal_id
      roleDefinitionId                   = strcontains(lower(each.value.role_definition_id_or_name), lower(local.role_definition_resource_substring)) ? each.value.role_definition_id_or_name : "${azapi_resource.this.id}${local.role_definition_resource_substring}/${each.value.role_definition_id_or_name}"
      condition                          = each.value.condition
      conditionVersion                   = each.value.condition_version
      delegatedManagedIdentityResourceId = each.value.delegated_managed_identity_resource_id
      principalType                      = each.value.principal_type
      description                        = "Role assignment managed by AVM module"
    }
  }
  create_headers          = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  delete_headers          = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  ignore_missing_property = true
  read_headers            = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  update_headers          = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null

  lifecycle {
    ignore_changes = [name]
  }
}
