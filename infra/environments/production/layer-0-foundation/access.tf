# Production administrator account (MFA): permanent read access, privileged roles only through PIM
# (Privileged Identity Management, Entra ID P2): activation for at most 2 hours, with justification and MFA.
data "azuread_user" "prod_admin" {
  user_principal_name = var.prod_admin_user_principal_name
}

locals {
  subscription_scope = "/subscriptions/${var.subscription_id}"

  prod_admin_permanent_roles = {
    reader   = { role = "Reader", scope = local.subscription_scope }
    vm_login = { role = "Virtual Machine User Login", scope = azurerm_resource_group.layers["network"].id }
  }

  prod_admin_eligible_roles = {
    contributor = { role = "Contributor", scope = local.subscription_scope }
    admin_vault = { role = "Key Vault Secrets User", scope = azurerm_key_vault.foundation["admin"].id }
    app_vault   = { role = "Key Vault Secrets Officer", scope = azurerm_resource_group.layers["keyvault"].id }
  }
}

resource "azurerm_role_assignment" "prod_admin" {
  for_each = local.prod_admin_permanent_roles

  scope                = each.value.scope
  role_definition_name = each.value.role
  principal_id         = data.azuread_user.prod_admin.object_id
}

data "azurerm_role_definition" "eligible" {
  for_each = local.prod_admin_eligible_roles

  name  = each.value.role
  scope = each.value.scope
}

# Activation rules of the eligible roles at their scopes
resource "azurerm_role_management_policy" "eligible" {
  for_each = local.prod_admin_eligible_roles

  scope              = each.value.scope
  role_definition_id = data.azurerm_role_definition.eligible[each.key].id

  activation_rules {
    maximum_duration                   = "PT2H"
    require_justification              = true
    require_multifactor_authentication = true
  }

  eligible_assignment_rules {
    expiration_required = false
  }
}

resource "azurerm_pim_eligible_role_assignment" "prod_admin" {
  for_each = local.prod_admin_eligible_roles

  scope              = each.value.scope
  role_definition_id = data.azurerm_role_definition.eligible[each.key].id
  principal_id       = data.azuread_user.prod_admin.object_id
  justification      = "SITS lab: temporary production administration through PIM"

  depends_on = [azurerm_role_management_policy.eligible]
}

# Contributor cannot create or delete locks. Custom roles: Lock Creator only for layer 2, Lock Remover only for prod-destroy.
resource "azurerm_role_definition" "locks" {
  for_each = {
    creator = { name = "SITS Lock Creator", actions = ["Microsoft.Authorization/locks/read", "Microsoft.Authorization/locks/write"] }
    remover = { name = "SITS Lock Remover", actions = ["Microsoft.Authorization/locks/read", "Microsoft.Authorization/locks/delete"] }
  }

  name              = each.value.name
  scope             = local.subscription_scope
  description       = "SITS lab: ${each.key == "creator" ? "create" : "remove"} management locks in production."
  assignable_scopes = [local.subscription_scope]

  permissions {
    actions = each.value.actions
  }
}

locals {
  lock_role_assignments = {
    creator_app = { role = "creator", identity = "infra-l2", resource_group = "application" }
    creator_kv  = { role = "creator", identity = "infra-l2", resource_group = "keyvault" }
    remover_app = { role = "remover", identity = "destroy", resource_group = "application" }
    remover_kv  = { role = "remover", identity = "destroy", resource_group = "keyvault" }
  }
}

resource "azurerm_role_assignment" "locks" {
  for_each = local.lock_role_assignments

  scope              = azurerm_resource_group.layers[each.value.resource_group].id
  role_definition_id = azurerm_role_definition.locks[each.value.role].role_definition_resource_id
  principal_id       = azurerm_user_assigned_identity.pipeline[each.value.identity].principal_id
}
