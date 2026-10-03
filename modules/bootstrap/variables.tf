variable "app_code" {
  description = "App code for Eatsy, used in resource naming"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, prd, etc.)"
  type        = string
}

variable "location" {
  description = "Azure region for resource deployment"
  type        = string
}

variable "location_short" {
  description = "Short code for location, used in resource naming"
  type        = string
}

variable "github_owner" {
  description = "GitHub organization owner for federated credentials"
  type        = string
}

variable "github_repository_names" {
  description = "List of GitHub repositories that need federated credentials"
  type        = list(string)
}

variable "github_oidc_environments" {
  description = "List of environments to create federated credentials for"
  type        = list(string)
}

variable "deployment_subscription_id" {
  description = "Subscription ID where eatsy-azure-terraform's actual infrastructure (Container Apps, Static Web Apps, etc.) is deployed (Subscription B) — the GitHub OIDC identity needs RBAC here in addition to the IAAC subscription"
  type        = string
}

variable "control_plane_enabled" {
  description = "Create the Deployment Control Plane Static Web App (Free) and push its deployment token to the control plane repo. Enable in a single environment only (prd)."
  type        = bool
  default     = false
}

variable "control_plane_repository_name" {
  description = "GitHub repository of the Deployment Control Plane; receives the Static Web App deployment token as AZURE_STATIC_WEB_APPS_API_TOKEN"
  type        = string
  default     = "eatsy-deployment-control-plane"
}

variable "control_plane_github_app_id" {
  description = "App ID of the control plane's GitHub App. Leave empty until the App exists; the private key is set outside Terraform."
  type        = string
  default     = ""
}

variable "control_plane_github_installation_id" {
  description = "Installation ID of the control plane's GitHub App on the managed repositories. Leave empty until the App is installed."
  type        = string
  default     = ""
}

variable "control_plane_allowed_github_users" {
  description = "Comma-separated GitHub logins allowed to use the control plane (empty means nobody)"
  type        = string
  default     = ""
}

###################################################
# LOCALS
###################################################
locals {
  resNameSuffix   = "${upper(var.location_short)}${upper(var.app_code)}${upper(var.environment)}"
  resNameSuffixLw = "${lower(var.location_short)}${lower(var.app_code)}${lower(var.environment)}"

  common_tags = {
    Environment = upper(var.environment)
    CreatedBy   = "Terraform"
    Component   = "Bootstrap"
  }
}

