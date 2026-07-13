terraform {
  backend "azurerm" {
    resource_group_name  = "RSGR01EU2IAACDEV"
    storage_account_name = "stac01eu2iaacdev"
    container_name       = "tfstate"
    key                  = "iaac-dev.tfstate"
    use_azuread_auth     = true
  }
}
