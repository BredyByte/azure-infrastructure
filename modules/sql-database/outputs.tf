output "id" {
  description = "SQL Database ID."
  value       = azurerm_mssql_database.this.id
}

output "name" {
  description = "SQL Database name."
  value       = azurerm_mssql_database.this.name
}
