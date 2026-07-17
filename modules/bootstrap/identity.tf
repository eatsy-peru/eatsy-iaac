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

# Grant Contributor on the deployment subscription (Subscription B) — this is where
# eatsy-azure-terraform's actual infrastructure (backend/frontend resource groups,
# Container Apps, Static Web Apps, ACS, etc.) is created by module.core/module.cf/
# module.gh. Subscription scope is required because the very first `terraform apply`
# for eatsy-azure-terraform has to create those resource groups itself, which is a
# subscription-level operation — there's nothing narrower to scope this to yet.
resource "azurerm_role_assignment" "deployment_subscription_contributor" {
  provider             = azurerm.deployment
  scope                = "/subscriptions/${var.deployment_subscription_id}"
  role_definition_name = "Contributor"
  principal_id         = azuread_service_principal.github_oidc.object_id
}

# Contributor alone is not enough: eatsy-azure-terraform's own Terraform code creates
# several azurerm_role_assignment resources at apply time (modules/core/keyvault.tf
# grants itself Key Vault Administrator on the app Key Vault; container_apps.tf and
# image_storage.tf grant the Container App's managed identity Key Vault/Storage
# access; ad_service_principal.tf grants Contributor/Key-Vault-access to the
# app-repo service principal it creates). Creating role assignments requires
# Microsoft.Authorization/roleAssignments/write, which Contributor deliberately
# excludes — User Access Administrator adds it.
resource "azurerm_role_assignment" "deployment_subscription_user_access_administrator" {
  provider             = azurerm.deployment
  scope                = "/subscriptions/${var.deployment_subscription_id}"
  role_definition_name = "User Access Administrator"
  principal_id         = azuread_service_principal.github_oidc.object_id
}

# eatsy-azure-terraform's modules/core/ad_service_principal.tf has this identity
# create its own Azure AD application/service principal/federated credentials (used
# for app-repo deploys) — a Microsoft Graph directory action that subscription RBAC
# does not grant. Application Administrator is broader than strictly necessary
# (tenant-wide app management, not just apps this SP owns); narrowing to a scoped
# Application.ReadWrite.OwnedBy Graph API permission is a possible future hardening.
resource "azuread_directory_role" "application_administrator" {
  display_name = "Application Administrator"
}

resource "azuread_directory_role_assignment" "github_oidc_app_admin" {
  role_id             = azuread_directory_role.application_administrator.object_id
  principal_object_id = azuread_service_principal.github_oidc.object_id
}

