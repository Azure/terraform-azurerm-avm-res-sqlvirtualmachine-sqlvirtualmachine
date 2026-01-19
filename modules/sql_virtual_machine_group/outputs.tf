output "resource" {
  description = "The full output for the SQL Virtual Machine Group resource."
  value       = azapi_resource.this
}

output "resource_id" {
  description = "The resource ID of the SQL Virtual Machine Group."
  value       = azapi_resource.this.id
}

output "name" {
  description = "The name of the SQL Virtual Machine Group."
  value       = azapi_resource.this.name
}
