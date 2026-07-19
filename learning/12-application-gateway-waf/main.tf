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

  private_dns_zone_sql       = "privatelink.database.windows.net"
  private_dns_zone_key_vault = "privatelink.vaultcore.azure.net"
  private_dns_zone_storage   = "privatelink.blob.core.windows.net"
  private_dns_zone_app       = "privatelink.azurewebsites.net"

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

# Create the VNet
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

# Create the private endpoint subnet
resource "azurerm_subnet" "private_endpoints" {
  name                 = local.private_endpoints_subnet_name
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = local.private_endpoints_subnet_prefixes

  # Allow the NSG to filter traffic to private endpoint NICs.
  # https://learn.microsoft.com/en-us/azure/private-link/disable-private-endpoint-network-policy?tabs=network-policy-json
  private_endpoint_network_policies = "NetworkSecurityGroupEnabled"
}

############################################################
# Network Security Groups
############################################################

resource "azurerm_network_security_group" "app_gateway" {
  name                = "nsg-app-gateway"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  tags = local.tags
}

resource "azurerm_network_security_group" "app_service" {
  name                = "nsg-app-service"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  tags = local.tags
}

resource "azurerm_network_security_group" "private_endpoints" {
  name                = "nsg-private-endpoints"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  tags = local.tags
}

# Allows the App Service integration subnet to reach Azure SQL privately.
resource "azurerm_network_security_rule" "allow_app_service_to_sql" {
  name                        = "allow-app-service-to-sql"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "1433"
  source_address_prefix       = "10.20.1.0/26"
  destination_address_prefix  = "10.20.2.0/27"
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.private_endpoints.name
  description                 = "Allows the App Service integration subnet to reach Azure SQL privately."
}

# Allows the App Service integration subnet to reach Key Vault and Blob Storage privately.
resource "azurerm_network_security_rule" "allow_app_service_to_private_https" {
  name                        = "allow-app-service-to-private-https"
  priority                    = 110
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "443"
  source_address_prefix       = "10.20.1.0/26"
  destination_address_prefix  = "10.20.2.0/27"
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.private_endpoints.name
  description                 = "Allows the App Service integration subnet to reach Key Vault and Blob Storage privately."
}

# Allows the future Application Gateway subnet to reach the App Service private endpoint.
resource "azurerm_network_security_rule" "allow_gateway_to_app_service" {
  name                        = "allow-gateway-to-app-service"
  priority                    = 120
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "443"
  source_address_prefix       = "10.20.0.0/24"
  destination_address_prefix  = "10.20.2.0/27"
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.private_endpoints.name
  description                 = "Allows Application Gateway to reach the App Service private endpoint over HTTPS."
}

# Blocks other VNet traffic before Azure's broad AllowVNetInBound default rule.
resource "azurerm_network_security_rule" "deny_vnet_to_private_endpoints" {
  name                        = "deny-vnet-to-private-endpoints"
  priority                    = 200
  direction                   = "Inbound"
  access                      = "Deny"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "VirtualNetwork"
  destination_address_prefix  = "10.20.2.0/27"
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.private_endpoints.name
  description                 = "Blocks other VNet traffic before Azure's broad AllowVNetInBound default rule."
}

resource "azurerm_subnet_network_security_group_association" "app_gateway" {
  subnet_id                 = azurerm_subnet.app_gateway.id
  network_security_group_id = azurerm_network_security_group.app_gateway.id
}

resource "azurerm_subnet_network_security_group_association" "app_service" {
  subnet_id                 = azurerm_subnet.app_service_integration.id
  network_security_group_id = azurerm_network_security_group.app_service.id
}

resource "azurerm_subnet_network_security_group_association" "private_endpoints" {
  subnet_id                 = azurerm_subnet.private_endpoints.id
  network_security_group_id = azurerm_network_security_group.private_endpoints.id
}

############################################################
# Application Gateway NSG Rules
############################################################

# Allows users on the Internet to reach the HTTP listener.
resource "azurerm_network_security_rule" "allow_http_from_internet" {
  name                        = "allow-http-from-internet"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "80"
  source_address_prefix       = "Internet"
  destination_address_prefix  = "10.20.0.0/24"
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.app_gateway.name
  description                 = "Allows HTTP traffic from the Internet to Application Gateway."
}

# Reserved now for the future HTTPS listener.
resource "azurerm_network_security_rule" "allow_https_from_internet" {
  name                        = "allow-https-from-internet"
  priority                    = 110
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "443"
  source_address_prefix       = "Internet"
  destination_address_prefix  = "10.20.0.0/24"
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.app_gateway.name
  description                 = "Allows HTTPS traffic from the Internet to Application Gateway."
}

# Required by the Application Gateway v2 control plane.
# The destination must be Any: GatewayManager is not client traffic to the subnet.
resource "azurerm_network_security_rule" "allow_gateway_manager" {
  name                        = "allow-gateway-manager"
  priority                    = 120
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "65200-65535"
  source_address_prefix       = "GatewayManager"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.app_gateway.name
  description                 = "Allows the required Application Gateway v2 control-plane traffic."
}

