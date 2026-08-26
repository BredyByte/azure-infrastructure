############################################################
# Resource Group
############################################################

variable "resource_group_name" {
  type = string
}

############################################################
# Web App
############################################################

variable "web_app_id" {
  description = "Resource ID of the Web App monitored by the metric alert."
  type        = string
}

############################################################
# Action Group
############################################################

variable "action_group_name" {
  description = "Name of the Azure Monitor Action Group."
  type        = string
}

variable "action_group_email_address" {
  description = "Email address that receives Azure Monitor alert notifications."
  type        = string
  sensitive   = true
}

############################################################
# Metric Alert
############################################################

variable "metric_alert_name" {
  description = "Name of the Web App HTTP 4xx metric alert."
  type        = string
}

############################################################
# Tags
############################################################

variable "tags" {
  type = map(string)
}
