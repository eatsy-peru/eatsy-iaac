variable "app_code" {
  description = "App code for Eatsy"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "location_short" {
  description = "Short location code"
  type        = string
}

variable "iaac_subscription_id" {
  description = "Azure subscription ID"
  type        = string
}

variable "github_owner" {
  description = "GitHub organization owner"
  type        = string
}

variable "github_repository_names" {
  description = "GitHub repositories requiring federated credentials"
  type        = list(string)
}

variable "github_oidc_environments" {
  description = "Environments for GitHub OIDC federated credentials"
  type        = list(string)
}

variable "deployment_subscription_id" {
  description = "Subscription ID where eatsy-azure-terraform's actual infrastructure is deployed (Subscription B)"
  type        = string
}

variable "control_plane_enabled" {
  description = "Create the Deployment Control Plane Static Web App (enable in prd only)"
  type        = bool
  default     = false
}

variable "control_plane_repository_name" {
  description = "GitHub repository of the Deployment Control Plane"
  type        = string
  default     = "eatsy-deployment-control-plane"
}

variable "control_plane_github_app_id" {
  description = "App ID of the control plane's GitHub App (empty until it exists)"
  type        = string
  default     = ""
}

variable "control_plane_github_installation_id" {
  description = "Installation ID of the control plane's GitHub App (empty until installed)"
  type        = string
  default     = ""
}

variable "control_plane_allowed_github_users" {
  description = "Comma-separated GitHub logins allowed to use the control plane"
  type        = string
  default     = ""
}
