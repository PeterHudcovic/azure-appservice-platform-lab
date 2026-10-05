locals {
  environment = "dev"
  region_code = "swc"

  tags = {
    environment = local.environment
    owner       = "peter"
    costCenter  = "sits-lab"
  }
}

# Resources owned by layer 0, found by their fixed names (no terraform_remote_state)
data "azurerm_resource_group" "network" {
  name = "rg-sits-${local.environment}-network-${local.region_code}"
}

data "azurerm_public_ip" "nat" {
  name                = "pip-sits-${local.environment}-nat-${local.region_code}"
  resource_group_name = data.azurerm_resource_group.network.name
}

output "network_resource_group" {
  value = data.azurerm_resource_group.network.name
}

output "nat_public_ip_zone" {
  value = data.azurerm_public_ip.nat.zones
}
