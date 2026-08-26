############################################################
# Action Group output
############################################################

output "action_group_id" {
  description = "Resource ID of the Azure Monitor Action Group."
  value       = azurerm_monitor_action_group.web_app_alerts.id
}

############################################################
# Metric Alert output
############################################################

output "web_app_http4xx_alert_id" {
  description = "Resource ID of the Web App HTTP 4xx metric alert."
  value       = azurerm_monitor_metric_alert.web_app_http4xx.id
}
