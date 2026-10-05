resource "azurerm_service_plan" "main" {
  name                = "asp-sits-${local.environment}-${local.region_code}"
  resource_group_name = data.azurerm_resource_group.layers["application"].name
  location            = data.azurerm_resource_group.layers["application"].location
  os_type             = "Linux"
  # Development runs one B1 instance without autoscale (Test and Prod use P0v3 with 1 to 3 instances)
  sku_name     = "B1"
  worker_count = 1
  tags         = local.tags
}

locals {
  app_identity_client_id = data.azurerm_user_assigned_identity.main["app"].client_id
}

# Linux Web App: reachable only through its private endpoint, outbound traffic through snet-app and the NAT Gateway
resource "azurerm_linux_web_app" "main" {
  name                = "app-sits-${local.environment}-${local.region_code}"
  resource_group_name = data.azurerm_resource_group.layers["application"].name
  location            = data.azurerm_resource_group.layers["application"].location
  service_plan_id     = azurerm_service_plan.main.id

  https_only                                     = true
  public_network_access_enabled                  = false
  ftp_publish_basic_authentication_enabled       = false
  webdeploy_publish_basic_authentication_enabled = false
  client_affinity_enabled                        = false
  virtual_network_subnet_id                      = data.azurerm_subnet.main["snet-app"].id

  identity {
    type         = "UserAssigned"
    identity_ids = [data.azurerm_user_assigned_identity.main["app"].id]
  }

  # Key Vault references in the settings resolve with the application identity from layer 0
  key_vault_reference_identity_id = data.azurerm_user_assigned_identity.main["app"].id

  site_config {
    always_on                         = true
    ftps_state                        = "Disabled"
    http2_enabled                     = true
    minimum_tls_version               = "1.2"
    scm_minimum_tls_version           = "1.2"
    remote_debugging_enabled          = false
    vnet_route_all_enabled            = true
    health_check_path                 = "/health"
    health_check_eviction_time_in_min = 10

    application_stack {
      python_version = "3.12"
    }
  }

  # Settings hold identifiers and references only, never secret values
  app_settings = {
    APP_ENVIRONMENT                       = local.environment
    AZURE_CLIENT_ID                       = local.app_identity_client_id
    KEY_VAULT_URI                         = azurerm_key_vault.app.vault_uri
    APPLICATIONINSIGHTS_CONNECTION_STRING = data.azurerm_application_insights.main.connection_string
    # The package already contains its Python dependencies; App Service does not build it
    SCM_DO_BUILD_DURING_DEPLOYMENT = "false"
    # Sign-in without a client secret: the app registration trusts the application identity (federated credential)
    OVERRIDE_USE_MI_FIC_ASSERTION_CLIENTID = local.app_identity_client_id
  }

  # App Service Authentication with Entra ID: sign-in is required, only users assigned to the
  # enterprise application are admitted (assignment required is set in layer 0)
  auth_settings_v2 {
    auth_enabled           = true
    require_authentication = true
    require_https          = true
    unauthenticated_action = "RedirectToLoginPage"
    default_provider       = "azureactivedirectory"
    runtime_version        = "~1"
    # The health check reports the state of the app and the vault, so it stays outside sign-in
    excluded_paths = ["/health"]
    # Behind the WAF the app takes its public name from X-Forwarded-Host
    forward_proxy_convention = "Standard"

    active_directory_v2 {
      client_id                  = data.azuread_application.app.client_id
      tenant_auth_endpoint       = "https://login.microsoftonline.com/${data.azurerm_client_config.current.tenant_id}/v2.0"
      client_secret_setting_name = "OVERRIDE_USE_MI_FIC_ASSERTION_CLIENTID"
    }

    login {
      token_store_enabled = true
    }
  }

  tags = local.tags
}

# Private endpoint of the Web App (application and its .scm deployment endpoint share the address)
resource "azurerm_private_endpoint" "webapp" {
  name                          = "pe-${azurerm_linux_web_app.main.name}"
  resource_group_name           = data.azurerm_resource_group.layers["application"].name
  location                      = data.azurerm_resource_group.layers["application"].location
  subnet_id                     = data.azurerm_subnet.main["snet-pe"].id
  custom_network_interface_name = "nic-pe-${azurerm_linux_web_app.main.name}"
  tags                          = local.tags

  private_service_connection {
    name                           = "psc-${azurerm_linux_web_app.main.name}"
    private_connection_resource_id = azurerm_linux_web_app.main.id
    subresource_names              = ["sites"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [data.azurerm_private_dns_zone.main["webapp"].id]
  }
}

# The endpoint joins the pe-webapp group: the snet-pe rules allow only snet-agw and snet-agents-app
resource "azurerm_private_endpoint_application_security_group_association" "webapp" {
  private_endpoint_id           = azurerm_private_endpoint.webapp.id
  application_security_group_id = data.azurerm_application_security_group.main["pe-webapp"].id
}