############################################################
# Private DNS Zones and VNet Links
############################################################

# Create the SQL private DNS zone
resource "azurerm_private_dns_zone" "sql" {
  name                = local.private_dns_zone_sql
  resource_group_name = azurerm_resource_group.rg.name
  tags                = local.tags
}

resource "azurerm_private_dns_zone" "key_vault" {
  name                = local.private_dns_zone_key_vault
  resource_group_name = azurerm_resource_group.rg.name
  tags                = local.tags
}

resource "azurerm_private_dns_zone" "storage" {
  name                = local.private_dns_zone_storage
  resource_group_name = azurerm_resource_group.rg.name
  tags                = local.tags
}

resource "azurerm_private_dns_zone" "app" {
  name                = local.private_dns_zone_app
  resource_group_name = azurerm_resource_group.rg.name
  tags                = local.tags
}

# Link the DNS zone to the VNet
resource "azurerm_private_dns_zone_virtual_network_link" "sql" {
  name                  = "link-sql"
  resource_group_name   = azurerm_resource_group.rg.name
  private_dns_zone_name = azurerm_private_dns_zone.sql.name
  virtual_network_id    = azurerm_virtual_network.vnet.id
  registration_enabled  = false
  tags                  = local.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "key_vault" {
  name                  = "link-key-vault"
  resource_group_name   = azurerm_resource_group.rg.name
  private_dns_zone_name = azurerm_private_dns_zone.key_vault.name
  virtual_network_id    = azurerm_virtual_network.vnet.id
  registration_enabled  = false
  tags                  = local.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "storage" {
  name                  = "link-storage"
  resource_group_name   = azurerm_resource_group.rg.name
  private_dns_zone_name = azurerm_private_dns_zone.storage.name
  virtual_network_id    = azurerm_virtual_network.vnet.id
  registration_enabled  = false
  tags                  = local.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "app" {
  # Azure generated this name during the manual private-endpoint creation.
  name                  = "mu7ibj3lhg6kc"
  resource_group_name   = azurerm_resource_group.rg.name
  private_dns_zone_name = azurerm_private_dns_zone.app.name
  virtual_network_id    = azurerm_virtual_network.vnet.id
  registration_enabled  = false
  tags                  = local.tags
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

  account_tier                  = "Standard"
  account_replication_type      = "LRS"
  public_network_access_enabled = false

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
  public_network_access_enabled = false

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

  rbac_authorization_enabled    = true
  public_network_access_enabled = false

  tags = local.tags
}

# Temporarily disabled because Terraform is running outside the VNet and
# cannot reach the private Key Vault to create or delete secrets.
# (RBAC) Assign role to user(me)
# resource "azurerm_role_assignment" "current_user_kv_admin" {
#   scope                = azurerm_key_vault.kv.id
#   role_definition_name = "Key Vault Administrator"
#   principal_id         = local.current_user_object_id
# }

# (RBAC) Allows the web app's managed identity to read values from Key Vault.
resource "azurerm_role_assignment" "app_key_vault_secrets_user" {
  scope                = azurerm_key_vault.kv.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_linux_web_app.app.identity[0].principal_id
}

# Temporarily disabled because Terraform is running outside the VNet and
# cannot reach the private Key Vault to create or delete secrets.
# Key Vault secrets creation
# resource "azurerm_key_vault_secret" "this" {

#   depends_on = [
#     azurerm_role_assignment.current_user_kv_admin
#   ]

#   for_each = local.secrets

#   name  = each.key
#   value = each.value

#   key_vault_id = azurerm_key_vault.kv.id
# }

############################################################
# Private Endpoints
############################################################

# Connect SQL to the private endpoint subnet
resource "azurerm_private_endpoint" "sql" {
  name                = "pe-sql-dev-helloworld"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = azurerm_subnet.private_endpoints.id

  # Create a network interface (NIC) and assigne  a dynamic IP
  private_service_connection {
    name                           = "psc-sql-dev-helloworld"
    private_connection_resource_id = azurerm_mssql_server.sql.id
    subresource_names              = ["sqlServer"]
    is_manual_connection           = false
  }

  # Assign the SQL private endpoint to the DNS zone
  private_dns_zone_group {
    name                 = "sql-dns-zone-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.sql.id]
  }

  tags = local.tags
}

resource "azurerm_private_endpoint" "key_vault" {
  name                = "pe-kv-dev-helloworld"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = azurerm_subnet.private_endpoints.id

  private_service_connection {
    name                           = "psc-kv-dev-helloworld"
    private_connection_resource_id = azurerm_key_vault.kv.id
    subresource_names              = ["vault"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "key-vault-dns-zone-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.key_vault.id]
  }

  tags = local.tags
}

resource "azurerm_private_endpoint" "storage_blob" {
  name                = "pe-storage-dev-helloworld"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = azurerm_subnet.private_endpoints.id

  private_service_connection {
    name                           = "psc-storage-blob-dev-helloworld"
    private_connection_resource_id = azurerm_storage_account.storage.id
    subresource_names              = ["blob"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "storage-dns-zone-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.storage.id]
  }

  tags = local.tags
}

# Allows private inbound access to the web application from the VNet.
resource "azurerm_private_endpoint" "app" {
  name                = "pe-app-dev-helloworld"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = azurerm_subnet.private_endpoints.id

  # Preserve the Azure-generated NIC name from the manually created endpoint.
  custom_network_interface_name = "pe-app-dev-helloworld-nic"

  private_service_connection {
    # Preserve the connection name from the manually created endpoint.
    name                           = "pe-app-dev-helloworld"
    private_connection_resource_id = azurerm_linux_web_app.app.id
    subresource_names              = ["sites"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    # Azure created the manual DNS zone group with this default name.
    name                 = "default"
    private_dns_zone_ids = [azurerm_private_dns_zone.app.id]
  }

  tags = local.tags
}


############################################################
# Application Gateway and Web Application Firewall
############################################################

# The only public entry point for the application architecture.
resource "azurerm_public_ip" "app_gateway" {
  name                = "pip-appgw-dev-helloworld"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  allocation_method       = "Static"
  sku                     = "Standard"
  zones                   = ["1", "2", "3"]
  idle_timeout_in_minutes = 4

  tags = local.tags
}

# This policy inspects requests before they are forwarded to the web app.
# Detection mode logs suspicious requests but does not yet block them.
resource "azurerm_web_application_firewall_policy" "app_gateway" {
  name                = "wafpol-dev-helloworld"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  policy_settings {
    enabled                          = true
    mode                             = "Detection"
    request_body_check               = true
    request_body_enforcement         = true
    request_body_inspect_limit_in_kb = 128
    file_upload_enforcement          = true
    file_upload_limit_in_mb          = 100
    max_request_body_size_in_kb      = 128
  }

  managed_rules {
    managed_rule_set {
      type    = "OWASP"
      version = "3.2"
    }
  }

  tags = local.tags
}

resource "azurerm_application_gateway" "app_gateway" {
  name                = "agw-dev-helloworld"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  http2_enabled      = true
  firewall_policy_id = azurerm_web_application_firewall_policy.app_gateway.id
  zones              = ["1", "2", "3"]

  sku {
    name = "WAF_v2"
    tier = "WAF_v2"
  }

  autoscale_configuration {
    min_capacity = 1
    max_capacity = 2
  }

  gateway_ip_configuration {
    name      = "appGatewayIpConfig"
    subnet_id = azurerm_subnet.app_gateway.id
  }

  frontend_port {
    name = "port_80"
    port = 80
  }

  frontend_ip_configuration {
    name                 = "appGwPublicFrontendIpIPv4"
    public_ip_address_id = azurerm_public_ip.app_gateway.id
  }

  # Keep the normal App Service hostname. Private DNS resolves it to the
  # private endpoint IP from inside this VNet.
  backend_address_pool {
    name  = "pool-app-service"
    fqdns = [azurerm_linux_web_app.app.default_hostname]
  }

  backend_http_settings {
    name                  = "bhs-app-service-https"
    cookie_based_affinity = "Disabled"
    port                  = 443
    protocol              = "Https"
    request_timeout       = 30
    host_name             = azurerm_linux_web_app.app.default_hostname
    probe_name            = "probe-app-service"
  }

  # Azure checks this endpoint before sending users' requests to the backend.
  probe {
    name                                      = "probe-app-service"
    protocol                                  = "Https"
    host                                      = azurerm_linux_web_app.app.default_hostname
    path                                      = "/"
    interval                                  = 30
    timeout                                   = 30
    unhealthy_threshold                       = 3
    minimum_servers                           = 0
    pick_host_name_from_backend_http_settings = false

    match {
      status_code = ["200-399"]
    }
  }

  http_listener {
    name                           = "listener-http"
    frontend_ip_configuration_name = "appGwPublicFrontendIpIPv4"
    frontend_port_name             = "port_80"
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = "rule-http-to-app"
    rule_type                  = "Basic"
    priority                   = 1
    http_listener_name         = "listener-http"
    backend_address_pool_name  = "pool-app-service"
    backend_http_settings_name = "bhs-app-service-https"
  }

  tags = local.tags
}


############################################################
# Application Gateway Diagnostics
############################################################

# Central workspace that stores and makes Azure monitoring logs searchable with KQL.
resource "azurerm_log_analytics_workspace" "monitoring" {
  name                = "law-dev-helloworld"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30

  tags = local.tags
}

# Sends Application Gateway access and WAF logs to the Log Analytics Workspace.
resource "azurerm_monitor_diagnostic_setting" "app_gateway" {
  name                           = "diag-app-gateway"
  target_resource_id             = azurerm_application_gateway.app_gateway.id
  log_analytics_workspace_id     = azurerm_log_analytics_workspace.monitoring.id
  log_analytics_destination_type = "Dedicated"

  enabled_log {
    category = "ApplicationGatewayAccessLog"
  }

  enabled_log {
    category = "ApplicationGatewayFirewallLog"
  }
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
