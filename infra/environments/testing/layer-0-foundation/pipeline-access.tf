# Roles the infrastructure pipeline identities need outside the resource groups of their own layers,
# so layers 1 and 2 can be planned, applied, rebuilt, and removed from Azure DevOps without Lab Admin.
# Every role is scoped to one resource group or one resource; no identity can assign roles.

# Testing shares the non-production monitoring of development (found by fixed names)
data "azurerm_log_analytics_workspace" "shared" {
  name                = "log-sits-dev-${local.region_code}"
  resource_group_name = "rg-sits-dev-foundation-${local.region_code}"
}

data "azurerm_application_insights" "shared" {
  name                = "appi-sits-dev-${local.region_code}"
  resource_group_name = "rg-sits-dev-foundation-${local.region_code}"
}

locals {
  network_watcher_resource_group_id = "/subscriptions/${var.subscription_id}/resourceGroups/NetworkWatcherRG"

  pipeline_resource_roles = {
    # Layers 1 and 2 find layer 0 resources (identities, vaults, flow log storage) by their fixed names
    infra_l1_foundation = { identity = "infra-l1", role = "Reader", scope = azurerm_resource_group.foundation.id }
    infra_l2_foundation = { identity = "infra-l2", role = "Reader", scope = azurerm_resource_group.foundation.id }
    destroy_foundation  = { identity = "destroy", role = "Reader", scope = azurerm_resource_group.foundation.id }

    # Layer 1: the VNet flow log is a child of the regional Network Watcher in NetworkWatcherRG
    infra_l1_network_watcher = { identity = "infra-l1", role = "Network Contributor", scope = local.network_watcher_resource_group_id }
    destroy_network_watcher  = { identity = "destroy", role = "Network Contributor", scope = local.network_watcher_resource_group_id }

    # Layer 1: the flow log writes with the storage account key and links Traffic Analytics to the shared workspace
    infra_l1_flowlog_storage = { identity = "infra-l1", role = "Storage Account Contributor", scope = azurerm_storage_account.flowlogs.id }
    infra_l1_workspace       = { identity = "infra-l1", role = "Log Analytics Contributor", scope = data.azurerm_log_analytics_workspace.shared.id }

    # Layer 1: private endpoints to the certificate and admin vaults are approved automatically
    infra_l1_cert_vault  = { identity = "infra-l1", role = "Key Vault Contributor", scope = azurerm_key_vault.foundation["cert"].id }
    infra_l1_admin_vault = { identity = "infra-l1", role = "Key Vault Contributor", scope = azurerm_key_vault.foundation["admin"].id }

    # Layer 2: private endpoints, VNet integration, and the gateway join layer 1 subnets and application
    # security groups, and the gateway address is published in the internal DNS zone
    infra_l2_network = { identity = "infra-l2", role = "Network Contributor", scope = azurerm_resource_group.layers["network"].id }

    # Layer 2: the Web App and the gateway run with the permanent identities of layer 0
    infra_l2_app_identity = { identity = "infra-l2", role = "Managed Identity Operator", scope = azurerm_user_assigned_identity.app.id }
    infra_l2_agw_identity = { identity = "infra-l2", role = "Managed Identity Operator", scope = azurerm_user_assigned_identity.agw.id }

    # Layer 2: diagnostic settings and log alerts target the shared workspace; the Web App reads the
    # shared Application Insights connection string
    infra_l2_workspace            = { identity = "infra-l2", role = "Log Analytics Contributor", scope = data.azurerm_log_analytics_workspace.shared.id }
    infra_l2_application_insights = { identity = "infra-l2", role = "Reader", scope = data.azurerm_application_insights.shared.id }
    destroy_workspace             = { identity = "destroy", role = "Reader", scope = data.azurerm_log_analytics_workspace.shared.id }
    destroy_application_insights  = { identity = "destroy", role = "Reader", scope = data.azurerm_application_insights.shared.id }
  }
}

resource "azurerm_role_assignment" "pipeline_resource" {
  for_each = local.pipeline_resource_roles

  scope                = each.value.scope
  role_definition_name = each.value.role
  principal_id         = azurerm_user_assigned_identity.pipeline[each.value.identity].principal_id
}
