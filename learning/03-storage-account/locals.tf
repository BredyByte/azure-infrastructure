locals {

  names = {

    resource_group = "rg-${var.environment}-${var.project}"

    app_service_plan = "asp-${var.environment}-${var.project}"

    app_service = "app-${var.environment}-${var.project}"

    storage_account = "st${var.environment}${var.project}"

  }

}
