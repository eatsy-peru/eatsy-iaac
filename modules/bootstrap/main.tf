terraform {
  # State storage managed separately
}

data "azurerm_client_config" "current" {
}

data "azuread_client_config" "current" {
}
