# SQL Virtual Machine Group resource
resource "azapi_resource" "this" {
  type      = "Microsoft.SqlVirtualMachine/sqlVirtualMachineGroups@2023-10-01"
  name      = var.name
  location  = var.location
  parent_id = "/subscriptions/${var.subscription_id}/resourceGroups/${var.resource_group_name}"
  tags      = var.tags

  body = {
    properties = {
      sqlImageOffer     = var.sql_image_offer
      sqlImageSku       = var.sql_image_sku
      wsfcDomainProfile = var.wsfc_domain_profile
    }
  }
}
