/*
 * PRODUCTION BOOTSTRAP CONFIGURATION
 * ==================================
 * Manages the Key Vault, Storage Account, and Managed Identity
 * for the IAAC infrastructure bootstrap.
 */

module "bootstrap" {
  source = "../../../modules/bootstrap"

  app_code                        = var.app_code
  environment                     = var.environment
  location                        = var.location
  location_short                  = var.location_short
  github_owner                    = var.github_owner
  github_repository_names         = var.github_repository_names
  github_oidc_environments        = var.github_oidc_environments
  deployment_resource_group_ids   = var.deployment_resource_group_ids

}
