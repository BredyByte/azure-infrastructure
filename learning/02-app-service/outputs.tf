output "web_app_name" {
  value = azurerm_linux_web_app.this.name
}

output "web_app_url" {
  value = "https://${azurerm_linux_web_app.this.default_hostname}"
}
