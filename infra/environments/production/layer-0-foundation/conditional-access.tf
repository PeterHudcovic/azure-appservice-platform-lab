# Conditional Access for the production administrator account. Created in report-only mode
# ("enabledForReportingButNotEnforced"); Peter switches them on manually after reviewing the sign-in reports.
# The account running this configuration (Lab Admin) is always excluded, so it can never lock itself out.

# Permanent NAT addresses of development and testing (layer 0 of the non-production subscription)
data "azurerm_public_ip" "nonprod_nat" {
  provider = azurerm.nonprod
  for_each = toset(["dev", "test"])

  name                = "pip-sits-${each.key}-nat-${local.region_code}"
  resource_group_name = "rg-sits-${each.key}-network-${local.region_code}"
}

resource "azuread_named_location" "nonprod_nat" {
  display_name = "SITS development and testing NAT addresses"

  ip {
    ip_ranges = [for ip in data.azurerm_public_ip.nonprod_nat : "${ip.ip_address}/32"]
    trusted   = false
  }
}

locals {
  conditional_access_policies = {
    block-nonprod-locations = {
      display_name = "SITS production: block the production admin from development and testing NAT addresses"
      # Conditional Access expects the named location object identifier, not the Graph path in "id"
      locations   = [azuread_named_location.nonprod_nat.object_id]
      device_code = false
    }
    block-device-code = {
      display_name = "SITS production: block device code sign-in for the production admin"
      locations    = []
      device_code  = true
    }
  }
}

resource "azuread_conditional_access_policy" "prod_admin" {
  for_each = local.conditional_access_policies

  display_name = each.value.display_name
  state        = "enabledForReportingButNotEnforced"

  conditions {
    client_app_types                     = ["all"]
    authentication_flow_transfer_methods = each.value.device_code ? ["deviceCodeFlow"] : null

    applications {
      included_applications = ["All"]
    }

    users {
      included_users = [data.azuread_user.prod_admin.object_id]
      excluded_users = [data.azurerm_client_config.current.object_id]
    }

    dynamic "locations" {
      for_each = length(each.value.locations) > 0 ? [each.value.locations] : []

      content {
        included_locations = locations.value
      }
    }
  }

  grant_controls {
    operator          = "OR"
    built_in_controls = ["block"]
  }
}
