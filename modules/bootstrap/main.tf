terraform {
  # State storage managed separately
  required_providers {
    github = {
      source = "integrations/github"
    }
  }
}

data "azurerm_client_config" "current" {
}

data "azuread_client_config" "current" {
}
