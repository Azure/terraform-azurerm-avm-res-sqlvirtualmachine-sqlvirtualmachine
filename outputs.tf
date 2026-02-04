output "name" {
  description = "The name of the SQL Virtual Machine."
  value       = azapi_resource.this.name
}

output "resource_id" {
  description = "The resource ID of the SQL Virtual Machine."
  value       = azapi_resource.this.id
}
