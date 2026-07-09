variable "name" {
  description = "Key Vault name."
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

variable "tenant_id" {
  description = "Azure Tenant ID."
  type        = string
}

variable "secrets" {
  description = "Secrets to create inside the Key Vault."
  type = map(string)
  default = {}
}

variable "current_user_object_id" {
  description = "Object ID of the current Azure user."
  type        = string
}

variable "tags" {
  description = "Common tags."
  type        = map(string)
}
