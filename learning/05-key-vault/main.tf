data "azurerm_client_config" "current" {}


############################################################
# RESOURCE GROUP
############################################################

module "resource_group" {

  source = "../../modules/resource-group"

  name     = local.names.resource_group
  location = var.location

  tags = var.tags
}

############################################################
# STORAGE ACCOUNT
############################################################

module "storage_account" {

  source = "../../modules/storage-account"

  name = local.names.storage_account

  location = module.resource_group.location

  resource_group_name = module.resource_group.name

  account_tier = var.account_tier

  account_replication_type = var.account_replication_type

  containers = var.containers

  tags = var.tags
}

############################################################
# APP SERVICE PLAN
############################################################

module "app_service_plan" {

  source = "../../modules/app-service-plan"

  name = local.names.app_service_plan

  location = module.resource_group.location

  resource_group_name = module.resource_group.name

  sku_name = var.app_service_plan_sku

  worker_count = var.worker_count

  zone_balancing_enabled = var.zone_balancing_enabled

  tags = var.tags
}

############################################################
# APP SERVICE
############################################################

module "app_service" {

  source = "../../modules/app-service"

  name = local.names.app_service

  location = module.resource_group.location

  resource_group_name = module.resource_group.name

  service_plan_id = module.app_service_plan.id

  python_version = var.python_version

  tags = var.tags
}

############################################################
# SQL SERVER
############################################################

module "sql_server" {
  source = "../../modules/sql-server"

  name                = local.names.sql_server
  resource_group_name = module.resource_group.name
  location            = var.sql_location

  administrator_login    = var.sql_admin_login
  administrator_password = var.sql_admin_password

  tags = var.tags
}

############################################################
# SQL DATABASE
############################################################

module "sql_database" {
  source = "../../modules/sql-database"

  name = local.names.sql_database

  server_id = module.sql_server.id

  sku_name             = var.sql_database_sku
  zone_redundant       = var.sql_zone_redundant
  storage_account_type = var.storage_account_type


  tags = var.tags
}

############################################################
# KEY VAULT
############################################################

module "key_vault" {

  source = "../../modules/key-vault"

  name = local.names.key_vault

  location = var.location

  resource_group_name = module.resource_group.name

  tenant_id = data.azurerm_client_config.current.tenant_id

  tags = var.tags

}
