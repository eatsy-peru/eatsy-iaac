# TERRAFORM COMMON VARIABLES FILE
# ================================
# This file contains the common values shared across all environments
# Environment-specific overrides are in each environment's terraform.tfvars

#################################################
# 1. ENVIRONMENT CONFIGURATION (COMMON)
#################################################
# App code
app_code             = "IAAC"
iaac_subscription_id = "9a1cfce6-9caa-4bf2-8b7c-0ceaf0ddb179"

# Azure region for deployment
location       = "East US 2"
location_short = "EU2"

#################################################
# 2. SUBSCRIPTION CONFIGURATION (COMMON)
#################################################
# Deploy target subscription (Subscription B) — where eatsy-azure-terraform's actual
# infrastructure is deployed. Must match eatsy-azure-terraform/infra/common.tfvars'
# deployment_subscription_id.
deployment_subscription_id = "1f4201a4-47d2-41d5-bc64-284406236325"

#################################################
# 4. GITHUB CONFIGURATION (COMMON)
#################################################
github_owner = "eatsy-peru"

# Repositories requiring federated credentials (same set for dev and prd)
github_repository_names = [
  "eatsy-azure-terraform",
  "eatsy-iaac"
  # Add other repositories that need federated credentials
]
