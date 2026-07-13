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

variable "subscription_id" {
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

variable "deployment_resource_group_ids" {
  description = "Resource group IDs for deployment subscriptions"
  type        = list(string)
}

variable "github_oidc_environments" {
  description = "Environments for GitHub OIDC federated credentials"
  type        = list(string)
  default     = ["dev", "prd"]
}
