# Azure Policy for the non-production subscription is assigned once in the development foundation layer.
# Testing only adds the exemption for its own certificate and admin vault (approved deviation, protected by Entra ID and RBAC).
#
# The exemption is scoped to the foundation resource group, not to each vault: the Deny policy blocks creating a vault
# with public access, so a resource-scoped exemption (which needs the vault to exist) cannot come first. The foundation
# resource group holds only these two vaults; the application vault lives in the Key Vault resource group without exemption.
locals {
  keyvault_policy_assignment_id = "/subscriptions/${var.subscription_id}/providers/Microsoft.Authorization/policyAssignments/sits-nonprod-keyvault-no-public-access"
}

resource "azurerm_resource_group_policy_exemption" "vault_public_access" {
  name                 = "exempt-keyvault-public-${local.environment}-foundation"
  resource_group_id    = azurerm_resource_group.foundation.id
  policy_assignment_id = local.keyvault_policy_assignment_id
  exemption_category   = "Waiver"
  description          = "Approved lab deviation: the certificate and admin vaults keep public access, protected by Microsoft Entra ID and RBAC."
}
