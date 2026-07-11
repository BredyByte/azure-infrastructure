terraform {
  required_version = ">= 1.5"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.80"
    }
  }
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

############################################################
# Current Azure Account
############################################################

data "azurerm_client_config" "current" {}

############################################################
# Configuration
############################################################

locals {
  location            = "France Central"
  resource_group_name = "rg-dev-helloworld"

  app_service_plan = "asp-dev-helloworld"
  web_app          = "app-dev-helloworld"

  storage_account = "stdevhelloworld"

  sql_server_location = "France Central"
  sql_server          = "sql-dev-helloworld"
  sql_database        = "sqldb-dev-helloworld"
  sql_admin_login    = "sqladmin"
  sql_admin_password = "wtFbyJMcDdgY3PbaI7fq"

  key_vault = "kv-dev-helloworld"
  current_user_object_id = data.azurerm_client_config.current.object_id

  secrets = {
    sql-admin-login    = local.sql_admin_login
    sql-admin-password = local.sql_admin_password

    welcome-message = "Welcome David from Azure Key Vault!"
    environment = "Development"
    project = "Hello World"
  }

  tags = {
    Environment = "Development"
    Project     = "Hello World"
    Owner       = "Davyd Bredykhin"
    ManagedBy   = "Terraform"
  }
}

############################################################
# Resource Group
############################################################

resource "azurerm_resource_group" "rg" {
  name     = local.resource_group_name
  location = local.location

  tags = local.tags
}

############################################################
# App Service Plan
############################################################

resource "azurerm_service_plan" "plan" {
  name                = local.app_service_plan
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name


  os_type  = "Linux"
  sku_name = "B1"

  # Production
  # app_service_plan_sku   = "P1v3"
  # worker_count           = 3
  # zone_balancing_enabled = true

  tags = local.tags
}

############################################################
# Linux Web App
############################################################

resource "azurerm_linux_web_app" "app" {
  name                = local.web_app
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  service_plan_id     = azurerm_service_plan.plan.id

  https_only = true

  site_config {
    always_on = true

    application_stack {
      python_version = "3.12"
    }
  }

  tags = local.tags
}

############################################################
# Storage Account
############################################################

resource "azurerm_storage_account" "storage" {
  name                = local.storage_account
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = local.tags
}

############################################################
# SQL Server
############################################################

resource "azurerm_mssql_server" "sql" {
  name                = local.sql_server
  resource_group_name = azurerm_resource_group.rg.name
  location            = local.sql_server_location

  version = "12.0"

  administrator_login          = local.sql_admin_login
  administrator_login_password = local.sql_admin_password

  minimum_tls_version           = "1.2"
  public_network_access_enabled = true

  tags = local.tags
}

############################################################
# SQL Database
############################################################

resource "azurerm_mssql_database" "database" {
  name      = local.sql_database
  server_id = azurerm_mssql_server.sql.id

  sku_name = "Basic"

  zone_redundant = false

  storage_account_type = "Local"

  tags = local.tags
}

############################################################
# Key Vault
############################################################

resource "azurerm_key_vault" "kv" {
  name                = local.key_vault
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  tenant_id = data.azurerm_client_config.current.tenant_id
  sku_name  = "standard"

  soft_delete_retention_days = 7
  purge_protection_enabled   = false

  rbac_authorization_enabled = true

  tags = local.tags
}

############################################################
# Key Vault RBAC
############################################################

resource "azurerm_role_assignment" "current_user_kv_admin" {

  scope = azurerm_key_vault.kv.id

  role_definition_name = "Key Vault Administrator"

  principal_id = local.current_user_object_id
}

############################################################
# Key Vault Secrets
############################################################

resource "azurerm_key_vault_secret" "this" {

  depends_on = [
    azurerm_role_assignment.current_user_kv_admin
  ]

  for_each = local.secrets

  name  = each.key
  value = each.value

  key_vault_id = azurerm_key_vault.kv.id
}

############################################################
# Outputs
############################################################

output "resource_group" {
  value = azurerm_resource_group.rg.name
}

output "app_service_plan" {
  value = azurerm_service_plan.plan.name
}

output "web_app" {
  value = azurerm_linux_web_app.app.name
}

output "storage_account" {
  value = azurerm_storage_account.storage.name
}

output "web_app_url" {
  value = "https://${azurerm_linux_web_app.app.default_hostname}"
}

output "sql_server" {
  value = azurerm_mssql_server.sql.name
}

output "sql_database" {
  value = azurerm_mssql_database.database.name
}

output "key_vault_name" {
  value = azurerm_key_vault.kv.name
}

output "key_vault_uri" {
  value = azurerm_key_vault.kv.vault_uri
}

output "key_vault_secrets" {
  value = keys(local.secrets)
}
