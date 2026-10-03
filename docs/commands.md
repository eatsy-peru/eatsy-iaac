cd infra\bootstrap\dev
cd infra\bootstrap\prd

terraform plan --var-file=../../common.tfvars

terraform apply --var-file=../../common.tfvars

terraform plan -out tf.plan

terraform show -no-color tf.plan > tfplan.txt


cd infra/bootstrap/prd

<!-- 
# Import Resource Group
terraform import module.bootstrap.azurerm_resource_group.main_rg /subscriptions/9a1cfce6-9caa-4bf2-8b7c-0ceaf0ddb179/resourceGroups/RSGR01EU2IAACPRD

# Import Key Vault
terraform import module.bootstrap.azurerm_key_vault.iaac /subscriptions/9a1cfce6-9caa-4bf2-8b7c-0ceaf0ddb179/resourceGroups/RSGR01EU2IAACPRD/providers/Microsoft.KeyVault/vaults/AKVT01EU2IAACPRD

# Import Storage Account
terraform import module.bootstrap.azurerm_storage_account.tfstate /subscriptions/9a1cfce6-9caa-4bf2-8b7c-0ceaf0ddb179/resourceGroups/RSGR01EU2IAACPRD/providers/Microsoft.Storage/storageAccounts/stac01eu2iaacprd 
-->
