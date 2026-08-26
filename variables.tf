############################################################
# General deployment inputs
############################################################

variable "location" {
  description = "Azure region where the project resources are deployed."
  type        = string
}

variable "environment" {
  description = "Short environment name used in resource names and tags."
  type        = string

  validation {
    condition     = contains(["dev", "test", "prod"], var.environment)
    error_message = "The environment must be one of: dev, test, prod."
  }
}

variable "project_name" {
  description = "Short project name used to build the permanent project identifier."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9]+$", var.project_name))
    error_message = "The project name must contain only lowercase letters and numbers."
  }
}

variable "project_display_name" {
  description = "Human-readable project name used in Azure tags."
  type        = string
}

variable "resource_suffix" {
  description = "Suffix appended directly to the project name to create its permanent identifier."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9]+$", var.resource_suffix))
    error_message = "The resource suffix must contain only lowercase letters and numbers."
  }
}

variable "owner" {
  description = "Owner recorded in the common Azure tags."
  type        = string
}

############################################################
# Networking inputs
############################################################

variable "application_vnet_address_space" {
  description = "Address space assigned to the application virtual network."
  type        = list(string)
}

variable "app_gateway_subnet_prefixes" {
  description = "Address prefixes assigned to the Application Gateway subnet."
  type        = list(string)
}

variable "app_service_subnet_prefixes" {
  description = "Address prefixes assigned to the App Service integration subnet."
  type        = list(string)
}

variable "private_endpoints_subnet_prefixes" {
  description = "Address prefixes assigned to the private endpoints subnet."
  type        = list(string)
}

variable "deployment_vnet_address_space" {
  description = "Address space assigned to the deployment virtual network."
  type        = list(string)
}

variable "deployment_bastion_subnet_prefixes" {
  description = "Address prefixes assigned to AzureBastionSubnet."
  type        = list(string)
}

variable "deployment_agent_subnet_prefixes" {
  description = "Address prefixes assigned to the deployment agent subnet."
  type        = list(string)
}

############################################################
# Azure DDoS Network Protection
############################################################

variable "enable_ddos_network_protection" {
  description = "Controls the paid Azure DDoS Network Protection plan and its association with both project VNets."
  type        = bool
}

############################################################
# Storage
############################################################

variable "storage_account_tier" {
  description = "Performance tier of the project Storage Account."
  type        = string

  validation {
    condition     = contains(["Standard", "Premium"], var.storage_account_tier)
    error_message = "The Storage Account tier must be Standard or Premium."
  }
}

############################################################
# Azure SQL Database
############################################################

variable "sql_database_sku_name" {
  description = "Azure SQL Database pricing SKU."
  type        = string

  validation {
    condition     = contains(["Basic", "S0", "S1", "S2", "S3"], var.sql_database_sku_name)
    error_message = "The SQL Database SKU must be Basic, S0, S1, S2 or S3."
  }
}

variable "storage_account_replication_type" {
  description = "Replication type of the project Storage Account."
  type        = string

  validation {
    condition = contains(
      ["LRS", "GRS", "RAGRS", "ZRS", "GZRS", "RAGZRS"],
      var.storage_account_replication_type
    )

    error_message = "The replication type must be LRS, GRS, RAGRS, ZRS, GZRS or RAGZRS."
  }
}

############################################################
# Microsoft Entra ID
############################################################

variable "sql_administrator_user_principal_name" {
  description = "Microsoft Entra user principal name added to the SQL administrators group."
  type        = string
}

############################################################
# App Service
############################################################

variable "app_service_plan_sku_name" {
  description = "Pricing SKU for the Linux App Service Plan."
  type        = string

  validation {
    condition     = contains(["B1", "B2", "B3", "S1", "S2", "S3"], var.app_service_plan_sku_name)
    error_message = "The App Service Plan SKU must be B1, B2, B3, S1, S2 or S3."
  }
}

variable "app_service_python_version" {
  description = "Python runtime version used by the Linux Web App."
  type        = string

  validation {
    condition     = contains(["3.10", "3.11", "3.12", "3.13"], var.app_service_python_version)
    error_message = "The Python version must be 3.10, 3.11, 3.12 or 3.13."
  }
}

############################################################
# Deployment platform
############################################################

variable "deployment_agent_vm_size" {
  description = "Azure size used by the deployment VM."
  type        = string
}

variable "deployment_agent_admin_username" {
  description = "Administrator username of the deployment VM."
  type        = string
}

variable "deployment_agent_ssh_public_key_path" {
  description = "Local path to the deployment VM SSH public key."
  type        = string
}

############################################################
# Monitoring
############################################################

variable "log_analytics_retention_in_days" {
  description = "Number of days that monitoring logs are retained."
  type        = number
}

############################################################
# Alerting
############################################################

variable "action_group_email_address" {
  description = "Email address that receives Azure Monitor alert notifications."
  type        = string
  sensitive   = true
}

