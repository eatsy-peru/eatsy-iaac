#################################################
# 1. PROVIDER REQUIREMENTS
#################################################
terraform {
  required_providers {
    # Azure Resource Manager provider for Azure resources
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.73.0"
    }

    # Azure Active Directory provider for identity management
    azuread = {
      source  = "hashicorp/azuread",
      version = "~> 3.8.0"
    }

    # Cloudflare provider for managing Cloudflare resources
    cloudflare = {
      source  = "cloudflare/cloudflare",
      version = "~> 5.19.1"
    }

    # GitHub provider for managing GitHub resources
    github = {
      source  = "integrations/github",
      version = "~> 6.12.1"
    }
  }
}

#################################################
# 2. PROVIDER CONFIGURATIONS
#################################################
# Azure Resource Manager provider configuration
provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}

# Azure Active Directory provider configuration
provider "azuread" {
  
}

# Auth via env vars:
#   $env:CLOUDFLARE_API_TOKEN  (Cloudflare)
provider "cloudflare" {}

# Auth via env vars:
#   $env:GITHUB_TOKEN          (GitHub)
provider "github" {
  owner = var.github_owner
}