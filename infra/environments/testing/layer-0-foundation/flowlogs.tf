# Storage for testing VNet flow logs. It lives in the permanent layer so the records survive a layer 1 destroy.
# Shared key access stays enabled: azurerm 5.7 cannot attach a managed identity to a flow log,
# so Network Watcher writes with the storage account key. The account holds network logs only.
# Retention is set on the flow log in layer 1 (the flow log manages the lifecycle rule of this account).
resource "azurerm_storage_account" "flowlogs" {
  name                     = "stsitsflow${local.environment}${local.region_code}"
  resource_group_name      = azurerm_resource_group.foundation.name
  location                 = azurerm_resource_group.foundation.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"

  min_tls_version                 = "TLS1_2"
  https_traffic_only_enabled      = true
  shared_access_key_enabled       = true
  allow_nested_items_to_be_public = false
  local_user_enabled              = false

  tags = local.tags

  lifecycle {
    prevent_destroy = true
  }
}
