terraform {
  backend "azurerm" {
    resource_group_name  = "rg-sits-dev-foundation-swc"
    storage_account_name = "stsitstfdevswc"
    container_name       = "tfstate-layer2"
    key                  = "development-layer2.tfstate"
    use_azuread_auth     = true
  }
}
