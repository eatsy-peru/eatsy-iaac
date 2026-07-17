# IAAC Bootstrap Setup Guide

This guide walks you through setting up the Eatsy IAAC bootstrap infrastructure.

## Overview

The bootstrap creates:
1. **Key Vault** - Manages the container only, not secrets inside
2. **Storage Account** - For Terraform state, manages container only, not blobs
3. **Managed Identity** - Azure AD app + service principal with GitHub Actions OIDC integration

## Prerequisites

### Azure Setup

1. **Subscriptions**: You need 2 subscriptions:
   - **IAAC Subscription (Subscription A)**: Where Key Vault and tfstate storage live
   - **Deployment Subscription (Subscription B)**: Where your actual infrastructure deploys

2. **Resource Groups**: Create resource groups beforehand:
   - For dev: `RGE01EU2DEV` (in IAAC subscription)
   - For prd: `RGE01EU2PRD` (in IAAC subscription)
   - Create any deployment RGs in Subscription B that need Reader access

3. **Authentication**: Ensure you're authenticated to the IAAC subscription:
   ```powershell
   az login
   az account set --subscription "IAAC-Subscription-ID"
   ```

### Tools

- Terraform >= 1.5
- Azure CLI
- PowerShell (optional, for helper scripts)

## Step 1: Update Development Configuration

Edit `infra/bootstrap/dev/terraform.tfvars`:

```hcl
app_code    = "EST"                    # Your app code
environment = "dev"                    # Environment name
location    = "eastus2"                # Azure region
location_short = "eus2"                # Region short code

github_owner = "eatsy-peru"            # Your GitHub org

# All repos that will use GitHub Actions OIDC
github_repository_names = [
  "eatsy-azure-terraform",
  "eatsy-iaac",
  "eatsy-back-java-monolith",
  # Add others as needed
]

Find subscription and resource group IDs:

```powershell
# Get current subscription ID
az account show --query id -o tsv

# Get resource group IDs
az group show --name "RGE01EU2DEV" --query id -o tsv
```

## Step 2: Initialize and Deploy Dev

```powershell
cd infra/bootstrap/dev

# Initialize Terraform (creates .terraform directory)
terraform init

# Review what will be created
terraform plan -out=tfplan

# Apply the configuration
terraform apply tfplan
```

This creates:
- Key Vault: `AKVT01EU2DEV`
- Storage Account: `stac01eu2dev`
- App Registration: `SVPR01EU2DEV-GitHub`
- Service Principal with federated credentials for all repos

## Step 3: Update Production Configuration

Edit `infra/bootstrap/prd/terraform.tfvars`:

```hcl
app_code    = "EST"
environment = "prd"                    # Change to "prd"
location    = "eastus2"
location_short = "eus2"

github_owner = "eatsy-peru"

github_repository_names = [
  "eatsy-azure-terraform",
  "eatsy-iaac",
  "eatsy-back-java-monolith",
]

## Step 4: Deploy Production

```powershell
cd infra/bootstrap/prd

terraform init
terraform plan -out=tfplan
terraform apply tfplan
```

## Verify Deployment

Check that resources were created:

```powershell
# Check Key Vault
az keyvault show --name "AKVT01EU2DEV"

# Check Storage Account
az storage account show --name "stac01eu2dev" --resource-group "RGE01EU2DEV"

# Check App Registration
az ad app list --display-name "SVPR01EU2DEV-GitHub"

# Check Service Principal
az ad sp list --display-name "SVPR01EU2DEV-GitHub"
```

## GitHub Actions Setup

GitHub Actions secrets are **automatically configured** by Terraform when you deploy the bootstrap:

**Automated secrets:**

On **both `eatsy-iaac` and `eatsy-azure-terraform` repos** (repository secrets — same tenant/subscription for dev and prd, not scoped to an environment):
- `AZURE_TENANT_ID` — Azure tenant ID
- `AZURE_IAAC_SUBSCRIPTION_ID` — deployment subscription ID

On **both `eatsy-iaac` and `eatsy-azure-terraform` repos** (environment secret, scoped to `dev` or `prd` — differs per environment since each has its own service principal):
- `AZURE_IAAC_CLIENT_ID` — bootstrap service principal client ID

On **`eatsy-iaac` repo only** (bootstrap-specific, environment secrets):
- `IAAC_KEY_VAULT_NAME` — bootstrap Key Vault name for secret storage
- `IAAC_CERTS_STORAGE_ACCOUNT_NAME` — storage account name for certificate management

These are created by the `github_actions_secret` and `github_actions_environment_secret` resources in `modules/bootstrap/github_secrets.tf`. No manual steps required after `terraform apply`!

**Use in GitHub Actions**:
```yaml
- name: Azure Login
  uses: azure/login@v2
  with:
    client-id: ${{ secrets.AZURE_IAAC_CLIENT_ID }}
    tenant-id: ${{ secrets.AZURE_TENANT_ID }}
    subscription-id: ${{ secrets.AZURE_IAAC_SUBSCRIPTION_ID }}
```

## Understanding the IAM Roles

The service principal gets these roles automatically:

### Reader on Deployment Resource Groups
- Allows Terraform to read existing resources during `terraform plan`
- Scoped to each deployment RG you specify

### Key Vault Secrets User
- Allows reading secrets from the IAAC Key Vault
- Enables `terraform plan` to read stored credentials

### Storage Blob Data Contributor
- Allows reading and writing Terraform state files
- Enables `terraform init` with `use_azuread_auth = true`

### Directory Readers
- Allows the identity to read Entra ID directory
- Required for state to include app registration objects

## Troubleshooting

### "Role not found" error

If you get an error about a role not being found:
- Verify the role name is correct
- Some roles take a few minutes to propagate
- Try again after a brief wait

### "Key Vault not found" error

- Ensure the resource group exists
- Ensure you're authenticated to the correct subscription

### Backend authentication errors

If `terraform init` fails with authentication errors:
- Ensure the storage account exists
- Verify you have Storage Blob Data Contributor on the storage account
- Try: `terraform init -reconfigure`

## Updating Repositories in Federated Credentials

If you need to add a new repository to GitHub Actions OIDC:

1. Update `github_repository_names` in `terraform.tfvars`
2. Run `terraform plan` to see new credentials
3. Run `terraform apply`
4. No existing credentials are affected

## Cleanup

To remove all bootstrap resources:

```powershell
cd infra/bootstrap/dev
terraform destroy

# Then manually delete the state file from storage if desired
az storage blob delete --account-name "stac01eu2dev" \
  --container-name "tfstate-bootstrap" \
  --name "dev.tfstate"
```

## Next Steps

After bootstrap is complete:

1. Create your environment infrastructure (networking, compute, etc.) in a separate repository
2. Use the outputs from bootstrap (Key Vault name, Storage Account name) in your infrastructure config
3. Store infrastructure secrets in the Key Vault created by bootstrap
4. Use the service principal credentials for GitHub Actions workflows

## Support

For issues or questions:
- Check Azure Portal for resource details
- Review Terraform state: `terraform state show`
- Check Azure CLI documentation: `az --help`
