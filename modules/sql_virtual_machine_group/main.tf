# SQL Virtual Machine Group resource
resource "azapi_resource" "this" {
  location  = var.location
  name      = var.name
  parent_id = "/subscriptions/${var.subscription_id}/resourceGroups/${var.resource_group_name}"
  type      = "Microsoft.SqlVirtualMachine/sqlVirtualMachineGroups@2023-10-01"
  body = {
    properties = {
      sqlImageOffer     = var.sql_image_offer
      sqlImageSku       = var.sql_image_sku
      wsfcDomainProfile = var.wsfc_domain_profile
    }
  }
  tags = var.tags
}
