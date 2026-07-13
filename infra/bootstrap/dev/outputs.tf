output "key_vault_id" {
  description = "The ID of the Key Vault"
  value       = module.bootstrap.key_vault_id
}

output "key_vault_name" {
  description = "The name of the Key Vault"
  value       = module.bootstrap.key_vault_name
}

output "key_vault_uri" {
  description = "The URI of the Key Vault"
  value       = module.bootstrap.key_vault_uri
}

output "storage_account_id" {
  description = "The ID of the Storage Account"
  value       = module.bootstrap.storage_account_id
}

output "storage_account_name" {
  description = "The name of the Storage Account"
  value       = module.bootstrap.storage_account_name
}

output "storage_account_primary_blob_endpoint" {
  description = "The primary blob endpoint of the Storage Account"
  value       = module.bootstrap.storage_account_primary_blob_endpoint
}

output "app_registration_id" {
  description = "The ID of the Azure AD application"
  value       = module.bootstrap.app_registration_id
}

output "app_registration_client_id" {
  description = "The client ID of the Azure AD application"
  value       = module.bootstrap.app_registration_client_id
}

output "service_principal_object_id" {
  description = "The object ID of the service principal"
  value       = module.bootstrap.service_principal_object_id
}

output "service_principal_id" {
  description = "The principal ID of the service principal"
  value       = module.bootstrap.service_principal_id
}

output "federated_credentials" {
  description = "Map of created federated credentials"
  value       = module.bootstrap.federated_credentials
}
