resource "azurerm_key_vault" "this" {

  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name

  tenant_id = var.tenant_id

  sku_name = "standard"

  soft_delete_retention_days = 7

  purge_protection_enabled = false

  rbac_authorization_enabled = true

  tags = var.tags

}

resource "azurerm_role_assignment" "current_user_kv_admin" {

  scope = azurerm_key_vault.this.id

  role_definition_name = "Key Vault Administrator"

  principal_id = var.current_user_object_id

}

resource "azurerm_key_vault_secret" "this" {

  ## Terraform creates resources in parallel whenever it can.
  ## This ensures the role assignment is created before Terraform starts creating secrets.
  depends_on =[
    azurerm_role_assignment.current_user_kv_admin
  ]

  for_each = var.secrets

  name  = each.key

  value = each.value

  key_vault_id = azurerm_key_vault.this.id
}

