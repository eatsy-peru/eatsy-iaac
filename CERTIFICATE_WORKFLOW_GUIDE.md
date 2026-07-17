# Certificate Management Workflow Guide

This guide explains how to use the GitHub Actions workflow to create certificates and store them as secrets in Azure Key Vault.

## Prerequisites

### 1. GitHub Secrets Configuration

The workflow requires these secrets to be set in the **`eatsy-iaac` repository** as **environment secrets** (per `dev` / `prd` environment):

**Required for this workflow:**
- **`IAAC_KEY_VAULT_NAME`**: The bootstrap Key Vault name for storing certificate secrets
- **`IAAC_CERTS_STORAGE_ACCOUNT_NAME`**: The storage account name for certificate blob storage
- **`AZURE_TENANT_ID`**: Your Azure tenant ID (used for OIDC login)
- **`AZURE_IAAC_CLIENT_ID`**: The GitHub OIDC service principal client ID (used for OIDC login)
- **`AZURE_IAAC_SUBSCRIPTION_ID`**: Your Azure subscription ID (used for OIDC login)

These are **automatically created by Terraform** when you deploy the bootstrap module (`terraform apply` in `infra/bootstrap/{dev,prd}`). No manual configuration needed!

Note: The `IAAC_KEY_VAULT_NAME` and `IAAC_CERTS_STORAGE_ACCOUNT_NAME` secrets are **only pushed to the `eatsy-iaac` repo** — they are bootstrap infrastructure secrets and not shared with other repositories.

### 2. Azure Configuration

Your Azure infrastructure (managed by the bootstrap Terraform module) should already have:

- ✅ Storage Account with a `certs` blob container (private access)
- ✅ Key Vault created with RBAC authorization enabled
- ✅ GitHub Actions service principal with:
  - "Storage Blob Data Contributor" role (for reading certificates from blob storage)
  - "Key Vault Secrets Officer" role (for storing secrets)
- ✅ Federated identity credentials configured for your repository

### 3. Upload Certificate Files to Blob Storage

Upload your `.pem` and `.key` files to the Azure Storage Account's `certs` container:

```bash
# Example using Azure CLI
az storage blob upload \
  --account-name "stac01usteatsydev" \
  --container-name "certs" \
  --name "myapp/cert.pem" \
  --file /path/to/cert.pem \
  --auth-mode login

az storage blob upload \
  --account-name "stac01usteatsydev" \
  --container-name "certs" \
  --name "myapp/key.key" \
  --file /path/to/key.key \
  --auth-mode login
```

Or use Azure Portal → Storage Account → Containers → certs → Upload

## How to Use

### Step 1: Upload Certificate Files to Blob Storage

Before running the workflow, upload your certificate files to the `certs` blob container in your environment's storage account.

**Find your storage account name:**
```bash
# Format: stac01{location}{app_code}{environment} (lowercase)
# Example: stac01usteatsydev
az storage account list --query "[?tags.Environment=='DEV'].name" -o tsv
```

**Upload files using Azure CLI:**
```bash
az storage blob upload \
  --account-name "stac01usteatsydev" \
  --container-name "certs" \
  --name "myapp/cert.pem" \
  --file /local/path/to/cert.pem \
  --auth-mode login

az storage blob upload \
  --account-name "stac01usteatsydev" \
  --container-name "certs" \
  --name "myapp/key.key" \
  --file /local/path/to/key.key \
  --auth-mode login
```

### Step 2: Trigger the Workflow

1. Go to **Actions** tab in your GitHub repository
2. Select **"Create Certificate and Store as KeyVault Secrets"**
3. Click **"Run workflow"**
4. Fill in the required inputs:

| Input | Example | Description |
|-------|---------|-------------|
| **Environment** | `dev`, `prd` | Target Azure environment |
| **Secret Prefix** | `myapp-ssl-cert` | Prefix for all secret names |
| **PEM Blob Name** | `myapp/cert.pem` | Path within `certs` container |
| **Key Blob Name** | `myapp/key.key` | Path within `certs` container |
| **PFX Password** | (your password) | Password to protect the PFX file |
| **Delete Certificate Files** | `true` (default) | Automatically delete the PEM and KEY files from blob storage after processing |

### Step 3: Verify Secrets

After the workflow completes successfully:

1. Go to your Azure Key Vault in the selected environment
2. Verify these secrets were created:
   - `{prefix}-b64-pem` — Base64-encoded PEM certificate
   - `{prefix}-b64-key` — Base64-encoded private key
   - `{prefix}-b64-pfx` — Base64-encoded PFX certificate
   - `{prefix}-pfx-pass` — Password for the PFX file

## Workflow Steps Explained

### 1. **Azure Login**
   - Authenticates to Azure using OIDC federated identity (no credentials needed!)

### 2. **Store secrets in variables**
   - Reads `IAAC_KEY_VAULT_NAME` and `IAAC_CERTS_STORAGE_ACCOUNT_NAME` from GitHub environment secrets
   - These are automatically set by Terraform when you deploy the bootstrap
   - Validates both are configured (exits if missing)

### 3. **Download from Blob Storage**
   - Retrieves PEM and KEY files from the `certs` blob container
   - Uses RBAC authentication (no connection strings needed)
   - Validates files were downloaded successfully

### 4. **PFX Creation**
   - Uses OpenSSL to create a PFX file from the downloaded PEM + KEY files
   - PFX combines certificate and private key with password protection

