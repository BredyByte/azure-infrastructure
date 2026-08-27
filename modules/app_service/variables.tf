############################################################
# Shared configuration
############################################################

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "tags" {
  type = map(string)
}

############################################################
# App Service Plan
############################################################

variable "app_service_plan_name" {
  type = string
}

variable "app_service_plan_sku_name" {
  type = string
}

############################################################
# Linux Web App
############################################################

variable "web_app_name" {
  type = string
}

variable "app_service_python_version" {
  type = string
}

variable "app_service_integration_subnet_id" {
  description = "Delegated subnet used for App Service VNet Integration."
  type        = string
}

############################################################
# Application settings
############################################################

variable "key_vault_uri" {
  type = string
}

variable "storage_account_name" {
  type = string
}

variable "sql_server_fqdn" {
  type = string
}

variable "sql_database_name" {
  type = string
}

variable "application_insights_connection_string" {
  description = "Connection string used by the Web App to send telemetry to Application Insights."
  type        = string
  sensitive   = true
}
