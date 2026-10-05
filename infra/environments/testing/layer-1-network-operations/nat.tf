# NAT Gateway: the only outbound path to the internet, using the permanent public IP address from layer 0
resource "azurerm_nat_gateway" "main" {
  name                    = "ng-sits-${local.environment}-${local.region_code}"
  resource_group_name     = data.azurerm_resource_group.network.name
  location                = data.azurerm_resource_group.network.location
  sku_name                = "Standard"
  zones                   = ["1"]
  idle_timeout_in_minutes = 4
  tags                    = local.tags
}

resource "azurerm_nat_gateway_public_ip_association" "main" {
  nat_gateway_id       = azurerm_nat_gateway.main.id
  public_ip_address_id = data.azurerm_public_ip.nat.id
}

# Subnets that need outbound access: Ops VM, agents, and the Web App VNet integration
resource "azurerm_subnet_nat_gateway_association" "main" {
  for_each = toset(["snet-ops", "snet-agents-infra", "snet-agents-app", "snet-app"])

  subnet_id      = azurerm_subnet.main[each.key].id
  nat_gateway_id = azurerm_nat_gateway.main.id
}
