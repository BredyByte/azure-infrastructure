resource "azurerm_mssql_database" "this" {

  name      = var.name
  server_id = var.server_id

  sku_name = var.sku_name

  zone_redundant = var.zone_redundant

  storage_account_type = var.storage_account_type

  collation = "SQL_Latin1_General_CP1_CI_AS"

  tags = var.tags
}
