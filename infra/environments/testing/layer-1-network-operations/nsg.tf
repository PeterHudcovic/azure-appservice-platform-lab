# Application security groups: the Ops VM and one group per private endpoint target (implementation decision 3)
resource "azurerm_application_security_group" "main" {
  for_each = toset(["ops-vm", "pe-webapp", "pe-kv-app", "pe-kv-cert", "pe-kv-admin"])

  name                = "asg-sits-${local.environment}-${each.key}-${local.region_code}"
  resource_group_name = data.azurerm_resource_group.network.name
  location            = data.azurerm_resource_group.network.location
  tags                = local.tags
}

# One network security group per subnet
resource "azurerm_network_security_group" "main" {
  for_each = local.subnets

  name                = "nsg-sits-${local.environment}-${trimprefix(each.key, "snet-")}-${local.region_code}"
  resource_group_name = data.azurerm_resource_group.network.name
  location            = data.azurerm_resource_group.network.location
  tags                = local.tags
}

resource "azurerm_subnet_network_security_group_association" "main" {
  for_each = local.subnets

  subnet_id                 = azurerm_subnet.main[each.key].id
  network_security_group_id = azurerm_network_security_group.main[each.key].id
}

locals {
  deny_all_inbound = { name = "deny-all-inbound", priority = 4000, direction = "Inbound", access = "Deny", protocol = "*", port = "*" }

  # Only the listed connections are allowed; every NSG ends with an explicit deny before AllowVnetInBound
  nsg_rules = {
    snet-ops = [
      { name = "allow-rdp-from-bastion-developer", priority = 100, direction = "Inbound", access = "Allow", protocol = "Tcp", port = "3389", source_prefix = "168.63.129.16", destination_asg = "ops-vm" },
      { name = "deny-ops-vm-to-azure-resource-manager", priority = 100, direction = "Outbound", access = "Deny", protocol = "*", port = "*", source_asg = "ops-vm", destination_prefix = "AzureResourceManager" },
      local.deny_all_inbound,
    ]
    snet-agents-infra = [local.deny_all_inbound]
    snet-agents-app   = [local.deny_all_inbound]
    snet-agw = [
      { name = "allow-https-from-ops-vm", priority = 100, direction = "Inbound", access = "Allow", protocol = "Tcp", port = "443", source_asg = "ops-vm", destination_prefix = local.subnets["snet-agw"].prefix },
      { name = "allow-gateway-manager", priority = 110, direction = "Inbound", access = "Allow", protocol = "Tcp", port = "65200-65535", source_prefix = "GatewayManager" },
      { name = "allow-azure-load-balancer", priority = 120, direction = "Inbound", access = "Allow", protocol = "*", port = "*", source_prefix = "AzureLoadBalancer" },
      local.deny_all_inbound,
    ]
    snet-pe = [
      { name = "allow-webapp-from-agw", priority = 100, direction = "Inbound", access = "Allow", protocol = "Tcp", port = "443", source_prefix = local.subnets["snet-agw"].prefix, destination_asg = "pe-webapp" },
      { name = "allow-webapp-from-agents-app", priority = 110, direction = "Inbound", access = "Allow", protocol = "Tcp", port = "443", source_prefix = local.subnets["snet-agents-app"].prefix, destination_asg = "pe-webapp" },
      { name = "allow-kv-app-from-app", priority = 120, direction = "Inbound", access = "Allow", protocol = "Tcp", port = "443", source_prefix = local.subnets["snet-app"].prefix, destination_asg = "pe-kv-app" },
      { name = "allow-kv-app-from-agents-infra", priority = 130, direction = "Inbound", access = "Allow", protocol = "Tcp", port = "443", source_prefix = local.subnets["snet-agents-infra"].prefix, destination_asg = "pe-kv-app" },
      { name = "allow-kv-cert-from-agw", priority = 140, direction = "Inbound", access = "Allow", protocol = "Tcp", port = "443", source_prefix = local.subnets["snet-agw"].prefix, destination_asg = "pe-kv-cert" },
      { name = "allow-kv-cert-from-agents-infra", priority = 150, direction = "Inbound", access = "Allow", protocol = "Tcp", port = "443", source_prefix = local.subnets["snet-agents-infra"].prefix, destination_asg = "pe-kv-cert" },
      { name = "allow-kv-admin-from-agents-infra", priority = 160, direction = "Inbound", access = "Allow", protocol = "Tcp", port = "443", source_prefix = local.subnets["snet-agents-infra"].prefix, destination_asg = "pe-kv-admin" },
      local.deny_all_inbound,
    ]
    snet-app = [local.deny_all_inbound]
  }

  nsg_rule_list = flatten([
    for nsg, rules in local.nsg_rules : [
      for rule in rules : {
        key                = "${nsg}.${rule.name}"
        nsg                = nsg
        name               = rule.name
        priority           = rule.priority
        direction          = rule.direction
        access             = rule.access
        protocol           = rule.protocol
        port               = rule.port
        source_prefix      = lookup(rule, "source_prefix", null)
        source_asg         = lookup(rule, "source_asg", null)
        destination_prefix = lookup(rule, "destination_prefix", null)
        destination_asg    = lookup(rule, "destination_asg", null)
      }
    ]
  ])
}

resource "azurerm_network_security_rule" "main" {
  for_each = { for rule in local.nsg_rule_list : rule.key => rule }

  name                        = each.value.name
  resource_group_name         = data.azurerm_resource_group.network.name
  network_security_group_name = azurerm_network_security_group.main[each.value.nsg].name
  priority                    = each.value.priority
  direction                   = each.value.direction
  access                      = each.value.access
  protocol                    = each.value.protocol
  source_port_range           = "*"
  destination_port_range      = each.value.port

  source_address_prefix                 = each.value.source_asg == null ? coalesce(each.value.source_prefix, "*") : null
  source_application_security_group_ids = each.value.source_asg == null ? null : [azurerm_application_security_group.main[each.value.source_asg].id]

  destination_address_prefix                 = each.value.destination_asg == null ? coalesce(each.value.destination_prefix, "*") : null
  destination_application_security_group_ids = each.value.destination_asg == null ? null : [azurerm_application_security_group.main[each.value.destination_asg].id]
}
