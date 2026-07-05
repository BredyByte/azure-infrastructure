variable "location" {
  description = "Azure region."
  type        = string
}

variable "environment" {
  description = "Deployment environment."
  type        = string
}

variable "project" {
  description = "Project name."
  type        = string
}

variable "app_service_plan_sku" {
  description = "App Service Plan pricing tier."
  type        = string
}

variable "worker_count" {
  description = "Number of App Service Plan workers."
  type        = number
}

variable "zone_balancing_enabled" {
  description = "Enable zone balancing."
  type        = bool
}

variable "python_version" {
  description = "Python runtime version."
  type        = string
}

variable "tags" {
  description = "Common resource tags."
  type        = map(string)
}
