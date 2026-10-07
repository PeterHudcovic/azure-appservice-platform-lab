# Alerts from the design: application outage, unhealthy gateway backend, denied Key Vault access, and a request
# matched by the WAF (Detection mode logs instead of blocking). They notify the administrator by e-mail.
resource "azurerm_monitor_action_group" "admin" {
  name                = "ag-sits-${local.environment}-${local.region_code}"
  resource_group_name = data.azurerm_resource_group.layers["application"].name
  short_name          = "sits-${local.environment}"
  tags                = local.tags

  email_receiver {
    name                    = "administrator"
    email_address           = var.alert_email
    use_common_alert_schema = true
  }
}

locals {
  metric_alerts = {
    app-unhealthy = {
      description = "The application health check (/health, including Key Vault access) is failing."
      scope       = azurerm_linux_web_app.main.id
      namespace   = "Microsoft.Web/sites"
      metric      = "HealthCheckStatus"
      operator    = "LessThan"
      threshold   = 100
    }
    gateway-backend-unhealthy = {
      description = "The Application Gateway reports an unhealthy backend (UnhealthyHostCount)."
      scope       = azurerm_application_gateway.main.id
      namespace   = "Microsoft.Network/applicationGateways"
      metric      = "UnhealthyHostCount"
      operator    = "GreaterThan"
      threshold   = 0
    }
  }

  # Key Vault and gateway logs land in AzureDiagnostics; the resource identifier keeps environments apart
  # in the shared non-production workspace
  log_alerts = {
    keyvault-access-denied = {
      description = "Denied access (HTTP 403) to the application Key Vault."
      severity    = 2
      query       = <<-KQL
        AzureDiagnostics
        | where _ResourceId =~ "${azurerm_key_vault.app.id}"
        | where httpStatusCode_d == 403
      KQL
    }
    waf-request-matched = {
      description = "The WAF matched a request against its rules (logged in Detection mode, blocked in Prevention mode)."
      severity    = 3
      query       = <<-KQL
        AzureDiagnostics
        | where _ResourceId =~ "${azurerm_application_gateway.main.id}"
        | where Category == "ApplicationGatewayFirewallLog"
        | where action_s in ("Blocked", "Detected", "Matched")
      KQL
    }
  }
}

resource "azurerm_monitor_metric_alert" "main" {
  for_each = local.metric_alerts

  name                = "alert-sits-${local.environment}-${each.key}"
  resource_group_name = data.azurerm_resource_group.layers["application"].name
  scopes              = [each.value.scope]
  description         = each.value.description
  severity            = 1
  frequency           = "PT1M"
  window_size         = "PT5M"
  tags                = local.tags

  criteria {
    metric_namespace = each.value.namespace
    metric_name      = each.value.metric
    aggregation      = "Average"
    operator         = each.value.operator
    threshold        = each.value.threshold
  }

  action {
    action_group_id = azurerm_monitor_action_group.admin.id
  }
}

resource "azurerm_monitor_scheduled_query_rules_alert_v2" "main" {
  for_each = local.log_alerts

  name                 = "alert-sits-${local.environment}-${each.key}"
  resource_group_name  = data.azurerm_resource_group.layers["application"].name
  location             = data.azurerm_log_analytics_workspace.main.location
  scopes               = [data.azurerm_log_analytics_workspace.main.id]
  description          = each.value.description
  severity             = each.value.severity
  evaluation_frequency = "PT5M"
  window_duration      = "PT5M"
  # Columns appear in AzureDiagnostics only after the first matching record, so the query is not validated at creation
  skip_query_validation = true
  tags                  = local.tags

  criteria {
    query                   = each.value.query
    time_aggregation_method = "Count"
    operator                = "GreaterThan"
    threshold               = 0
  }

  action {
    action_groups = [azurerm_monitor_action_group.admin.id]
  }
}
