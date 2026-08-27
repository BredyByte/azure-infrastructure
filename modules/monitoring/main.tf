############################################################
# Monitoring names
############################################################

locals {
  log_analytics_workspace_name        = "law-${var.name_prefix}"
  application_insights_name           = "app-${var.name_prefix}"
  application_gateway_diagnostic_name = "diag-app-gateway"
}

############################################################
# Log Analytics Workspace
############################################################

resource "azurerm_log_analytics_workspace" "this" {
  name                = local.log_analytics_workspace_name
  location            = var.location
  resource_group_name = var.resource_group_name

  sku               = "PerGB2018"
  retention_in_days = var.log_analytics_retention_in_days

  tags = var.tags
}

############################################################
# Application Gateway diagnostic settings
############################################################

resource "azurerm_monitor_diagnostic_setting" "application_gateway" {
  name               = local.application_gateway_diagnostic_name
  target_resource_id = var.application_gateway_id

  log_analytics_workspace_id = (
    azurerm_log_analytics_workspace.this.id
  )

  # Stores logs in the dedicated AGWAccessLogs
  # and AGWFirewallLogs tables.
  log_analytics_destination_type = "Dedicated"

  ##########################################################
  # Application Gateway access logs
  ##########################################################

  enabled_log {
    category = "ApplicationGatewayAccessLog"
  }

  ##########################################################
  # Web Application Firewall logs
  ##########################################################

  enabled_log {
    category = "ApplicationGatewayFirewallLog"
  }
}

############################################################
# Application Insights
############################################################

resource "azurerm_application_insights" "this" {
  name                = local.application_insights_name
  location            = var.location
  resource_group_name = var.resource_group_name
  workspace_id        = azurerm_log_analytics_workspace.this.id
  application_type    = "web"

  tags = var.tags
}
