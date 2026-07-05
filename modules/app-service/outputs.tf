output "id" {

  description = "Linux Web App ID."

  value = azurerm_linux_web_app.this.id

}

output "name" {

  description = "Linux Web App name."

  value = azurerm_linux_web_app.this.name

}

output "default_hostname" {

  description = "Default hostname."

  value = azurerm_linux_web_app.this.default_hostname

}
