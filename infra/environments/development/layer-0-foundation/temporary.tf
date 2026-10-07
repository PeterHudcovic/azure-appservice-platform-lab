# TEMPORARY: Lab Admin builds development layers 1 and 2 locally before the pipelines take over.
# Remove each assignment (and apply) when its layer runs through its pipeline (dev-infra-l1, dev-infra-l2).
resource "azurerm_role_assignment" "temporary_admin_state_layer1" {
  scope                = azurerm_storage_container.tfstate["tfstate-layer1"].id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = data.azurerm_client_config.current.object_id
}

resource "azurerm_role_assignment" "temporary_admin_state_layer2" {
  scope                = azurerm_storage_container.tfstate["tfstate-layer2"].id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = data.azurerm_client_config.current.object_id
}
