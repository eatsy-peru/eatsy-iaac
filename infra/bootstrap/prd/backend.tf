terraform {
  backend "azurerm" {
    resource_group_name  = "RSGR01EU2IAACPRD"
    storage_account_name = "stac01eu2iaacprd"
    container_name       = "tfstate"
    key                  = "iaac-prd.tfstate"
    use_azuread_auth     = true
  }
}
