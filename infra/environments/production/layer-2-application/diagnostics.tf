# Diagnostic settings to the production Log Analytics workspace of layer 0, so the records survive a layer 2 destroy:
# Key Vault audit (AuditEvent), App Service logs, WAF and gateway access logs, and platform metrics
locals {
  diagnostic_targets = {
    keyvault = { resource_id = azurerm_key_vault.app.id, logs = true }
    webapp   = { resource_id = azurerm_linux_web_app.main.id, logs = true }
    gateway  = { resource_id = azurerm_application_gateway.main.id, logs = true }
    plan     = { resource_id = azurerm_service_plan.main.id, logs = false }
  }
}

resource "azurerm_monitor_diagnostic_setting" "main" {
  for_each = local.diagnostic_targets

  name                       = "diag-${data.azurerm_log_analytics_workspace.main.name}"
  target_resource_id         = each.value.resource_id
  log_analytics_workspace_id = data.azurerm_log_analytics_workspace.main.id

  dynamic "enabled_log" {
    for_each = each.value.logs ? ["allLogs"] : []

    content {
      category_group = enabled_log.value
    }
  }

  enabled_metric {
    category = "AllMetrics"
  }
}
