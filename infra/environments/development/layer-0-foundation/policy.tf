# Azure Policy on the non-production subscription (shared by Dev and Test)
data "azurerm_policy_definition_built_in" "policy" {
  for_each = {
    allowed_locations = "Allowed locations"
    require_tag       = "Require a tag on resources"
    webapp_https      = "App Service apps should only be accessible over HTTPS"
    webapp_tls        = "App Service apps should use the latest TLS version"
    keyvault_public   = "Azure Key Vault should disable public network access"
  }

  display_name = each.value
}

locals {
  subscription_resource_id = "/subscriptions/${var.subscription_id}"

  policy_assignments = {
    allowed-locations = {
      definition = "allowed_locations"
      enforce    = true
      parameters = { listOfAllowedLocations = { value = [var.location, "global"] } }
    }
    tag-environment = {
      definition = "require_tag"
      enforce    = false
      parameters = { tagName = { value = "environment" } }
    }
    tag-owner = {
      definition = "require_tag"
      enforce    = false
      parameters = { tagName = { value = "owner" } }
    }
    tag-costcenter = {
      definition = "require_tag"
      enforce    = false
      parameters = { tagName = { value = "costCenter" } }
    }
    webapp-https = {
      definition = "webapp_https"
      enforce    = true
      parameters = { effect = { value = "Audit" } }
    }
    webapp-tls = {
      definition = "webapp_tls"
      enforce    = true
      parameters = {}
    }
    keyvault-no-public-access = {
      definition = "keyvault_public"
      enforce    = true
      parameters = { effect = { value = "Deny" } }
    }
  }
}

resource "azurerm_subscription_policy_assignment" "nonprod" {
  for_each = local.policy_assignments

  name                 = "sits-nonprod-${each.key}"
  display_name         = "SITS non-production: ${each.key}"
  subscription_id      = local.subscription_resource_id
  policy_definition_id = data.azurerm_policy_definition_built_in.policy[each.value.definition].id
  enforce              = each.value.enforce
  parameters           = length(each.value.parameters) > 0 ? jsonencode(each.value.parameters) : null
}

# Exemptions: resource groups created automatically by Azure in other regions
data "azurerm_resource_group" "automatic" {
  for_each = {
    network_watcher = "NetworkWatcherRG"
    azure_devops    = var.azure_devops_billing_resource_group
  }

  name = each.value
}

resource "azurerm_resource_group_policy_exemption" "automatic_locations" {
  for_each = data.azurerm_resource_group.automatic

  name                 = "exempt-locations-${replace(each.key, "_", "-")}"
  resource_group_id    = each.value.id
  policy_assignment_id = azurerm_subscription_policy_assignment.nonprod["allowed-locations"].id
  exemption_category   = "Waiver"
  description          = "Created automatically by Azure outside the allowed region."
}

# Exemptions: certificate and admin vault keep public access (approved deviation, protected by Entra ID and RBAC)
resource "azurerm_resource_policy_exemption" "vault_public_access" {
  for_each = azurerm_key_vault.foundation

  name                 = "exempt-keyvault-public-${each.key}"
  resource_id          = each.value.id
  policy_assignment_id = azurerm_subscription_policy_assignment.nonprod["keyvault-no-public-access"].id
  exemption_category   = "Waiver"
  description          = "Approved lab deviation: public access protected by Microsoft Entra ID and RBAC."
}