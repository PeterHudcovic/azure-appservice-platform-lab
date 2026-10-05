# Private endpoints to the permanent vaults of layer 0 (found by their fixed names)
data "azurerm_key_vault" "foundation" {
  for_each = {
    cert  = "kv-sits-${local.environment}-cert-${local.region_code}"
    admin = "kv-sits-${local.environment}-adm-${local.region_code}"
  }

  name                = each.value
  resource_group_name = "rg-sits-${local.environment}-foundation-${local.region_code}"
}

resource "azurerm_private_endpoint" "vault" {
  for_each = data.azurerm_key_vault.foundation

  name                          = "pe-${each.value.name}"
  resource_group_name           = data.azurerm_resource_group.network.name
  location                      = data.azurerm_resource_group.network.location
  subnet_id                     = azurerm_subnet.main["snet-pe"].id
  custom_network_interface_name = "nic-pe-${each.value.name}"
  tags                          = local.tags

  private_service_connection {
    name                           = "psc-${each.value.name}"
    private_connection_resource_id = each.value.id
    subresource_names              = ["vault"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [azurerm_private_dns_zone.main["keyvault"].id]
  }
}

# Each endpoint joins its own application security group, so the snet-pe rules apply per target
resource "azurerm_private_endpoint_application_security_group_association" "vault" {
  for_each = azurerm_private_endpoint.vault

  private_endpoint_id           = each.value.id
  application_security_group_id = azurerm_application_security_group.main[each.key == "cert" ? "pe-kv-cert" : "pe-kv-admin"].id
}
