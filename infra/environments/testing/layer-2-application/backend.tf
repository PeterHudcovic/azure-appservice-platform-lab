terraform {
  backend "azurerm" {
    resource_group_name  = "rg-sits-test-foundation-swc"
    storage_account_name = "stsitstftestswc"
    container_name       = "tfstate-layer2"
    key                  = "testing-layer2.tfstate"
    use_azuread_auth     = true
  }
}
