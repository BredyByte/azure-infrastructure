output "id" {
  description = "SQL Server ID."
  value       = azurerm_mssql_server.this.id
}

output "name" {
  description = "SQL Server name."
  value       = azurerm_mssql_server.this.name
}

output "fully_qualified_domain_name" {
  description = "SQL Server FQDN."
  value       = azurerm_mssql_server.this.fully_qualified_domain_name
}
