locals {
  environment = "prod"
  region_code = "swc"

  tags = {
    environment = local.environment
    owner       = "peter"
    costCenter  = "sits-lab"
  }

  address_space = ["10.30.0.0/16"]

  # Production has its own AzureBastionSubnet for Bastion Basic
  subnets = {
    AzureBastionSubnet = {
      prefix     = "10.30.0.0/26"
      delegation = null
    }
    snet-ops = {
      prefix     = "10.30.1.0/24"
      delegation = null
    }
    snet-agents-infra = {
      prefix     = "10.30.2.0/24"
      delegation = { name = "Microsoft.DevOpsInfrastructure/pools", actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"] }
    }
    snet-agents-app = {
      prefix     = "10.30.3.0/24"
      delegation = { name = "Microsoft.DevOpsInfrastructure/pools", actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"] }
    }
    snet-agw = {
      prefix     = "10.30.4.0/24"
      delegation = { name = "Microsoft.Network/applicationGateways", actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"] }
    }
    snet-pe = {
      prefix     = "10.30.5.0/24"
      delegation = null
    }
    snet-app = {
      prefix     = "10.30.6.0/24"
      delegation = { name = "Microsoft.Web/serverFarms", actions = ["Microsoft.Network/virtualNetworks/subnets/action"] }
    }
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

resource "azurerm_virtual_network" "main" {
  name                = "vnet-sits-${local.environment}-${local.region_code}"
  resource_group_name = data.azurerm_resource_group.network.name
  location            = data.azurerm_resource_group.network.location
  address_space       = local.address_space
  tags                = local.tags
}

resource "azurerm_subnet" "main" {
  for_each = local.subnets

  name                              = each.key
  resource_group_name               = data.azurerm_resource_group.network.name
  virtual_network_name              = azurerm_virtual_network.main.name
  address_prefixes                  = [each.value.prefix]
  default_outbound_access_enabled   = false
  private_endpoint_network_policies = each.key == "snet-pe" ? "Enabled" : "Disabled"

  dynamic "delegation" {
    for_each = each.value.delegation == null ? [] : [each.value.delegation]

    content {
      name = "delegation"

      service_delegation {
        name    = delegation.value.name
        actions = delegation.value.actions
      }
    }
  }
}

output "network_resource_group" {
  value = data.azurerm_resource_group.network.name
}

output "nat_public_ip_zone" {
  value = data.azurerm_public_ip.nat.zones
}

output "subnet_prefixes" {
  value = { for name, subnet in azurerm_subnet.main : name => subnet.address_prefixes[0] }
}
