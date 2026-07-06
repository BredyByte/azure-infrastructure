location = "West Europe"

environment = "dev"

project = "helloworld"

############################################################
# Storage Account
############################################################

account_tier             = "Standard"
account_replication_type = "LRS"

containers = [
  "images",
  "data",
  "text"
]

############################################################
# App Service Plan
############################################################

app_service_plan_sku   = "B1"
worker_count           = 1
zone_balancing_enabled = false

# Production
# app_service_plan_sku   = "P1v3"
# worker_count           = 3
# zone_balancing_enabled = true

############################################################
# App Service
############################################################

python_version = "3.12"

############################################################
# Tags
############################################################

tags = {

  Environment = "Development"

  Project = "Hello World"

  Owner = "Davyd Bredykhin"

  ManagedBy = "Terraform"

}
