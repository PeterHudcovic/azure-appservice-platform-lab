# Roles for layer 2, granted here on the resource groups (conscious deviation from design decisions 7 and 8,
# same as development): they survive a layer 2 destroy and a soft-delete recovery, and the layer 2 identity
# never needs permission to assign roles.

# The application identity reads secrets from the application vault (the only vault in this resource group)
resource "azurerm_role_assignment" "app_vault_secrets_user" {
  scope                = azurerm_resource_group.layers["keyvault"].id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.app.principal_id
}

# The test-deploy pipeline identity deploys the verified package to the Web App
resource "azurerm_role_assignment" "deploy_website_contributor" {
  scope                = azurerm_resource_group.layers["application"].id
  role_definition_name = "Website Contributor"
  principal_id         = azurerm_user_assigned_identity.pipeline["deploy"].principal_id
}
