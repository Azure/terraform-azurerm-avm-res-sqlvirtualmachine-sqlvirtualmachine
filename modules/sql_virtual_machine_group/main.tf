terraform {
  required_version = "~> 1.5"

  required_providers {
    azapi = {
      source  = "Azure/azapi"
      version = "~> 2.4"
    }
  }
}

# SQL Virtual Machine Group resource
resource "azapi_resource" "this" {
  type      = "Microsoft.SqlVirtualMachine/sqlVirtualMachineGroups@2023-10-01"
  name      = var.name
  location  = var.location
  parent_id = "/subscriptions/${var.subscription_id}/resourceGroups/${var.resource_group_name}"

  body = {
    properties = {
      sqlImageOffer              = var.sql_image_offer
      sqlImageSku                = var.sql_image_sku
      wsfcDomainProfile          = var.wsfc_domain_profile
      clusterManagerType         = var.cluster_manager_type
      clusterSubnetType          = var.cluster_subnet_type
    }
  }

  tags = var.tags
}
