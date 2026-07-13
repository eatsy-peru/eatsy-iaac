# Development Bootstrap Configuration

app_code   = "IAAC"
environment = "DEV"
location   = "East US 2"
location_short = "EU2"
subscription_id = "9a1cfce6-9caa-4bf2-8b7c-0ceaf0ddb179"

# GitHub configuration
github_owner = "eatsy-peru"
github_repository_names = [
  "eatsy-azure-terraform",
  "eatsy-iaac"
  # Add other repositories that need federated credentials
]

github_oidc_environments = ["dev", "prd"]

# Deployment resource group IDs - used to grant Reader role
# Format: /subscriptions/{subscription-id}/resourceGroups/{resource-group-name}
deployment_resource_group_ids = [
  # Example:
  # "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/RGE01EU2DEV"
]

/*
cd infra/bootstrap/dev

# Import Resource Group
terraform import module.bootstrap.azurerm_resource_group.main_rg /subscriptions/9a1cfce6-9caa-4bf2-8b7c-0ceaf0ddb179/resourceGroups/RSGR01EU2IAACDEV

# Import Key Vault
terraform import module.bootstrap.azurerm_key_vault.iaac /subscriptions/9a1cfce6-9caa-4bf2-8b7c-0ceaf0ddb179/resourceGroups/RSGR01EU2IAACDEV/providers/Microsoft.KeyVault/vaults/AKVT01EU2IAACDEV

# Import Storage Account
terraform import module.bootstrap.azurerm_storage_account.tfstate /subscriptions/9a1cfce6-9caa-4bf2-8b7c-0ceaf0ddb179/resourceGroups/RSGR01EU2IAACDEV/providers/Microsoft.Storage/storageAccounts/stac01eu2iaacdev
*/