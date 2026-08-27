############################################################
# Linux App Service Plan
############################################################

resource "azurerm_service_plan" "this" {
  name                = var.app_service_plan_name
  location            = var.location
  resource_group_name = var.resource_group_name

  os_type  = "Linux"
  sku_name = var.app_service_plan_sku_name

  tags = var.tags
}

############################################################
# Linux Web App
############################################################

resource "azurerm_linux_web_app" "this" {
  name                = var.web_app_name
  location            = var.location
  resource_group_name = var.resource_group_name
  service_plan_id     = azurerm_service_plan.this.id

  https_only = true

  # The application will be reachable only through its future private endpoint
  # and Application Gateway.
  public_network_access_enabled = false

  # Sends outbound application traffic through the delegated VNet subnet.
  virtual_network_subnet_id = var.app_service_integration_subnet_id

  # Creates a Microsoft Entra managed identity for this Web App.
  identity {
    type = "SystemAssigned"
  }

  app_settings = {
    KEY_VAULT_URL              = var.key_vault_uri
    AZURE_STORAGE_ACCOUNT_NAME = var.storage_account_name
    SQL_SERVER                 = var.sql_server_fqdn
    SQL_DATABASE               = var.sql_database_name

    APPLICATIONINSIGHTS_CONNECTION_STRING = var.application_insights_connection_string


    # Kudu installs requirements.txt during ZIP deployment.
    SCM_DO_BUILD_DURING_DEPLOYMENT = "true"
  }

  site_config {
    always_on = true

    # Routes all outbound application traffic through VNet Integration.
    vnet_route_all_enabled = true

    application_stack {
      python_version = var.app_service_python_version
    }
  }

  tags = var.tags
}
