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


output "sql_server_name" {
  value = module.sql_server.name
}

output "sql_server_fqdn" {
  value = module.sql_server.fully_qualified_domain_name
}

output "sql_database_name" {
  value = module.sql_database.name
}
