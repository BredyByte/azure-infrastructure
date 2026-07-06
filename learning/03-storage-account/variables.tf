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

#
# Storage Account
#

variable "account_tier" {
  description = "Storage Account tier."
  type        = string
}

variable "account_replication_type" {
  description = "Storage Account replication."
  type        = string
}

variable "containers" {
  description = "Blob containers."
  type        = list(string)
}

#
# App Service Plan
#

variable "app_service_plan_sku" {
  description = "App Service Plan SKU."
  type        = string
}

variable "worker_count" {
  description = "Number of workers."
  type        = number
}

variable "zone_balancing_enabled" {
  description = "Enable Zone Balancing."
  type        = bool
}

#
# App Service
#

variable "python_version" {
  description = "Python version."
  type        = string
}

#
# Common
#

variable "tags" {
  description = "Common tags."
  type        = map(string)
}
