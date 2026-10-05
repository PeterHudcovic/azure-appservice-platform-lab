# Private DNS zones of this environment, linked only to its own virtual network
resource "azurerm_private_dns_zone" "main" {
  for_each = {
    keyvault = "privatelink.vaultcore.azure.net"
    webapp   = "privatelink.azurewebsites.net"
    internal = "${local.environment}.sits.internal"
  }

  name                = each.value
  resource_group_name = data.azurerm_resource_group.network.name
  tags                = local.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "main" {
  for_each = azurerm_private_dns_zone.main

  name                 = "link-${each.key}-${azurerm_virtual_network.main.name}"
  private_dns_zone_id  = each.value.id
  virtual_network_id   = azurerm_virtual_network.main.id
  registration_enabled = false
  tags                 = local.tags
}
