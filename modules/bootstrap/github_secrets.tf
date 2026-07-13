/*
 * GITHUB SECRETS CONFIGURATION - BOOTSTRAP MODULE
 * ===============================================
 * This file pushes the bootstrap service principal credentials
 * as GitHub Actions environment secrets to target repositories.
 *
 * Two types of secrets:
 * 1. SHARED SECRETS (pushed to all repos in github_oidc_credentials)
 *    - AZURE_TENANT_ID
 *    - AZURE_SUBSCRIPTION_ID
 *    - AZURE_CLIENT_ID
 *
 * 2. BOOTSTRAP-ONLY SECRETS (pushed only to eatsy-iaac repo)
 *    - KEY_VAULT_NAME (for bootstrap KV access)
 *    - CERTS_STORAGE_ACCOUNT_NAME (for certificate blob storage)
 */

locals {
  # Filter for eatsy-iaac repo only (to receive bootstrap-specific secrets)
  iaac_repo_environments = {
    for key, cred in local.github_oidc_credentials :
    key => cred if cred.repository == "eatsy-iaac"
  }
}

# Create GitHub repository environments for each federated credential
resource "github_repository_environment" "bootstrap_repo_env" {
  for_each    = local.github_oidc_credentials
  repository  = each.value.repository
  environment = each.value.environment
}

#################################################
# SHARED SECRETS (pushed to all target repos)
#################################################

# Push Azure Tenant ID as environment secret
resource "github_actions_environment_secret" "azure_tenant_id" {
  for_each    = github_repository_environment.bootstrap_repo_env
  repository  = each.value.repository
  environment = each.value.environment
  secret_name = "AZURE_TENANT_ID"
  value       = data.azurerm_client_config.current.tenant_id
}

# Push Azure Subscription ID as environment secret
resource "github_actions_environment_secret" "azure_subscription_id" {
  for_each    = github_repository_environment.bootstrap_repo_env
  repository  = each.value.repository
  environment = each.value.environment
  secret_name = "AZURE_SUBSCRIPTION_ID"
  value       = data.azurerm_client_config.current.subscription_id
}

# Push Azure Client ID as environment secret
resource "github_actions_environment_secret" "azure_client_id" {
  for_each    = github_repository_environment.bootstrap_repo_env
  repository  = each.value.repository
  environment = each.value.environment
  secret_name = "AZURE_CLIENT_ID"
  value       = azuread_application.github_oidc.client_id
}

#################################################
# BOOTSTRAP-ONLY SECRETS (eatsy-iaac only)
#################################################

# Push Key Vault name as environment secret (eatsy-iaac only)
resource "github_actions_environment_secret" "key_vault_name" {
  for_each    = local.iaac_repo_environments
  repository  = each.value.repository
  environment = each.value.environment
  secret_name = "KEY_VAULT_NAME"
  value       = azurerm_key_vault.iaac.name
}

# Push Certificates Storage Account name as environment secret (eatsy-iaac only)
resource "github_actions_environment_secret" "certs_storage_account_name" {
  for_each    = local.iaac_repo_environments
  repository  = each.value.repository
  environment = each.value.environment
  secret_name = "CERTS_STORAGE_ACCOUNT_NAME"
  value       = azurerm_storage_account.tfstate.name
}
