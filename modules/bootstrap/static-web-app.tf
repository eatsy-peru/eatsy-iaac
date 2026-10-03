/*
 * STATIC WEB APP CONFIGURATION - BOOTSTRAP MODULE
 * ===============================================
 * Hosts the Deployment Control Plane (repo eatsy-deployment-control-plane): an Angular
 * frontend plus managed Azure Functions API. Free plan, so it costs nothing.
 *
 * It lives here and not in eatsy-azure-terraform because it is operator tooling that
 * deploys the platform, not part of the platform, and must keep working while the
 * platform is being applied.
 *
 * Disabled unless var.control_plane_enabled is true (a single instance is enough: it
 * manages both dev and prd, so only the prd bootstrap turns it on).
 *
 * Settings ownership:
 * - Terraform sets the non-secret settings (GitHub App id/installation id, allowed
 *   GitHub login) once they are known.
 * - GITHUB_APP_PRIVATE_KEY is never held in Terraform or its state. Set it with
 *   `az staticwebapp appsettings set` (see the control plane repo's docs/setup.md);
 *   lifecycle.ignore_changes keeps Terraform from removing it.
 * - The deployment token is pushed to the control plane repo as a GitHub secret in
 *   github_secrets.tf.
 */

locals {
  control_plane_app_settings = merge(
    var.control_plane_github_app_id != "" ? { GITHUB_APP_ID = var.control_plane_github_app_id } : {},
    var.control_plane_github_installation_id != "" ? { GITHUB_APP_INSTALLATION_ID = var.control_plane_github_installation_id } : {},
    var.control_plane_allowed_github_users != "" ? { ALLOWED_GITHUB_USERS = var.control_plane_allowed_github_users } : {},
  )
}

resource "azurerm_static_web_app" "control_plane" {
  count = var.control_plane_enabled ? 1 : 0

  name                = "ASTW01${local.resNameSuffix}"
  resource_group_name = azurerm_resource_group.main_rg.name
  location            = var.location
  sku_tier            = "Free"
  sku_size            = "Free"
  tags                = local.common_tags

  app_settings = local.control_plane_app_settings

  lifecycle {
    ignore_changes = [
      repository_url,
      repository_branch,
      app_settings["GITHUB_APP_PRIVATE_KEY"],
    ]
  }
}
