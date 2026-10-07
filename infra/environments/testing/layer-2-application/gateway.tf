# WAF policy with the Microsoft default rule set. It starts in Detection mode (log only);
# Prevention (block) follows after normal use has been reviewed in the WAF logs.
resource "azurerm_web_application_firewall_policy" "main" {
  name                = "waf-sits-${local.environment}-${local.region_code}"
  resource_group_name = data.azurerm_resource_group.layers["application"].name
  location            = data.azurerm_resource_group.layers["application"].location
  tags                = local.tags

  policy_settings {
    enabled            = true
    mode               = "Detection"
    request_body_check = true
  }

  managed_rules {
    managed_rule_set {
      type    = "Microsoft_DefaultRuleSet"
      version = "2.1"
    }
  }
}

locals {
  # Static private address of the gateway in snet-agw (10.20.4.0/24); the WAF has no public address
  gateway_private_ip = "10.20.4.10"

  # Versionless secret identifier of the WAF certificate from layer 0, so the gateway follows certificate renewals.
  # It is built from the vault address, so Terraform never reads the certificate vault data plane.
  waf_certificate_secret_id = "${data.azurerm_key_vault.cert.vault_uri}secrets/cert-app-${local.environment}"

  gateway = {
    frontend_ip   = "private"
    frontend_port = "https"
    certificate   = "cert-app-${local.environment}"
    listener      = "https-${local.environment}"
    backend_pool  = "webapp"
    backend_https = "webapp-https"
    probe         = "webapp-health"
    rewrite_set   = "forwarded-host"
    routing_rule  = "app-${local.environment}"
  }
}

# Application Gateway WAF_v2, private address only (network isolation), in its delegated subnet
resource "azurerm_application_gateway" "main" {
  name                              = "agw-sits-${local.environment}-${local.region_code}"
  resource_group_name               = data.azurerm_resource_group.layers["application"].name
  location                          = data.azurerm_resource_group.layers["application"].location
  firewall_policy_id                = azurerm_web_application_firewall_policy.main.id
  force_firewall_policy_association = true
  http2_enabled                     = true
  tags                              = local.tags

  sku {
    name = "WAF_v2"
    tier = "WAF_v2"
  }

  # Testing uses a small capacity: no reserved instances, at most two capacity units
  autoscale_configuration {
    min_capacity = 0
    max_capacity = 2
  }

  # The gateway reads the WAF certificate as a secret with its own identity from layer 0 through the vault private endpoint
  identity {
    type         = "UserAssigned"
    identity_ids = [data.azurerm_user_assigned_identity.main["agw"].id]
  }

  gateway_ip_configuration {
    name      = "gateway"
    subnet_id = data.azurerm_subnet.main["snet-agw"].id
  }

  frontend_ip_configuration {
    name                          = local.gateway.frontend_ip
    subnet_id                     = data.azurerm_subnet.main["snet-agw"].id
    private_ip_address_allocation = "Static"
    private_ip_address            = local.gateway_private_ip
  }

  frontend_port {
    name = local.gateway.frontend_port
    port = 443
  }

  ssl_certificate {
    name                = local.gateway.certificate
    key_vault_secret_id = local.waf_certificate_secret_id
  }

  ssl_policy {
    policy_type = "Predefined"
    policy_name = "AppGwSslPolicy20220101"
  }

  http_listener {
    name                           = local.gateway.listener
    frontend_ip_configuration_name = local.gateway.frontend_ip
    frontend_port_name             = local.gateway.frontend_port
    protocol                       = "Https"
    ssl_certificate_name           = local.gateway.certificate
    host_names                     = [local.app_host_name]
  }

  # Backend: the default host name of the Web App, which resolves to its private endpoint in this network
  backend_address_pool {
    name  = local.gateway.backend_pool
    fqdns = [azurerm_linux_web_app.main.default_hostname]
  }

  # HTTPS to the backend with an explicit host name and SNI; the publicly trusted App Service certificate is validated
  backend_http_settings {
    name                  = local.gateway.backend_https
    port                  = 443
    protocol              = "Https"
    cookie_based_affinity = "Disabled"
    host_name             = azurerm_linux_web_app.main.default_hostname
    probe_name            = local.gateway.probe
    request_timeout       = 30
  }

  # The health path checks the app and its vault access, not only the sign-in redirect
  probe {
    name                = local.gateway.probe
    protocol            = "Https"
    host                = azurerm_linux_web_app.main.default_hostname
    path                = "/health"
    interval            = 30
    timeout             = 30
    unhealthy_threshold = 3

    match {
      status_code = ["200-399"]
    }
  }

  # The app builds its sign-in redirect from the original name (forward_proxy_convention = "Standard")
  rewrite_rule_set {
    name = local.gateway.rewrite_set

    rewrite_rule {
      name          = "set-x-forwarded-host"
      rule_sequence = 100

      request_header_configuration {
        header_name  = "X-Forwarded-Host"
        header_value = "{var_host}"
      }
    }
  }

  request_routing_rule {
    name                       = local.gateway.routing_rule
    rule_type                  = "Basic"
    priority                   = 100
    http_listener_name         = local.gateway.listener
    backend_address_pool_name  = local.gateway.backend_pool
    backend_http_settings_name = local.gateway.backend_https
    rewrite_rule_set_name      = local.gateway.rewrite_set
  }
}

# app.test.sits.internal points to the private address of the WAF
resource "azurerm_private_dns_a_record" "app" {
  name                = "app"
  private_dns_zone_id = data.azurerm_private_dns_zone.main["internal"].id
  ttl                 = 300
  records             = [azurerm_application_gateway.main.frontend_ip_configuration[0].private_ip_address]
  tags                = local.tags
}
