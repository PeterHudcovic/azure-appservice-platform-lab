# TEMPORARY: Lab Admin builds testing layers 1 and 2 locally before the pipelines take over.
# Remove each assignment (and apply) when its layer runs through its pipeline (test-infra-l1, test-infra-l2).
resource "azurerm_role_assignment" "temporary_admin_state" {
  for_each = toset(["tfstate-layer1", "tfstate-layer2"])

  scope                = azurerm_storage_container.tfstate[each.key].id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = data.azurerm_client_config.current.object_id
}
