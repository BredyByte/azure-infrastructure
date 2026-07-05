resource "azurerm_resource_group" "rg" {

  name = local.names.resource_group

  location = var.location

  tags = var.tags

}
