variable "name" {
  description = "Linux Web App name."
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

variable "service_plan_id" {
  description = "App Service Plan ID."
  type        = string
}

variable "python_version" {
  description = "Python runtime version."
  type        = string
}

variable "tags" {
  description = "Tags applied to the resource."
  type        = map(string)
}
