output "resource" {
  description = "The full output for the Availability Group Listener resource."
  value       = azapi_resource.this
}

output "resource_id" {
  description = "The resource ID of the Availability Group Listener."
  value       = azapi_resource.this.id
}

output "name" {
  description = "The name of the Availability Group Listener."
  value       = azapi_resource.this.name
}
