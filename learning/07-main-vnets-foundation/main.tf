terraform {
  required_version = ">= 1.5"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.80"
    }

    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 3.0"
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

provider "azuread" {}

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
  storage_containers = toset([
    "images",
    "data",
    "text",
  ])

  sql_server_location                 = "France Central"
  sql_server                          = "sql-dev-helloworld"
  sql_database                        = "sqldb-dev-helloworld"
  sql_entra_admin_user_principal_name = "correodemimobil_gmail.com#EXT#@correodemimobilgmail.onmicrosoft.com"

  key_vault              = "kv-dev-helloworld"
  current_user_object_id = data.azurerm_client_config.current.object_id

  virtual_network_name          = "vnet-dev-helloworld"
  virtual_network_address_space = ["10.20.0.0/16"]

  app_gateway_subnet_name     = "snet-app-gateway"
  app_gateway_subnet_prefixes = ["10.20.0.0/24"]

  app_service_subnet_name     = "snet-app-service-integration"
  app_service_subnet_prefixes = ["10.20.1.0/26"]

  private_endpoints_subnet_name     = "snet-private-endpoints"
  private_endpoints_subnet_prefixes = ["10.20.2.0/27"]

  secrets = {
    welcome-message = "Welcome David from Azure Key Vault!"
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
# Virtual Network
############################################################

resource "azurerm_virtual_network" "vnet" {
  name                = local.virtual_network_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = local.virtual_network_address_space

  tags = local.tags
}

resource "azurerm_subnet" "app_gateway" {
  name                 = local.app_gateway_subnet_name
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = local.app_gateway_subnet_prefixes
}

resource "azurerm_subnet" "app_service_integration" {
  name                 = local.app_service_subnet_name
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = local.app_service_subnet_prefixes

  delegation {
    name = "app-service-delegation"

    service_delegation {
      name = "Microsoft.Web/serverFarms"
      actions = [
        # Reserve that subnet for App Service use.
        "Microsoft.Network/virtualNetworks/subnets/action",
      ]
    }
  }
}

resource "azurerm_subnet" "private_endpoints" {
  name                 = local.private_endpoints_subnet_name
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = local.private_endpoints_subnet_prefixes

  private_endpoint_network_policies = "Disabled"
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

  # Sends the App Service's private outbound traffic through the delegated subnet.
  virtual_network_subnet_id = azurerm_subnet.app_service_integration.id

  # Creates a Microsoft Entra service principal for this App Service.
  identity {
    type = "SystemAssigned"
  }

  app_settings = {
    KEY_VAULT_URL              = azurerm_key_vault.kv.vault_uri
    AZURE_STORAGE_ACCOUNT_NAME = azurerm_storage_account.storage.name
    SQL_SERVER                 = azurerm_mssql_server.sql.fully_qualified_domain_name
    SQL_DATABASE               = azurerm_mssql_database.database.name
  }

  site_config {
    always_on = true
    # Route all app outbound traffic through your VNet.
    vnet_route_all_enabled = true

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

resource "azurerm_storage_container" "containers" {
  for_each = local.storage_containers

  name                  = each.value
  storage_account_id    = azurerm_storage_account.storage.id
  container_access_type = "private"
}

# (RBAC) Allows the web app's managed identity to read and list blobs.
resource "azurerm_role_assignment" "app_storage_blob_data_reader" {
  scope                = azurerm_storage_account.storage.id
  role_definition_name = "Storage Blob Data Reader"
  principal_id         = azurerm_linux_web_app.app.identity[0].principal_id
}

# (RBAC) Allows the user(me) to manage blob's content.
resource "azurerm_role_assignment" "current_user_storage_blob_owner" {
  scope                = azurerm_storage_account.storage.id
  role_definition_name = "Storage Blob Data Owner"
  principal_id         = data.azurerm_client_config.current.object_id
}

############################################################
# SQL Server
############################################################

data "azuread_user" "sql_admin" {
  user_principal_name = local.sql_entra_admin_user_principal_name
}

resource "azurerm_mssql_server" "sql" {
  name                = local.sql_server
  resource_group_name = azurerm_resource_group.rg.name
  location            = local.sql_server_location

  version = "12.0"

  minimum_tls_version           = "1.2"
  public_network_access_enabled = true

  # This administrator can create Microsoft Entra users inside the database.
  azuread_administrator {
    login_username              = data.azuread_user.sql_admin.user_principal_name
    object_id                   = data.azuread_user.sql_admin.object_id
    tenant_id                   = data.azurerm_client_config.current.tenant_id
    azuread_authentication_only = true
  }

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

# (RBAC) Assign role to user(me)
resource "azurerm_role_assignment" "current_user_kv_admin" {
  scope                = azurerm_key_vault.kv.id
  role_definition_name = "Key Vault Administrator"
  principal_id         = local.current_user_object_id
}

# (RBAC) Allows the web app's managed identity to read values from Key Vault.
resource "azurerm_role_assignment" "app_key_vault_secrets_user" {
  scope                = azurerm_key_vault.kv.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_linux_web_app.app.identity[0].principal_id
}

# Key Vault secrets creation
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

output "web_app_principal_id" {
  value = azurerm_linux_web_app.app.identity[0].principal_id
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
