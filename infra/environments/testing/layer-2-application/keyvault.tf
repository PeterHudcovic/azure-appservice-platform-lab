# Application vault: fully private, RBAC mode, no trusted services bypass, no policy exemption.
# The name is fixed: a layer 2 destroy leaves the vault in soft-delete and the next apply recovers it with its secrets.
# Secrets are not Terraform resources; a separate private agent step adds missing values later.
# The application identity reads secrets through Key Vault Secrets User granted in layer 0 on this resource group.
resource "azurerm_key_vault" "app" {
  name                          = "kv-sits-${local.environment}-app-${local.region_code}"
  resource_group_name           = data.azurerm_resource_group.layers["keyvault"].name
  location                      = data.azurerm_resource_group.layers["keyvault"].location
  tenant_id                     = data.azurerm_client_config.current.tenant_id
  sku_name                      = "standard"
  rbac_authorization_enabled    = true
  soft_delete_retention_days    = 7
  purge_protection_enabled      = false
  public_network_access_enabled = false

  network_acls {
    default_action = "Deny"
    bypass         = "None"
  }

  tags = local.tags
}

# Private endpoint next to the vault, in snet-pe, with its record in the vault private DNS zone of layer 1
resource "azurerm_private_endpoint" "vault" {
  name                          = "pe-${azurerm_key_vault.app.name}"
  resource_group_name           = data.azurerm_resource_group.layers["keyvault"].name
  location                      = data.azurerm_resource_group.layers["keyvault"].location
  subnet_id                     = data.azurerm_subnet.main["snet-pe"].id
  custom_network_interface_name = "nic-pe-${azurerm_key_vault.app.name}"
  tags                          = local.tags

  private_service_connection {
    name                           = "psc-${azurerm_key_vault.app.name}"
    private_connection_resource_id = azurerm_key_vault.app.id
    subresource_names              = ["vault"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [data.azurerm_private_dns_zone.main["keyvault"].id]
  }
}

# The endpoint joins the pe-kv-app group: the snet-pe rules allow only snet-app and snet-agents-infra
resource "azurerm_private_endpoint_application_security_group_association" "vault" {
  private_endpoint_id           = azurerm_private_endpoint.vault.id
  application_security_group_id = data.azurerm_application_security_group.main["pe-kv-app"].id
}
