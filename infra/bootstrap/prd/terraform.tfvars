# Production Bootstrap Configuration
# deployment_subscription_id and github_repository_names are shared across dev/prd
# and live in ../../common.tfvars.

environment = "PRD"

github_oidc_environments = ["prd"]
