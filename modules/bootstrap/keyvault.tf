/*
 * KEY VAULT CONFIGURATION - BOOTSTRAP MODULE
 * ==========================================
 * This file contains the Key Vault container configuration.
 * Secrets inside the Key Vault are managed by other repositories.
 */

# Key Vault - Container level management only (secrets managed elsewhere)
resource "azurerm_key_vault" "iaac" {
  name                       = "AKVT01${local.resNameSuffix}"
  location                   = var.location
  resource_group_name        = azurerm_resource_group.main_rg.name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  soft_delete_retention_days = 7
  purge_protection_enabled   = false
  rbac_authorization_enabled = true

  network_acls {
    default_action = "Allow"
    bypass         = "AzureServices"
  }

  tags = local.common_tags
}
