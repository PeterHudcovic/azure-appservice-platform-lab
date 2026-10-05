locals {
  environment = "dev"
  region_code = "swc"

  tags = {
    environment = local.environment
    owner       = "peter"
    costCenter  = "sits-lab"
  }

  foundation_resource_group = "rg-sits-${local.environment}-foundation-${local.region_code}"
  virtual_network_name      = "vnet-sits-${local.environment}-${local.region_code}"

  # Name the users open on the Ops VM; matches the WAF certificate and the Entra ID redirect address from layer 0
  app_host_name = "app.${local.environment}.sits.internal"
}

data "azurerm_client_config" "current" {}

# Resources owned by layer 0, found by their fixed names (no terraform_remote_state)
data "azurerm_resource_group" "layers" {
  for_each = {
    network     = "rg-sits-${local.environment}-network-${local.region_code}"
    application = "rg-sits-${local.environment}-app-${local.region_code}"
    keyvault    = "rg-sits-${local.environment}-kv-${local.region_code}"
  }

  name = each.value
}

data "azurerm_user_assigned_identity" "main" {
  for_each = {
    app = "id-sits-${local.environment}-app-${local.region_code}"
    agw = "id-sits-${local.environment}-agw-${local.region_code}"
  }

  name                = each.value
  resource_group_name = local.foundation_resource_group
}

data "azurerm_key_vault" "cert" {
  name                = "kv-sits-${local.environment}-cert-${local.region_code}"
  resource_group_name = local.foundation_resource_group
}

data "azurerm_log_analytics_workspace" "main" {
  name                = "log-sits-${local.environment}-${local.region_code}"
  resource_group_name = local.foundation_resource_group
}

data "azurerm_application_insights" "main" {
  name                = "appi-sits-${local.environment}-${local.region_code}"
  resource_group_name = local.foundation_resource_group
}

data "azuread_application" "app" {
  display_name = "app-sits-${local.environment}"
}

# Resources owned by layer 1, found by their fixed names
data "azurerm_subnet" "main" {
  for_each = toset(["snet-agw", "snet-pe", "snet-app"])

  name                 = each.key
  virtual_network_name = local.virtual_network_name
  resource_group_name  = data.azurerm_resource_group.layers["network"].name
}

data "azurerm_application_security_group" "main" {
  for_each = toset(["pe-webapp", "pe-kv-app"])

  name                = "asg-sits-${local.environment}-${each.key}-${local.region_code}"
  resource_group_name = data.azurerm_resource_group.layers["network"].name
}

data "azurerm_private_dns_zone" "main" {
  for_each = {
    keyvault = "privatelink.vaultcore.azure.net"
    webapp   = "privatelink.azurewebsites.net"
    internal = "${local.environment}.sits.internal"
  }

  name                = each.value
  resource_group_name = data.azurerm_resource_group.layers["network"].name
}
