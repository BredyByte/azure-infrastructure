location = "West Europe"

environment = "dev"

project = "helloworld"


app_service_plan_sku   = "B1"
worker_count           = 1
zone_balancing_enabled = false

# Production (Target Architecture)
# app_service_plan_sku   = "P1v3"
# worker_count           = 3
# zone_balancing_enabled = true

python_version = "3.12"


tags = {
  Environment = "Development"
  Project     = "Hello World"
  Owner       = "Davyd Bredykhin"
  ManagedBy   = "Terraform"
}
