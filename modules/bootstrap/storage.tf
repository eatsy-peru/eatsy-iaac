/*
 * TFSTATE STORAGE CONFIGURATION - BOOTSTRAP MODULE
 * ================================================
 * This file contains the Storage Account for Terraform state.
 * Container/blob management is handled by other repositories.
 */

# Terraform State Storage Account - Container level management only (blobs managed elsewhere)
resource "azurerm_storage_account" "tfstate" {
  name                     = "stac01${local.resNameSuffixLw}"
  resource_group_name      = azurerm_resource_group.main_rg.name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  # Security settings
  https_traffic_only_enabled      = true
  min_tls_version                 = "TLS1_2"
  default_to_oauth_authentication = true
  access_tier                     = "Cool"

  # Blob properties for state storage
  blob_properties {
    delete_retention_policy {
      days = 7
    }
    versioning_enabled = true
  }

  tags = local.common_tags
}

# Certificate Storage Container
resource "azurerm_storage_container" "certs" {
  name                  = "certs"
  storage_account_name  = azurerm_storage_account.tfstate.name
  container_access_type = "private"
}
