# Production Bootstrap Configuration
# deployment_subscription_id and github_repository_names are shared across dev/prd
# and live in ../../common.tfvars.

environment = "PRD"

github_oidc_environments = ["prd"]

# The Deployment Control Plane manages dev and prd, so a single Static Web App is
# enough. It is created by the prd bootstrap only.
control_plane_enabled = true

#### Ran a second time after creating the GitHub App

# Comma-separated GitHub logins allowed to sign in. Empty means nobody can use the
# control plane, so set your login before the first real use.
control_plane_allowed_github_users   = "gdpc215"

# From the GitHub App created for the control plane (see the control plane repo's
# docs/setup.md). Leave empty on the first apply, fill in after creating/installing
# the App, then apply again. The App's private key is NOT set here.
control_plane_github_app_id          = "5171449"
control_plane_github_installation_id = "167408659"