### 5. **Base64 Encoding**
   - Encodes PEM, KEY, and PFX to base64 for storage as Key Vault secrets
   - Key Vault secret values have size limits (~80KB), but base64 is standard for binary data

### 6. **Key Vault Storage**
   - Uses the `IAAC_KEY_VAULT_NAME` secret to reference the correct Key Vault
   - Creates four secrets with the specified prefix

### 7. **Delete Certificate Files from Blob Storage** (optional, enabled by default)
   - If "Delete Certificate Files" is checked (enabled by default), removes the PEM and KEY files from the `certs` blob container
   - This ensures the original files don't remain in storage after being processed
   - Useful for security — you can re-upload new files for the next certificate creation without managing old ones

### 8. **Cleanup**
   - Deletes all temporary files from the runner (PEM, KEY, PFX)
   - Clears sensitive environment variables

## Retrieving Secrets from Other Workflows

Once stored in Key Vault, you can retrieve these secrets in other GitHub Actions workflows:

```yaml
- name: Get certificate from Key Vault
  run: |
    az keyvault secret show \
      --vault-name "AKVT01USTEATSYDEV" \
      --name "myapp-ssl-cert-b64-pem" \
      --query value -o tsv
```

## Decoding Base64 Secrets in Applications

When using these secrets in your applications:

### Node.js/TypeScript
```typescript
const pemB64 = process.env.CERT_PEM_B64;
const pem = Buffer.from(pemB64, 'base64').toString('utf8');
```

### Python
```python
import base64
pem_b64 = os.environ['CERT_PEM_B64']
pem = base64.b64decode(pem_b64).decode('utf-8')
```

### Bash/Shell
```bash
echo "$PEM_B64" | base64 -d > certificate.pem
```

## Troubleshooting

### "IAAC_KEY_VAULT_NAME secret not configured" or "IAAC_IAAC_CERTS_STORAGE_ACCOUNT_NAME secret not configured"
- Verify you've deployed the bootstrap Terraform stack: `cd infra/bootstrap/{dev,prd} && terraform apply`
- Confirm you set `GITHUB_TOKEN` environment variable when running Terraform (needed for `github_actions_environment_secret` resources)
- Check GitHub UI: Repo Settings → Environments → {dev,prd} → Secrets to verify they were created
- If missing, run `terraform apply` again to push the secrets

### "Failed to download PEM/KEY file from blob storage"
- Verify the blob names are correct (case-sensitive)
- Check that files exist in the `certs` container:
  ```bash
  az storage blob list --account-name "stac01usteatsydev" --container-name "certs"
  ```
- Ensure the GitHub service principal has "Storage Blob Data Contributor" role
- Try uploading files again with correct paths

### "Key Vault not found for environment"
- Verify the environment name matches your Terraform configuration
- Check that the Key Vault has the correct `Environment` tag

### "Azure login failed"
- Verify `AZURE_TENANT_ID`, `AZURE_IAAC_CLIENT_ID`, and `AZURE_IAAC_SUBSCRIPTION_ID` are set correctly
- Confirm the GitHub OIDC credential is configured for this repository
- Check that the service principal has "Key Vault Secrets Officer" role

### "Failed to create PFX file"
- Ensure the PEM and KEY files are valid
- Verify the key is not encrypted (or decrypt it first)
- Check that the downloaded files are not corrupted

### "Permission denied" when setting secrets
- Verify the GitHub service principal has "Key Vault Secrets Officer" role on the Key Vault
- Check that Key Vault RBAC authorization is enabled (not Access Policies)

### Blob files not deleted despite "Delete Certificate Files" being enabled
- Verify the GitHub service principal has "Storage Blob Data Contributor" role (it already needs this to download files)
- The workflow will not fail if deletion fails — check the logs for "⚠ file deletion skipped" messages
- Files may have been deleted already, or they may not exist at the specified blob path
- To manually delete: `az storage blob delete --account-name "<storage>" --container-name "certs" --name "<blob-name>"`

## Security Considerations

✅ **Best Practices Implemented:**
- Uses OIDC federated credentials (no long-lived secrets)
- Sensitive files cleaned up after use (local runner files)
- Passwords masked in GitHub Actions logs
- RBAC-based access control via Azure
- **Certificate files auto-deleted from blob storage** (enabled by default) — prevents accumulation of old certificate files

🔐 **Additional Recommendations:**
- Store certificate files in a private repository or use separate storage
- Regularly rotate certificates
- Monitor Key Vault access via Azure audit logs
- Use environment protection rules to require approvals for production deployments

## Extending the Workflow

### Custom Key Vault Name
If your naming convention differs, modify the `Get KeyVault name` step:

```bash
# Replace this query with your specific naming pattern
keyvault_name=$(az keyvault list \
  --query "[?tags.Environment=='${environment_upper}' && contains(name, 'AKVT01')].name" \
  -o tsv | head -1)
```

### Adding Certificate Validation
Add a validation step after PFX creation:

```bash
openssl pkcs12 -info -in certificate.pfx -password pass:"${{ github.event.inputs.pfx_password }}" -noout
```

### Tagging Secrets
Modify the secret creation to add tags/metadata (requires Azure CLI):

```bash
az keyvault secret set \
  --vault-name "${keyvault_name}" \
  --name "${prefix}-b64-pem" \
  --value "${PEM_B64}" \
  --tags source=github-actions automated=true
```
