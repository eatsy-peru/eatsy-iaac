/*
 * DEVELOPMENT BOOTSTRAP CONFIGURATION
 * ==================================
 * Manages the Key Vault, Storage Account, and Managed Identity
 * for the IAAC infrastructure bootstrap.
 */

module "bootstrap" {
  source = "../../../modules/bootstrap"

  app_code                   = var.app_code
  environment                = var.environment
  location                   = var.location
  location_short             = var.location_short
  github_owner               = var.github_owner
  github_repository_names    = var.github_repository_names
  github_oidc_environments   = var.github_oidc_environments
  deployment_subscription_id = var.deployment_subscription_id

  control_plane_enabled                = var.control_plane_enabled
  control_plane_repository_name        = var.control_plane_repository_name
  control_plane_github_app_id          = var.control_plane_github_app_id
  control_plane_github_installation_id = var.control_plane_github_installation_id
  control_plane_allowed_github_users   = var.control_plane_allowed_github_users

  providers = {
    azurerm            = azurerm
    azurerm.deployment = azurerm.deployment
    azuread            = azuread
    github             = github
  }
}
