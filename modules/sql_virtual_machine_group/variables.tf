variable "location" {
  type        = string
  description = "Azure region where the resource should be deployed."
  nullable    = false
}

variable "name" {
  type        = string
  description = "The name of the SQL Virtual Machine Group."

  validation {
    condition     = can(regex("^[a-zA-Z0-9-]{1,128}$", var.name))
    error_message = "The name must be between 1 and 128 characters long and can only contain letters, numbers, and hyphens."
  }
}

variable "resource_group_name" {
  type        = string
  description = "The resource group where the resources will be deployed."
  nullable    = false
}

variable "sql_image_offer" {
  type        = string
  description = "The SQL Server image offer. Example: 'SQL2019-WS2019'."
  nullable    = false
}

variable "sql_image_sku" {
  type        = string
  description = "The SQL Server image SKU. Possible values include 'Developer', 'Enterprise'."
  nullable    = false

  validation {
    condition     = contains(["Developer", "Enterprise"], var.sql_image_sku)
    error_message = "The sql_image_sku must be one of: 'Developer' or 'Enterprise' for Always On availability groups."
  }
}

variable "subscription_id" {
  type        = string
  description = "The subscription ID where the resource will be deployed."
  nullable    = false
}

variable "tags" {
  type        = map(string)
  default     = null
  description = "(Optional) Tags of the resource."
}

variable "wsfc_domain_profile" {
  type = object({
    domain_fqdn                 = string
    cluster_bootstrap_account   = optional(string)
    cluster_operator_account    = optional(string)
    sql_service_account         = optional(string)
    storage_account_url         = optional(string)
    storage_account_primary_key = optional(string)
    organizational_unit_path    = optional(string)
    file_share_witness_path     = optional(string)
    cluster_subnet_type         = optional(string)
  })
  default     = null
  description = "Windows Server Failover Cluster domain profile configuration."
}
