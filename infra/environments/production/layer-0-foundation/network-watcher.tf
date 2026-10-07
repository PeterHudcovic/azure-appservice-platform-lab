# Network Watcher for the production subscription, created here in the allowed region before the first virtual network.
# In the non-production subscription Azure created it automatically (NetworkWatcherRG outside the allowed region, exempted);
# in production it is managed explicitly, so it complies with the region policy and survives a layer 1 destroy.
resource "azurerm_resource_group" "network_watcher" {
  name     = "NetworkWatcherRG"
  location = var.location
  tags     = local.tags
}

resource "azurerm_network_watcher" "main" {
  name                = "NetworkWatcher_${var.location}"
  resource_group_name = azurerm_resource_group.network_watcher.name
  location            = azurerm_resource_group.network_watcher.location
  tags                = local.tags

  lifecycle {
    prevent_destroy = true
  }
}
