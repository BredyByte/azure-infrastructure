# Reads tenant and subscription information from the Azure account
# that runs Terraform.
data "azurerm_client_config" "current" {}

############################################################
# Shared foundation
############################################################

resource "azurerm_resource_group" "rg" {
  name     = local.resource_group_name
  location = var.location

  tags = local.common_tags
}

############################################################
# Networking foundation
############################################################

module "networking" {
  source = "./modules/networking"

  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  tags                = local.common_tags

  ##########################################################
  # Azure DDoS Network Protection
  ##########################################################

  enable_ddos_network_protection = var.enable_ddos_network_protection

  ddos_network_protection_plan_name = local.ddos_network_protection_plan_name

  ##########################################################
  # Application network
  ##########################################################

  application_vnet_name          = local.application_vnet_name
  application_vnet_address_space = var.application_vnet_address_space

  app_gateway_subnet_name     = local.app_gateway_subnet_name
  app_gateway_subnet_prefixes = var.app_gateway_subnet_prefixes

  app_service_subnet_name     = local.app_service_subnet_name
  app_service_subnet_prefixes = var.app_service_subnet_prefixes

  private_endpoints_subnet_name = (
    local.private_endpoints_subnet_name
  )

  private_endpoints_subnet_prefixes = (
    var.private_endpoints_subnet_prefixes
  )

  ##########################################################
  # Deployment network
  ##########################################################

  deployment_vnet_name          = local.deployment_vnet_name
  deployment_vnet_address_space = var.deployment_vnet_address_space

  deployment_bastion_subnet_name = (
    local.deployment_bastion_subnet_name
  )

  deployment_bastion_subnet_prefixes = (
    var.deployment_bastion_subnet_prefixes
  )

  deployment_agent_subnet_name = (
    local.deployment_agent_subnet_name
  )

  deployment_agent_subnet_prefixes = (
    var.deployment_agent_subnet_prefixes
  )
}

############################################################
# Private DNS
############################################################

module "private_dns" {
  source = "./modules/private_dns"

  resource_group_name = azurerm_resource_group.rg.name
  tags                = local.common_tags

  application_vnet_id = module.networking.application_vnet_id
  deployment_vnet_id  = module.networking.deployment_vnet_id
}

############################################################
# Microsoft Entra identity
############################################################

module "identity" {
  source = "./modules/identity"

  sql_administrator_group_display_name = local.sql_administrators_group_name
  sql_administrator_user_principal_name = (
    var.sql_administrator_user_principal_name
  )
}

############################################################
# Data services
############################################################

module "data_services" {
  source = "./modules/data_services"

  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  tenant_id           = data.azurerm_client_config.current.tenant_id
  tags                = local.common_tags

  ##########################################################
  # Storage
  ##########################################################

  storage_account_name     = local.storage_account_name
  storage_account_tier     = var.storage_account_tier
  storage_replication_type = var.storage_account_replication_type
  storage_container_names  = local.storage_container_names

  ##########################################################
  # Azure SQL
  ##########################################################

  sql_server_name       = local.sql_server_name
  sql_database_name     = local.sql_database_name
  sql_database_sku_name = var.sql_database_sku_name

  sql_administrator_group_display_name = (
    module.identity.sql_administrator_group_display_name
  )

  sql_administrator_group_object_id = (
    module.identity.sql_administrator_group_object_id
  )

  ##########################################################
  # Azure Key Vault
  ##########################################################

  key_vault_name = local.key_vault_name

  depends_on = [module.identity]
}

############################################################
# App Service
############################################################

module "app_service" {
  source = "./modules/app_service"

  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  tags                = local.common_tags

  app_service_plan_name     = local.app_service_plan_name
  app_service_plan_sku_name = var.app_service_plan_sku_name

  web_app_name               = local.web_app_name
  app_service_python_version = var.app_service_python_version

  app_service_integration_subnet_id = (
    module.networking.app_service_integration_subnet_id
  )

  key_vault_uri                          = module.data_services.key_vault_uri
  storage_account_name                   = module.data_services.storage_account_name
  sql_server_fqdn                        = module.data_services.sql_server_fqdn
  sql_database_name                      = module.data_services.sql_database_name
  application_insights_connection_string = module.monitoring.application_insights_connection_string

}

