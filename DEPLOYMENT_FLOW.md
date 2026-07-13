# Deployment Flow: Bootstrap → Infrastructure

This document explains how the eatsy-iaac bootstrap integrates with the eatsy-azure-terraform repository.

## Architecture Overview

```
┌─────────────────────────────────────┐
│     GitHub Actions Workflows        │
│  (eatsy-azure-terraform repo)       │
└──────────────────┬──────────────────┘
                   │
                   │ Uses OIDC
                   ▼
        ┌─────────────────────┐
        │  Service Principal  │
        │  (SVPR01EU2DEV)     │
        │  from eatsy-iaac    │
        └─────────────────────┘
                   │
        ┌──────────┴──────────┐
        │                     │
        ▼                     ▼
   ┌─────────────┐     ┌──────────────────┐
   │ Key Vault   │     │ Storage Account  │
   │ (IAAC KV)   │     │ (tfstate)        │
   │             │     │                  │
   │ Secrets for │     │ Terraform state  │
   │ infra repos │     │ for all envs     │
   └─────────────┘     └──────────────────┘
         │
         │ Reads secrets
         ▼
   ┌──────────────────┐
   │ Infrastructure   │
   │ Deployment       │
   │ (in eatsy-azure- │
   │  terraform repo) │
   └──────────────────┘
```

## Two-Subscription Setup

```
┌──────────────────────────────────────────────────────────────────┐
│                    Azure Subscriptions                           │
├───────────────────────────┬───────────────────────────────────────┤
│  Subscription A (IAAC)    │  Subscription B (Deployment)          │
├───────────────────────────┼───────────────────────────────────────┤
│                           │                                       │
│  This repo (eatsy-iaac):  │  eatsy-azure-terraform deploys to:  │
│  ├─ Key Vault             │  ├─ Resource Groups                 │
│  │  └─ Secrets from       │  ├─ Networking                      │
│  │    infrastructure repos │  ├─ Compute                         │
│  └─ Storage Account        │  └─ Other resources                 │
│     └─ Terraform state     │                                       │
│        (all envs)          │  Service Principal needs Reader      │
│                            │  access here to run terraform plan  │
│                            │                                       │
└───────────────────────────┴───────────────────────────────────────┘
```

## Deployment Sequence

### Phase 1: Bootstrap (eatsy-iaac repo)

**When**: Once, per environment, before any infrastructure deployments

**What happens**:
1. Create resource groups (manual or via separate script)
2. Deploy eatsy-iaac bootstrap:
   ```powershell
   cd infra/bootstrap/dev
   terraform apply
   ```
3. Outputs:
   - Key Vault name: `AKVT01EU2DEV`
   - Storage Account name: `stac01eu2dev`
   - Service Principal ID & Client ID

**Result**: Shared infrastructure is ready

### Phase 2: Store Secrets (manually or via script)

**When**: After bootstrap, before first infrastructure deployment

**What happens**:
1. Populate Key Vault with secrets:
   ```powershell
   az keyvault secret set \
     --vault-name "AKVT01EU2DEV" \
     --name "sql-admin-password" \
     --value "your-secret-password"
   ```
2. Secrets needed by infrastructure deployments:
   - Database credentials
   - API keys
   - Registry tokens
   - etc.

**Result**: Secrets available for infrastructure Terraform

### Phase 3: Infrastructure Deployment (eatsy-azure-terraform repo)

**When**: Continuously, as you develop and deploy

**Prerequisites**:
- Bootstrap completed (Phase 1)
- Secrets populated (Phase 2)
- Deployment resource groups created

**What happens**:
1. GitHub Actions workflow triggers
2. Authenticates using OIDC federated credential:
   ```yaml
   - uses: azure/login@v1
     with:
       client-id: ${{ secrets.AZURE_CLIENT_ID }}
       tenant-id: ${{ secrets.AZURE_TENANT_ID }}
       subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
   ```
3. Service principal reads from:
   - Key Vault (for secrets)
   - Terraform state (to understand current state)
4. Terraform plans changes:
   ```powershell
   terraform plan -var-file=envs/dev/terraform.tfvars
   ```
5. Terraform applies changes:
   ```powershell
   terraform apply
   ```
6. State is stored in Storage Account

## Important: Separation of Concerns

### eatsy-iaac (This Repo)
**Manages**: Bootstrap infrastructure only
- Key Vault container
- Storage Account container
- Managed Identity

**Does NOT manage**:
- Key Vault secrets (managed by eatsy-azure-terraform or manually)
- Storage Account blobs (managed by Terraform itself)
- Any workload infrastructure

### eatsy-azure-terraform (Separate Repo)
**Manages**: All workload infrastructure
- Resource groups
- Networking
- Databases
- Compute
- etc.

**Uses**: Outputs from eatsy-iaac
- Key Vault for reading secrets
- Storage Account for storing state

## GitHub Secrets Configuration

GitHub Actions secrets are **automatically managed by Terraform**. When you deploy the bootstrap in `eatsy-iaac`, the `github_actions_environment_secret` resources automatically create these secrets, scoped to the appropriate environment (`dev` or `prd`):

