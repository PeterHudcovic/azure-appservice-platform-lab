# The application managed identity reads secrets from the application vault of layer 2.
# The role is granted on the Key Vault resource group, which holds only the application vault, so it
# survives a layer 2 destroy and a soft-delete recovery, and the layer 2 identity never needs
# permission to assign roles.
resource "azurerm_role_assignment" "app_vault_secrets_user" {
  scope                = azurerm_resource_group.layers["keyvault"].id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.app.principal_id
}
