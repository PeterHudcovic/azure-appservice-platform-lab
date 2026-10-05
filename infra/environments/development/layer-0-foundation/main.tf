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

# Pipeline identities (federated with Azure DevOps service connections, no secrets)
resource "azurerm_user_assigned_identity" "pipeline" {
  for_each = toset(["infra-l1", "infra-l2", "deploy", "destroy"])

  name                = "id-sits-${local.environment}-${each.key}-${local.region_code}"
  resource_group_name = azurerm_resource_group.foundation.name
  location            = azurerm_resource_group.foundation.location
  tags                = local.tags
}

resource "azurerm_user_assigned_identity" "build" {
  name                = "id-sits-build-${local.region_code}"
  resource_group_name = azurerm_resource_group.foundation.name
  location            = azurerm_resource_group.foundation.location
  tags                = local.tags
}

locals {
  pipeline_data_roles = {
    infra_l1_state = {
      principal_id = azurerm_user_assigned_identity.pipeline["infra-l1"].principal_id
      role         = "Storage Blob Data Contributor"
      scope        = azurerm_storage_container.tfstate["tfstate-layer1"].id
    }
    infra_l2_state = {
      principal_id = azurerm_user_assigned_identity.pipeline["infra-l2"].principal_id
      role         = "Storage Blob Data Contributor"
      scope        = azurerm_storage_container.tfstate["tfstate-layer2"].id
    }
    destroy_state_l1 = {
      principal_id = azurerm_user_assigned_identity.pipeline["destroy"].principal_id
      role         = "Storage Blob Data Contributor"
      scope        = azurerm_storage_container.tfstate["tfstate-layer1"].id
    }
    destroy_state_l2 = {
      principal_id = azurerm_user_assigned_identity.pipeline["destroy"].principal_id
      role         = "Storage Blob Data Contributor"
      scope        = azurerm_storage_container.tfstate["tfstate-layer2"].id
    }
    build_packages = {
      principal_id = azurerm_user_assigned_identity.build.principal_id
      role         = "Storage Blob Data Contributor"
      scope        = azurerm_storage_container.packages.id
    }
    deploy_packages = {
      principal_id = azurerm_user_assigned_identity.pipeline["deploy"].principal_id
      role         = "Storage Blob Data Reader"
      scope        = azurerm_storage_container.packages.id
    }
  }
}

resource "azurerm_role_assignment" "pipeline_data" {
  for_each = local.pipeline_data_roles

  principal_id         = each.value.principal_id
  role_definition_name = each.value.role
  scope                = each.value.scope
}

# Trust between each Azure DevOps service connection and its pipeline identity (no secrets)
locals {
  pipeline_identity_ids = merge(
    { for key, identity in azurerm_user_assigned_identity.pipeline : key => identity.id },
    { build = azurerm_user_assigned_identity.build.id }
  )
}

resource "azurerm_federated_identity_credential" "pipeline" {
  for_each = var.pipeline_federation_subjects

  name                      = each.key == "build" ? "azure-devops-build" : "azure-devops-${local.environment}-${each.key}"
  user_assigned_identity_id = local.pipeline_identity_ids[each.key]
  audience                  = ["api://AzureADTokenExchange"]
  issuer                    = "https://login.microsoftonline.com/${data.azurerm_client_config.current.tenant_id}/v2.0"
  subject                   = each.value
}

moved {
  from = azurerm_federated_identity_credential.dev_infra_l1
  to   = azurerm_federated_identity_credential.pipeline["infra-l1"]
}

resource "azurerm_role_assignment" "infra_l1_network_contributor" {
  scope                = azurerm_resource_group.layers["network"].id
  role_definition_name = "Contributor"
  principal_id         = azurerm_user_assigned_identity.pipeline["infra-l1"].principal_id
}

# Management roles of the pipeline identities on the resource groups of their layers
locals {
  pipeline_management_roles = {
    infra_l2_app    = { identity = "infra-l2", resource_group = "application" }
    infra_l2_kv     = { identity = "infra-l2", resource_group = "keyvault" }
    destroy_network = { identity = "destroy", resource_group = "network" }
    destroy_app     = { identity = "destroy", resource_group = "application" }
    destroy_kv      = { identity = "destroy", resource_group = "keyvault" }
  }
}

resource "azurerm_role_assignment" "pipeline_management" {
  for_each = local.pipeline_management_roles

  scope                = azurerm_resource_group.layers[each.value.resource_group].id
  role_definition_name = "Contributor"
  principal_id         = azurerm_user_assigned_identity.pipeline[each.value.identity].principal_id
}

# Entra ID app registration for user sign-in to the application (no client secret: trusts the application managed identity)
resource "azuread_application" "app" {
  display_name     = "app-sits-${local.environment}"
  sign_in_audience = "AzureADMyOrg"

  web {
    redirect_uris = ["https://app.${local.environment}.sits.internal/.auth/login/aad/callback"]

    implicit_grant {
      id_token_issuance_enabled = true
    }
  }

  required_resource_access {
    resource_app_id = "00000003-0000-0000-c000-000000000000"

    resource_access {
      id   = "e1fe6dd8-ba31-4d61-89e7-88639da4683d"
      type = "Scope"
    }
  }
}

resource "azuread_application_federated_identity_credential" "app" {
  application_id = azuread_application.app.id
  display_name   = "app-managed-identity"
  audiences      = ["api://AzureADTokenExchange"]
  issuer         = "https://login.microsoftonline.com/${data.azurerm_client_config.current.tenant_id}/v2.0"
  subject        = azurerm_user_assigned_identity.app.principal_id
}

resource "azuread_service_principal" "app" {
  client_id                    = azuread_application.app.client_id
  app_role_assignment_required = true
}

resource "azuread_group" "app_users" {
  display_name     = "grp-sits-${local.environment}-app-users"
  security_enabled = true
}

resource "azuread_app_role_assignment" "app_users" {
  app_role_id         = "00000000-0000-0000-0000-000000000000"
  principal_object_id = azuread_group.app_users.object_id
  resource_object_id  = azuread_service_principal.app.object_id
}