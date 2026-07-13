# Bootstrap Module Outputs
output "app_registration_display_name" {
  description = "Display name of the Azure AD application"
  value       = azuread_application.github_oidc.display_name
}

output "deployment_rg_role_assignments" {
  description = "Map of Reader role assignments on deployment resource groups"
  value = {
    for key, assignment in azurerm_role_assignment.deployment_rg_reader :
    key => assignment.id
  }
}

# Storage Account Outputs
output "storage_account_id" {
  description = "The ID of the Storage Account"
  value       = azurerm_storage_account.tfstate.id
}

output "storage_account_name" {
  description = "The name of the Storage Account"
  value       = azurerm_storage_account.tfstate.name
}

output "storage_account_primary_blob_endpoint" {
  description = "The primary blob endpoint of the Storage Account"
  value       = azurerm_storage_account.tfstate.primary_blob_endpoint
}

# Keyvault Outputs
output "key_vault_id" {
  description = "The ID of the Key Vault"
  value       = azurerm_key_vault.iaac.id
}

output "key_vault_name" {
  description = "The name of the Key Vault"
  value       = azurerm_key_vault.iaac.name
}

output "key_vault_uri" {
  description = "The URI of the Key Vault"
  value       = azurerm_key_vault.iaac.vault_uri
}

# Service Principal Outputs
output "app_registration_id" {
  description = "The ID of the Azure AD application"
  value       = azuread_application.github_oidc.id
}

output "app_registration_client_id" {
  description = "The client ID of the Azure AD application"
  value       = azuread_application.github_oidc.client_id
}

output "service_principal_object_id" {
  description = "The object ID of the service principal"
  value       = azuread_service_principal.github_oidc.object_id
}

output "service_principal_id" {
  description = "The principal ID of the service principal"
  value       = azuread_service_principal.github_oidc.id
}

output "federated_credentials" {
  description = "Map of created federated credentials"
  value = {
    for key, cred in azuread_application_federated_identity_credential.github_repo_env :
    key => {
      id      = cred.id
      subject = cred.subject
    }
  }
}
