# VNet flow logs with Traffic Analytics. Network Watcher is created by Azure (NetworkWatcherRG) and is not managed here.
data "azurerm_network_watcher" "main" {
  name                = "NetworkWatcher_${data.azurerm_resource_group.network.location}"
  resource_group_name = "NetworkWatcherRG"
}

# Flow log storage of this environment (layer 0)
data "azurerm_storage_account" "flowlogs" {
  name                = "stsitsflow${local.environment}${local.region_code}"
  resource_group_name = "rg-sits-${local.environment}-foundation-${local.region_code}"
}

# Development and testing share the non-production Log Analytics workspace (only production has its own)
data "azurerm_log_analytics_workspace" "main" {
  name                = "log-sits-dev-${local.region_code}"
  resource_group_name = "rg-sits-dev-foundation-${local.region_code}"
}

resource "azurerm_network_watcher_flow_log" "vnet" {
  name                 = "fl-sits-${local.environment}-vnet-${local.region_code}"
  network_watcher_name = data.azurerm_network_watcher.main.name
  resource_group_name  = data.azurerm_network_watcher.main.resource_group_name
  target_resource_id   = azurerm_virtual_network.main.id
  storage_account_id   = data.azurerm_storage_account.flowlogs.id
  enabled              = true
  version              = 2
  tags                 = local.tags

  retention_policy {
    enabled = true
    days    = 30
  }

  traffic_analytics {
    enabled               = true
    workspace_id          = data.azurerm_log_analytics_workspace.main.workspace_id
    workspace_region      = data.azurerm_log_analytics_workspace.main.location
    workspace_resource_id = data.azurerm_log_analytics_workspace.main.id
    interval_in_minutes   = 10
  }
}
