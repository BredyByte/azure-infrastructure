locals {

  names = {

    resource_group = "rg-${var.environment}-${var.project}"

    app_service_plan = "asp-${var.environment}-${var.project}"

    app_service = "app-${var.environment}-${var.project}"

    storage_account = "st${var.environment}${var.project}"

    sql_server = "sql-${var.environment}-${var.project}"

    sql_database = "sqldb-${var.environment}-${var.project}"

    key_vault = "kv-${var.environment}-${var.project}"

  }

}
