locals {
  environment = "dev"
  region_code = "swc"

  tags = {
    environment = local.environment
    owner       = "peter"
    costCenter  = "sits-lab"
  }
}

resource "azurerm_resource_group" "foundation" {
  name     = "rg-sits-${local.environment}-foundation-${local.region_code}"
  location = var.location
  tags     = local.tags
}

resource "azurerm_storage_account" "tfstate" {
  name                     = "stsitstf${local.environment}${local.region_code}"
  resource_group_name      = azurerm_resource_group.foundation.name
  location                 = azurerm_resource_group.foundation.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"

  min_tls_version                 = "TLS1_2"
  https_traffic_only_enabled      = true
  shared_access_key_enabled       = false
  default_to_oauth_authentication = true
  allow_nested_items_to_be_public = false
  local_user_enabled              = false

  blob_properties {
    versioning_enabled = true

    delete_retention_policy {
      days = 7
    }

    container_delete_retention_policy {
      days = 7
    }
  }

  tags = local.tags

  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_storage_container" "tfstate" {
  for_each = toset(["tfstate-layer0", "tfstate-layer1", "tfstate-layer2"])

  name                  = each.key
  storage_account_id    = azurerm_storage_account.tfstate.id
  container_access_type = "private"
}

data "azurerm_client_config" "current" {}

resource "azurerm_role_assignment" "tfstate_layer0_admin" {
  scope                = azurerm_storage_container.tfstate["tfstate-layer0"].id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = data.azurerm_client_config.current.object_id
}