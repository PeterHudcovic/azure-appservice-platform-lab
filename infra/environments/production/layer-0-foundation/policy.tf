# Azure Policy on the production subscription: tags, region, HTTPS and TLS for web apps, and no public Key Vault access
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

resource "azurerm_subscription_policy_assignment" "prod" {
  for_each = local.policy_assignments

  name                 = "sits-prod-${each.key}"
  display_name         = "SITS production: ${each.key}"
  subscription_id      = local.subscription_resource_id
  policy_definition_id = data.azurerm_policy_definition_built_in.policy[each.value.definition].id
  enforce              = each.value.enforce
  parameters           = length(each.value.parameters) > 0 ? jsonencode(each.value.parameters) : null

  # The certificate and admin vaults exist before the Deny assignment, so their exemptions can be resource-scoped
  depends_on = [azurerm_key_vault.foundation]
}

# Exemptions: certificate and admin vault keep public access (conscious deviation, protected by Entra ID and RBAC;
# the design limits it to the administrator address)
resource "azurerm_resource_policy_exemption" "vault_public_access" {
  for_each = azurerm_key_vault.foundation

  name                 = "exempt-keyvault-public-${each.key}"
  resource_id          = each.value.id
  policy_assignment_id = azurerm_subscription_policy_assignment.prod["keyvault-no-public-access"].id
  exemption_category   = "Waiver"
  description          = "Approved lab deviation: public access protected by Microsoft Entra ID and RBAC."
}
