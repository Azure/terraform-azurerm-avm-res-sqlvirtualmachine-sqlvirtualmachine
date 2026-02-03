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

# required AVM resources interfaces (scoped to the created SQL Virtual Machine)
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
