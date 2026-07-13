# Production Bootstrap Configuration

app_code   = "IAAC"
environment = "PRD"
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

github_oidc_environments = ["prd"]

/*
cd infra/bootstrap/prd

# Import Resource Group
terraform import module.bootstrap.azurerm_resource_group.main_rg /subscriptions/9a1cfce6-9caa-4bf2-8b7c-0ceaf0ddb179/resourceGroups/RSGR01EU2IAACPRD

# Import Key Vault
terraform import module.bootstrap.azurerm_key_vault.iaac /subscriptions/9a1cfce6-9caa-4bf2-8b7c-0ceaf0ddb179/resourceGroups/RSGR01EU2IAACPRD/providers/Microsoft.KeyVault/vaults/AKVT01EU2IAACPRD

# Import Storage Account
terraform import module.bootstrap.azurerm_storage_account.tfstate /subscriptions/9a1cfce6-9caa-4bf2-8b7c-0ceaf0ddb179/resourceGroups/RSGR01EU2IAACPRD/providers/Microsoft.Storage/storageAccounts/stac01eu2iaacprd
*/