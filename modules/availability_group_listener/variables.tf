variable "availability_group_name" {
  type        = string
  description = "The name of the availability group."
  nullable    = false
}

variable "name" {
  type        = string
  description = "The name of the Availability Group Listener."

  validation {
    condition     = can(regex("^[a-zA-Z0-9-]{1,128}$", var.name))
    error_message = "The name must be between 1 and 128 characters long and can only contain letters, numbers, and hyphens."
  }
}

variable "sql_virtual_machine_group_id" {
  type        = string
  description = "The resource ID of the SQL Virtual Machine Group."
  nullable    = false
}

variable "availability_group_configuration" {
  type = object({
    replicas = optional(list(object({
      sql_virtual_machine_instance_id = string
      role                            = string
      commit                          = optional(string)
      failover                        = optional(string)
      readable_secondary              = optional(string)
    })))
  })
  default     = null
  description = "Availability group configuration for replicas."
}

variable "create_default_availability_group_if_not_exist" {
  type        = bool
  default     = false
  description = "Whether to create the default availability group if it does not exist."
}

variable "load_balancer_configurations" {
  type = list(object({
    private_ip_address = object({
      ip_address         = string
      subnet_resource_id = string
    })
    load_balancer_resource_id     = optional(string)
    probe_port                    = optional(number)
    public_ip_address_resource_id = optional(string)
    sql_virtual_machine_instances = list(string)
  }))
  default     = []
  description = "Load balancer configurations for the availability group listener."
}

variable "port" {
  type        = number
  default     = 1433
  description = "The port on which the availability group listener will listen."

  validation {
    condition     = var.port > 0 && var.port <= 65535
    error_message = "The port must be between 1 and 65535."
  }
}
