variable "name" {
  description = "Storage Account name."
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

variable "account_tier" {
  description = "Storage Account tier."
  type        = string
}

variable "account_replication_type" {
  description = "Storage Account replication type."
  type        = string
}

variable "containers" {
  description = "Blob containers to create."
  type        = list(string)
}

variable "tags" {
  description = "Common tags."
  type        = map(string)
}
