output "resource_group_name" {

  value = module.resource_group.name

}

output "app_service_plan_name" {

  value = module.app_service_plan.name

}

output "web_app_name" {

  value = azurerm_linux_web_app.this.name

}

output "web_app_url" {

  value = "https://${azurerm_linux_web_app.this.default_hostname}"

}
