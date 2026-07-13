/*
 * MANAGED IDENTITY CONFIGURATION - BOOTSTRAP MODULE
 * =================================================
 * This file contains the Azure AD application, service principal,
 * federated credentials for GitHub Actions, and role assignments.
 */


# Create Azure AD Application for GitHub Actions
resource "azuread_application" "github_oidc" {
  display_name = "SVPR01${local.resNameSuffix}"
  owners       = [data.azuread_client_config.current.object_id]
}

# Create Service Principal associated with the application
resource "azuread_service_principal" "github_oidc" {
  client_id                    = azuread_application.github_oidc.client_id
  app_role_assignment_required = false
  owners                       = [data.azuread_client_config.current.object_id]
}

#################################################
# FEDERATED IDENTITY CREDENTIALS FOR GITHUB ACTIONS
#################################################

locals {
  github_oidc_credentials = {
    for tuple in setproduct(var.github_repository_names, var.github_oidc_environments) :
    "${tuple[0]}:${tuple[1]}" => {
      repository  = tuple[0]
      environment = tuple[1]
      subject     = "repo:${var.github_owner}/${tuple[0]}:environment:${tuple[1]}"
      display_name = substr(
        format("svpr01_%s_%s", replace(tuple[0], "-", "_"), tuple[1]),
        0,
        120
      )
      description = "GitHub Actions OIDC credential for ${tuple[0]} repository in ${var.github_owner} organization (${tuple[1]} environment)"
    }
  }
}

resource "azuread_application_federated_identity_credential" "github_repo_env" {
  for_each = local.github_oidc_credentials

  application_id = azuread_application.github_oidc.id
  audiences      = ["api://AzureADTokenExchange"]
  issuer         = "https://token.actions.githubusercontent.com"
  display_name   = each.value.display_name
  description    = each.value.description
  subject        = each.value.subject
}

#################################################
# ROLE ASSIGNMENTS
#################################################

# Grant Reader role on each deployment resource group
resource "azurerm_role_assignment" "deployment_rg_reader" {
  scope                = azurerm_resource_group.main_rg.id
  role_definition_name = "Reader"
  principal_id         = azuread_service_principal.github_oidc.object_id
}

# Grant Key Vault Secrets User on the IAAC Key Vault
resource "azurerm_role_assignment" "keyvault_secrets_user" {
  scope                = azurerm_key_vault.iaac.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azuread_service_principal.github_oidc.object_id
}

# Grant Key Vault Secrets Officer on the IAAC Key Vault
resource "azurerm_role_assignment" "keyvault_secrets_officer" {
  scope                = azurerm_key_vault.iaac.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = azuread_service_principal.github_oidc.object_id
}

# Grant Storage Blob Data Contributor on the tfstate storage account
resource "azurerm_role_assignment" "storage_blob_contributor" {
  scope                = azurerm_storage_account.tfstate.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azuread_service_principal.github_oidc.object_id
}

# Grant Key Vault Secrets User to the current user (bootstrap operator)
resource "azurerm_role_assignment" "keyvault_secrets_user_current_user" {
  scope                = azurerm_key_vault.iaac.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = data.azurerm_client_config.current.object_id
}

# Grant Key Vault Secrets Officer to the current user (bootstrap operator)
resource "azurerm_role_assignment" "keyvault_secrets_officer_current_user" {
  scope                = azurerm_key_vault.iaac.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = data.azurerm_client_config.current.object_id
}

