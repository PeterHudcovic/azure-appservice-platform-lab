terraform {
  backend "azurerm" {
    resource_group_name  = "rg-sits-prod-foundation-swc"
    storage_account_name = "stsitstfprodswc"
    container_name       = "tfstate-layer1"
    key                  = "production-layer1.tfstate"
    use_azuread_auth     = true
  }
}
