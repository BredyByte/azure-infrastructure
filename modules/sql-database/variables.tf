variable "name" {
  description = "SQL Database name."
  type        = string
}

variable "server_id" {
  description = "SQL Server ID."
  type        = string
}

variable "sku_name" {
  description = "SQL Database SKU."
  type        = string
}

variable "zone_redundant" {
  description = "Enable zone redundancy."
  type        = bool
}

variable "storage_account_type" {
  description = "Backup storage redundancy."
  type        = string
}

variable "tags" {
  description = "Common tags."
  type        = map(string)
}


