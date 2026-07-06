resource "azurerm_storage_account" "this" {

  name                     = var.name

  resource_group_name      = var.resource_group_name

  location                 = var.location

  account_tier             = var.account_tier

  account_replication_type = var.account_replication_type

  tags = var.tags

}

resource "azurerm_storage_container" "this" {

  for_each = toset(var.containers)

  name = each.value

  storage_account_id = azurerm_storage_account.this.id

  container_access_type = "private"

}
