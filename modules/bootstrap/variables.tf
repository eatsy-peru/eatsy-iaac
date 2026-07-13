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
  default     = ["dev", "prd"]
}

variable "deployment_resource_group_ids" {
  description = "List of resource group IDs where the identity needs Reader role"
  type        = list(string)
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