############################################################
# Private connectivity
############################################################

module "private_connectivity" {
  source = "./modules/private_connectivity"

  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  tags                = local.common_tags

  ##########################################################
  # Networking
  ##########################################################

  private_endpoints_subnet_id = (
    module.networking.private_endpoints_subnet_id
  )

  name_prefix = local.name_prefix

  ##########################################################
  # Private Link service resources
  ##########################################################

  sql_server_id      = module.data_services.sql_server_id
  key_vault_id       = module.data_services.key_vault_id
  storage_account_id = module.data_services.storage_account_id
  web_app_id         = module.app_service.web_app_id

  ##########################################################
  # Private DNS Zones
  ##########################################################

  private_dns_zone_ids = {
    sql = module.private_dns.private_dns_zone_ids.sql

    key_vault = (
      module.private_dns.private_dns_zone_ids.key_vault
    )

    storage_blob = (
      module.private_dns.private_dns_zone_ids.storage
    )

    app_service = (
      module.private_dns.private_dns_zone_ids.app_service
    )
  }
}

############################################################
# Edge Gateway
############################################################

module "edge_gateway" {
  source = "./modules/edge_gateway"

  name_prefix         = local.name_prefix
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  tags                = local.common_tags

  ##########################################################
  # Networking
  ##########################################################

  app_gateway_subnet_id = (
    module.networking.app_gateway_subnet_id
  )

  ##########################################################
  # App Service backend
  ##########################################################

  web_app_default_hostname = (
    module.app_service.web_app_default_hostname
  )

  # Networking must finish its NSG rules and the App Service
  # Private Endpoint and Private DNS must already exist.
  depends_on = [
    module.networking,
    module.private_connectivity,
  ]
}

############################################################
# Deployment platform
############################################################

module "deployment_platform" {
  source = "./modules/deployment_platform"

  name_prefix         = local.name_prefix
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  tags                = local.common_tags

  ##########################################################
  # Networking
  ##########################################################

  deployment_bastion_subnet_id = (
    module.networking.deployment_bastion_subnet_id
  )

  deployment_agent_subnet_id = (
    module.networking.deployment_agent_subnet_id
  )

  ##########################################################
  # Deployment VM
  ##########################################################

  deployment_agent_vm_size = (
    var.deployment_agent_vm_size
  )

  deployment_agent_admin_username = (
    var.deployment_agent_admin_username
  )

  deployment_agent_ssh_public_key_path = (
    var.deployment_agent_ssh_public_key_path
  )

  depends_on = [
    module.networking,
  ]
}

############################################################
# Access control
############################################################

module "access_control" {
  source = "./modules/access_control"

  ##########################################################
  # Managed identities
  ##########################################################

  web_app_principal_id = (
    module.app_service.web_app_principal_id
  )

  deployment_agent_principal_id = (
    module.deployment_platform.deployment_agent_principal_id
  )

  ##########################################################
  # Azure resource scopes
  ##########################################################

  storage_account_id = (
    module.data_services.storage_account_id
  )

  key_vault_id = (
    module.data_services.key_vault_id
  )

  web_app_id = (
    module.app_service.web_app_id
  )

  ##########################################################
  # Microsoft Entra SQL group
  ##########################################################

  sql_administrator_group_object_id = (
    module.identity.sql_administrator_group_object_id
  )
}

############################################################
# Monitoring
############################################################

module "monitoring" {
  source = "./modules/monitoring"

  name_prefix         = local.name_prefix
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  tags                = local.common_tags

  ##########################################################
  # Log Analytics
  ##########################################################

  log_analytics_retention_in_days = (
    var.log_analytics_retention_in_days
  )

  ##########################################################
  # Application Gateway
  ##########################################################

  application_gateway_id = (
    module.edge_gateway.application_gateway_id
  )
}

############################################################
# Alerting
############################################################

module "alerting" {
  source = "./modules/alerting"

  resource_group_name = azurerm_resource_group.rg.name
  web_app_id          = module.app_service.web_app_id

  action_group_name          = "ag-dev-helloworldf800"
  action_group_email_address = var.action_group_email_address
  metric_alert_name          = "webapp-http4xx-warning-dev-helloworldf800"

  tags = local.common_tags
}
