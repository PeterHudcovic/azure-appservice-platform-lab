provider "azurerm" {
  features {
    # The application vault has a fixed name: a layer 2 destroy leaves it in soft-delete,
    # and the next apply recovers it together with its secrets
    key_vault {
      purge_soft_delete_on_destroy    = false
      recover_soft_deleted_key_vaults = true
    }
  }

  subscription_id     = var.subscription_id
  storage_use_azuread = true
}
