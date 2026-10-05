terraform {
  backend "azurerm" {
    resource_group_name  = "rg-sits-prod-foundation-swc"
    storage_account_name = "stsitstfprodswc"
    container_name       = "tfstate-layer2"
    key                  = "production-layer2.tfstate"
    use_azuread_auth     = true
  }
}