| Secret | Repositories | Managed By | Purpose |
|--------|-------------|-----------|---------|
| `AZURE_CLIENT_ID` | eatsy-iaac, eatsy-azure-terraform | `modules/bootstrap/github_secrets.tf` | OIDC login for both repos |
| `AZURE_TENANT_ID` | eatsy-iaac, eatsy-azure-terraform | `modules/bootstrap/github_secrets.tf` | OIDC login for both repos |
| `AZURE_SUBSCRIPTION_ID` | eatsy-iaac, eatsy-azure-terraform | `modules/bootstrap/github_secrets.tf` | OIDC login for both repos |
| `KEY_VAULT_NAME` | **eatsy-iaac only** | `modules/bootstrap/github_secrets.tf` | Bootstrap Key Vault access |
| `CERTS_STORAGE_ACCOUNT_NAME` | **eatsy-iaac only** | `modules/bootstrap/github_secrets.tf` | Certificate blob storage access |

**No manual setup required** — just run `terraform apply` in the bootstrap stack and the secrets are pushed automatically.

## Example GitHub Actions Workflow

In **eatsy-azure-terraform** repo (`.github/workflows/deploy.yml`):

```yaml
name: Deploy Infrastructure

on:
  push:
    branches: [main]

permissions:
  id-token: write
  contents: read

jobs:
  deploy:
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v3
      
      - name: Azure Login
        uses: azure/login@v1
        with:
          client-id: ${{ secrets.AZURE_CLIENT_ID }}
          tenant-id: ${{ secrets.AZURE_TENANT_ID }}
          subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
      
      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v2
        with:
          terraform_version: 1.5.0
      
      - name: Terraform Init
        run: |
          cd infra/envs/dev
          terraform init
      
      - name: Terraform Plan
        run: |
          cd infra/envs/dev
          terraform plan -out=tfplan
      
      - name: Terraform Apply
        if: github.ref == 'refs/heads/main'
        run: |
          cd infra/envs/dev
          terraform apply tfplan
```

## Updating Bootstrap Resources

If you need to change bootstrap configuration (e.g., add new repos):

1. Update `infra/bootstrap/{env}/terraform.tfvars`
2. Run `terraform plan` to see changes
3. Run `terraform apply`
4. Existing resources are not replaced, just updated

### Adding a New Repository to Federated Credentials

1. In `infra/bootstrap/dev/terraform.tfvars`:
   ```hcl
   github_repository_names = [
     "eatsy-azure-terraform",
     "eatsy-iaac",
     "new-repo-name",  # Add here
   ]
   ```

2. Deploy:
   ```powershell
   cd infra/bootstrap/dev
   terraform apply
   ```

3. New federated credentials are created automatically

## Troubleshooting Deployment Failures

### Error: "No secret found in Key Vault"

**Cause**: Secrets haven't been populated yet

**Fix**:
```powershell
# Populate required secrets
az keyvault secret set \
  --vault-name "AKVT01EU2DEV" \
  --name "secret-name" \
  --value "secret-value"
```

### Error: "Unauthorized to read Key Vault"

**Cause**: Service principal doesn't have Key Vault Secrets User role

**Verify**:
```powershell
az role assignment list \
  --all \
  --assignee "SVPR01EU2DEV" \
  --scope "/subscriptions/IAAC-SUB-ID/resourceGroups/RGE01EU2DEV/providers/Microsoft.KeyVault/vaults/AKVT01EU2DEV"
```

### Error: "Cannot read Terraform state"

**Cause**: Service principal doesn't have Storage Blob Data Contributor role

**Verify**:
```powershell
az role assignment list \
  --all \
  --assignee "SVPR01EU2DEV" \
  --scope "/subscriptions/IAAC-SUB-ID/resourceGroups/RGE01EU2DEV/providers/Microsoft.Storage/storageAccounts/stac01eu2dev"
```

## Security Best Practices

1. **Never commit secrets**: They go in Key Vault, not in code
2. **Use federated credentials**: No secrets in GitHub, OIDC handles auth
3. **Limit role scope**: Service principal gets only needed roles
4. **Audit access**: Monitor Key Vault and storage account access
5. **Rotate credentials**: Periodically review and rotate sensitive items

## Disaster Recovery

### If Service Principal is Compromised

1. Create a new app registration in eatsy-iaac bootstrap
2. Update federated credentials to point to new registration
3. Remove old service principal
4. Update GitHub secrets with new client ID

### If Key Vault is Deleted

1. Key Vault has soft-delete enabled (7-day retention)
2. Recover: `az keyvault recover --name "AKVT01EU2DEV"`
3. If hard-deleted, recreate via bootstrap and restore secrets

### If Storage Account is Deleted

1. Recover from soft-delete (enabled by default)
2. If hard-deleted, recreate via bootstrap
3. Terraform state can be restored from backups if configured

## Cost Optimization

- **Key Vault**: ~$0.60/month (standard SKU)
- **Storage Account**: ~$0.25/month for tfstate (minimal usage)
- **Service Principal**: No direct cost

Total: ~$1/month for bootstrap infrastructure

## Next Steps

1. Complete Phase 1: Deploy bootstrap
2. Complete Phase 2: Populate secrets
3. Create infrastructure repository with Phase 3 deployment
4. Monitor deployments and audit access

---

For detailed setup instructions, see [SETUP.md](./SETUP.md)
