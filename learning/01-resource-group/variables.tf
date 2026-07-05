variable "location" {
  description = "Azure region where resources will be deployed."
  type        = string
}

variable "environment" {
  description = "Deployment environment (dev, test, prod)."
  type        = string
}

variable "project" {
  description = "Project name."
  type        = string
}

variable "tags" {
  description = "Common tags applied to all Azure resources."
  type        = map(string)
}
