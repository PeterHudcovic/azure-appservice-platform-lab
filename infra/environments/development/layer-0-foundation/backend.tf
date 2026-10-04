terraform {
  backend "azurerm" {
    resource_group_name  = "rg-sits-dev-foundation-swc"
    storage_account_name = "stsitstfdevswc"
    container_name       = "tfstate-layer0"
    key                  = "development-layer0.tfstate"
    use_azuread_auth     = true
  }
}