variable "name" {
  description = "SQL Server name."
  type        = string
}

variable "resource_group_name" {
  description = "Resource Group name."
  type        = string
}

variable "location" {
  description = "Azure region."
  type        = string
}

variable "administrator_login" {
  description = "SQL administrator username."
  type        = string
}

variable "administrator_password" {
  description = "SQL administrator password."
  type        = string
  sensitive   = true
}

variable "tags" {
  description = "Common tags."
  type        = map(string)
}
