variable "location" {
  type = string
}

variable "environment" {
  type = string
}

variable "project" {
  type = string
}

variable "app_service_plan_sku" {
  type = string
}

variable "python_version" {
  type = string
}

variable "tags" {
  type = map(string)
}
