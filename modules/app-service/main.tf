resource "azurerm_linux_web_app" "this" {

  name                = var.name

  location            = var.location

  resource_group_name = var.resource_group_name

  service_plan_id     = var.service_plan_id

  https_only = true

  site_config {

    application_stack {

      python_version = var.python_version

    }

  }

  tags = var.tags

}
