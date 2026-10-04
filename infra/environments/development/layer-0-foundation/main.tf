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

resource "azurerm_resource_group" "layers" {
  for_each = {
    network     = "rg-sits-${local.environment}-network-${local.region_code}"
    application = "rg-sits-${local.environment}-app-${local.region_code}"
    keyvault    = "rg-sits-${local.environment}-kv-${local.region_code}"
  }

  name     = each.value
  location = var.location
  tags     = local.tags
}

resource "azurerm_user_assigned_identity" "app" {
  name                = "id-sits-${local.environment}-app-${local.region_code}"
  resource_group_name = azurerm_resource_group.foundation.name
  location            = azurerm_resource_group.foundation.location
  tags                = local.tags
}

resource "azurerm_user_assigned_identity" "agw" {
  name                = "id-sits-${local.environment}-agw-${local.region_code}"
  resource_group_name = azurerm_resource_group.foundation.name
  location            = azurerm_resource_group.foundation.location
  tags                = local.tags
}

resource "azurerm_log_analytics_workspace" "main" {
  name                = "log-sits-${local.environment}-${local.region_code}"
  resource_group_name = azurerm_resource_group.foundation.name
  location            = azurerm_resource_group.foundation.location
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags                = local.tags
}

resource "azurerm_application_insights" "main" {
  name                = "appi-sits-${local.environment}-${local.region_code}"
  resource_group_name = azurerm_resource_group.foundation.name
  location            = azurerm_resource_group.foundation.location
  workspace_id        = azurerm_log_analytics_workspace.main.id
  application_type    = "web"
  tags                = local.tags
}

# Shared package storage for all environments (lab simplification: lives in the non-production subscription)
resource "azurerm_storage_account" "packages" {
  name                     = "stsitspkg${local.region_code}"
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

resource "azurerm_storage_container" "packages" {
  name                  = "packages"
  storage_account_id    = azurerm_storage_account.packages.id
  container_access_type = "private"
}

resource "azurerm_storage_container_immutability_policy" "packages" {
  storage_container_resource_manager_id = azurerm_storage_container.packages.id
  immutability_period_in_days           = 7
  protected_append_writes_enabled       = false
  locked                                = false
}

# Permanent outbound address for the layer 1 NAT Gateway, also used by Conditional Access
resource "azurerm_public_ip" "nat" {
  name                = "pip-sits-${local.environment}-nat-${local.region_code}"
  resource_group_name = azurerm_resource_group.layers["network"].name
  location            = azurerm_resource_group.layers["network"].location
  sku                 = "Standard"
  allocation_method   = "Static"
  zones               = ["1"]
  tags                = local.tags

  lifecycle {
    prevent_destroy = true
  }
}

# Certificate vault and admin vault (approved deviation: public access from any address, protected by Entra ID and RBAC)
resource "azurerm_key_vault" "foundation" {
  for_each = {
    cert  = "kv-sits-${local.environment}-cert-${local.region_code}"
    admin = "kv-sits-${local.environment}-adm-${local.region_code}"
  }

  name                          = each.value
  resource_group_name           = azurerm_resource_group.foundation.name
  location                      = azurerm_resource_group.foundation.location
  tenant_id                     = data.azurerm_client_config.current.tenant_id
  sku_name                      = "standard"
  rbac_authorization_enabled    = true
  soft_delete_retention_days    = 7
  purge_protection_enabled      = false
  public_network_access_enabled = true

  network_acls {
    default_action = "Allow"
    bypass         = "None"
  }

  tags = local.tags

  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_role_assignment" "agw_cert_vault" {
  scope                = azurerm_key_vault.foundation["cert"].id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.agw.principal_id
}

resource "azurerm_role_assignment" "admin_cert_vault" {
  scope                = azurerm_key_vault.foundation["cert"].id
  role_definition_name = "Key Vault Certificates Officer"
  principal_id         = data.azurerm_client_config.current.object_id
}

# Self-signed WAF certificate (lab limitation: a company would use its own certificate authority)
resource "azurerm_key_vault_certificate" "waf" {
  name         = "cert-app-${local.environment}"
  key_vault_id = azurerm_key_vault.foundation["cert"].id

  certificate_policy {
    issuer_parameters {
      name = "Self"
    }

    key_properties {
      exportable = true
      key_type   = "RSA"
      key_size   = 2048
      reuse_key  = false
    }

    lifetime_action {
      action {
        action_type = "EmailContacts"
      }

      trigger {
        days_before_expiry = 30
      }
    }

    secret_properties {
      content_type = "application/x-pkcs12"
    }

    x509_certificate_properties {
      subject            = "CN=app.${local.environment}.sits.internal"
      validity_in_months = 12
      key_usage          = ["digitalSignature", "keyEncipherment"]
      extended_key_usage = ["1.3.6.1.5.5.7.3.1"]

      subject_alternative_names {
        dns_names = ["app.${local.environment}.sits.internal"]
      }
    }
  }

  depends_on = [azurerm_role_assignment.admin_cert_vault]
}