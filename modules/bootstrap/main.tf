terraform {
  # State storage managed separately
  required_providers {
    github = {
      source = "integrations/github"
    }
    azuread = {
      source = "hashicorp/azuread"
    }
    # configuration_aliases makes this module accept a second azurerm configuration
    # scoped to the deployment subscription (Subscription B), where
    # eatsy-azure-terraform's actual infrastructure lives, in addition to the default.
    azurerm = {
      source                = "hashicorp/azurerm"
      configuration_aliases = [azurerm.deployment]
    }
  }
}

data "azurerm_client_config" "current" {
}

data "azuread_client_config" "current" {
}
