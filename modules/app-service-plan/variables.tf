variable "name" {
  description = "App Service Plan name."
  type        = string
}

variable "location" {
  description = "Azure region."
  type        = string
}

variable "resource_group_name" {
  description = "Resource Group name."
  type        = string
}

variable "os_type" {
  description = "Operating system."
  type        = string
  default     = "Linux"
}

variable "sku_name" {
  description = "Pricing tier."
  type        = string
}

variable "worker_count" {
  description = "Number of workers."
  type        = number
  default     = 1
}

variable "zone_balancing_enabled" {
  description = "Enable zone balancing."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Resource tags."
  type        = map(string)
}
