############################################################
# Resource Group
############################################################

module "resource_group" {

  source = "../../modules/resource-group"

  name     = local.names.resource_group
  location = var.location

  tags = var.tags
}

############################################################
# Storage Account
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
# App Service Plan
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
# App Service
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
