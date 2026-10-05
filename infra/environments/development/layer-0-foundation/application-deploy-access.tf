# The dev-deploy pipeline identity deploys application packages to the Web App of layer 2.
# The role is granted on the application resource group (conscious deviation: the design grants it on the
# Web App only), so it survives a layer 2 destroy and the layer 2 identity never needs permission to assign roles.
resource "azurerm_role_assignment" "deploy_website_contributor" {
  scope                = azurerm_resource_group.layers["application"].id
  role_definition_name = "Website Contributor"
  principal_id         = azurerm_user_assigned_identity.pipeline["deploy"].principal_id
}
