############################################################
# Azure Monitor Action Group
############################################################

resource "azurerm_monitor_action_group" "web_app_alerts" {
  name                = var.action_group_name
  resource_group_name = var.resource_group_name
  short_name          = "DevAlerts"

  email_receiver {
    name                    = "Email-IT"
    email_address           = var.action_group_email_address
    use_common_alert_schema = true
  }

  tags = var.tags
}

############################################################
# Web App HTTP 4xx Metric Alert
############################################################

resource "azurerm_monitor_metric_alert" "web_app_http4xx" {
  name                = var.metric_alert_name
  resource_group_name = var.resource_group_name
  scopes              = [var.web_app_id]

  description   = "Alert when the Web App generates more than 5 HTTP 4xx responses in 5 minutes."
  severity      = 2
  enabled       = true
  auto_mitigate = true

  # Evaluate the alert every minute.
  frequency = "PT1M"

  # Analyze metrics generated during the last five minutes.
  window_size = "PT5M"

  criteria {
    metric_namespace = "Microsoft.Web/sites"
    metric_name      = "Http4xx"
    aggregation      = "Total"
    operator         = "GreaterThan"
    threshold        = 5
  }

  action {
    action_group_id = azurerm_monitor_action_group.web_app_alerts.id
  }

  tags = var.tags
}
