output "resource_group_name" {
  value = module.resource_group.name
}

output "storage_account_name" {
  value = module.storage_account.name
}

output "storage_blob_endpoint" {
  value = module.storage_account.primary_blob_endpoint
}

output "app_service_plan_name" {
  value = module.app_service_plan.name
}

output "web_app_name" {
  value = module.app_service.name
}

output "web_app_url" {
  value = module.app_service.default_hostname
}
