# TEMPORARY: Lab Admin builds development layer 1 locally before the pipeline takes over.
# Remove this file (and apply) when layer 1 runs through the dev-infra-l1 pipeline.
resource "azurerm_role_assignment" "temporary_admin_state_layer1" {
  scope                = azurerm_storage_container.tfstate["tfstate-layer1"].id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = data.azurerm_client_config.current.object_id
}