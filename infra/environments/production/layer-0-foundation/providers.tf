provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy    = false
      recover_soft_deleted_key_vaults = true
    }
  }

  subscription_id     = var.subscription_id
  storage_use_azuread = true
}

# Read-only lookups in the non-production subscription: the shared package storage and the
# permanent NAT addresses of development and testing (for Conditional Access)
provider "azurerm" {
  alias = "nonprod"

  features {}

  subscription_id     = var.nonprod_subscription_id
  storage_use_azuread = true
}

provider "azuread" {}
