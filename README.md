# Eatsy IAAC Bootstrap

This repository manages the bootstrap infrastructure for Eatsy's Infrastructure-as-Code platform. It creates and maintains:

- **Key Vault**: Container-level management only (secrets are managed by other repositories)
- **Storage Account**: For Terraform state storage, container-level management only (blobs managed elsewhere)
- **Managed Identity**: Azure AD application, service principal, and federated credentials for GitHub Actions OIDC authentication

## Scope

This bootstrap configuration is **intentionally minimal** and focused on:

1. Creating the shared infrastructure components
2. Setting up GitHub Actions OIDC authentication via federated credentials
3. Granting necessary IAM roles to the identity for:
   - Reading resource groups (Reader role on deployment RGs)
   - Managing Key Vault secrets (Key Vault Secrets User on IAAC KV)
   - Accessing Terraform state (Storage Blob Data Contributor on tfstate storage)
   - Reading Entra ID directory (Directory Readers role)

## Prerequisites

Before applying this configuration:

1. Create resource groups for Key Vault and Storage Account
   - Example: `RGE01EU2DEV` for dev, `RGE01EU2PRD` for production
2. Have subscription IDs and resource group IDs ready
3. Authenticated with Azure CLI (`az login` or federated identity)

## Structure

```
infra/bootstrap/
├── dev/                          # Development environment
│   ├── providers.tf             # Provider configuration
│   ├── variables.tf             # Input variables
│   ├── main.tf                  # Module invocation
│   ├── outputs.tf               # Output definitions
│   ├── terraform.tfvars         # Environment-specific values
│   └── backend.tf               # State backend configuration
└── prd/                          # Production environment
    ├── providers.tf
    ├── variables.tf
    ├── main.tf
    ├── outputs.tf
    ├── terraform.tfvars
    └── backend.tf

modules/bootstrap/                # Reusable bootstrap module
├── providers.tf                 # Provider definitions
├── variables.tf                 # Input variable definitions
├── locals.tf                    # Local values
├── main.tf                      # Data sources
├── keyvault.tf                  # Key Vault resource
├── storage.tf                   # Storage Account resource
├── identity.tf                  # App registration, SP, federated credentials, IAM
└── outputs.tf                   # Output definitions
```

## Usage

### Development Environment

1. Update `infra/bootstrap/dev/terraform.tfvars`:
   - Set resource group names
   - Set GitHub repositories list
   - Set deployment resource group IDs
   - Update location and location_short if needed

2. Initialize Terraform:
   ```powershell
   cd infra/bootstrap/dev
   terraform init
   ```

3. Review the plan:
   ```powershell
   terraform plan
   ```

4. Apply the configuration:
   ```powershell
   terraform apply
   ```

### Production Environment

Same process as development, but use `infra/bootstrap/prd/`:

```powershell
cd infra/bootstrap/prd
terraform init
terraform plan
terraform apply
```

## Configuration Variables

### Key Variables

- `app_code`: Application code (e.g., "EST" for Eatsy)
- `environment`: Environment name ("dev", "prd")
- `location`: Azure region (e.g., "eastus2")
- `location_short`: Region short code (e.g., "eus2")
- `github_owner`: GitHub organization (e.g., "eatsy-peru")
- `github_repository_names`: List of repositories needing federated credentials

## Outputs

After applying, you'll get outputs for:

- **Key Vault**: Name, ID, URI
- **Storage Account**: Name, ID, endpoint
- **Managed Identity**: App registration ID, client ID, service principal ID
- **Federated Credentials**: Map of created credentials with subjects

## GitHub Actions Integration

The federated credentials created by this configuration allow GitHub Actions to authenticate without storing secrets:

```yaml
- name: Azure Login
  uses: azure/login@v1
  with:
    client-id: ${{ secrets.AZURE_CLIENT_ID }}
    tenant-id: ${{ secrets.AZURE_TENANT_ID }}
    subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
```

The service principal automatically gets these roles:
- **Reader** on all specified deployment resource groups
- **Key Vault Secrets User** on the IAAC Key Vault
- **Storage Blob Data Contributor** on the tfstate storage account
- **Directory Readers** on the Entra ID directory

## Important Notes

- **Key Vault management**: This config only creates the Key Vault container. Secrets are managed by other repositories.
- **Storage management**: This config only creates the Storage Account container. State files and blobs are managed by Terraform and other systems.
- **Resource groups**: Resource groups must exist before applying. Create them manually or via a separate configuration.
- **State isolation**: Each environment's state is isolated in separate containers/keys for safety.

## Future Deployments

To deploy to a new environment:

1. Copy `infra/bootstrap/dev/` to a new directory (e.g., `infra/bootstrap/staging/`)
2. Update `terraform.tfvars` with environment-specific values
3. Update `backend.tf` with new storage account details
4. Run `terraform init` → `terraform plan` → `terraform apply`

## Related Documentation

- [Azure Key Vault Documentation](https://learn.microsoft.com/en-us/azure/key-vault/)
- [GitHub Actions OIDC with Azure](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/about-security-hardening-with-openid-connect)
- [Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
