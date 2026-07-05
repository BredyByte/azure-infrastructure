module "resource_group" {

  source = "../../modules/resource-group"

  name     = local.names.resource_group
  location = var.location
  tags     = var.tags

}


resource "azurerm_service_plan" "this" {

  name = local.names.app_service_plan

  location = module.resource_group.location

  resource_group_name = module.resource_group.name

  os_type = "Linux"

  sku_name = var.app_service_plan_sku

  tags = var.tags

}


resource "azurerm_linux_web_app" "this" {

  name = local.names.app_service

  location = module.resource_group.location

  resource_group_name = module.resource_group.name

  service_plan_id = azurerm_service_plan.this.id

  site_config {

    application_stack {

      python_version = var.python_version

    }

  }

  https_only = true

  tags = var.tags

}
