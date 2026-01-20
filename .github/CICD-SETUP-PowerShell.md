# GitHub Actions Configuration for ZavaStorefront (PowerShell)

This guide explains how to configure GitHub secrets and variables for the automated deployment workflow using PowerShell commands.

## Prerequisites

- Azure infrastructure already deployed (via `azd up`)
- GitHub repository with the code
- Azure CLI installed locally
- PowerShell 5.1 or PowerShell 7+

## Step 1: Create Azure Service Principal

Create a service principal with Contributor access to your resource group:

```powershell
az ad sp create-for-rbac `
  --name "github-actions-zavastorefrontTechWorkshop-L300-GitHub-Copilot-and-platform" `
  --role Contributor `
  --scopes /subscriptions/{subscription-id}/resourceGroups/{resource-group-name} `
  --sdk-auth
```

Copy the entire JSON output. You'll use this in the next step.

## Step 2: Configure GitHub Secrets

Go to your GitHub repository → **Settings** → **Secrets and variables** → **Actions**.

### Create Secret

Click **New repository secret** and add:

| Name                | Value                             | Description                         |
| ------------------- | --------------------------------- | ----------------------------------- |
| `AZURE_CREDENTIALS` | `{...JSON output from Step 1...}` | Azure service principal credentials |

The JSON should look like:

```json
{
  "clientId": "<client-id>",
  "clientSecret": "<client-secret>",
  "subscriptionId": "<subscription-id>",
  "tenantId": "<tenant-id>"
}
```

## Step 3: Configure GitHub Variables

In the same location, click the **Variables** tab, then **New repository variable** for each:

| Name                       | Value                                 | How to Find                                                    |
| -------------------------- | ------------------------------------- | -------------------------------------------------------------- |
| `AZURE_WEBAPP_NAME`        | Your App Service name                 | Run: `az webapp list -g {rg-name} --query "[].name" -o tsv`   |
| `AZURE_RESOURCE_GROUP`     | Your resource group name              | Example: `rg-dev` or `rg-markenv`                              |
| `AZURE_CONTAINER_REGISTRY` | Your ACR name (without `.azurecr.io`) | Run: `az acr list -g {rg-name} --query "[].name" -o tsv`      |

### Quick Commands to Get Values

```powershell
# Set your resource group name
$RG_NAME = "rg-markenv"  # Replace with your actual resource group name

# Get App Service name
az webapp list -g $RG_NAME --query "[].name" -o tsv

# Get Container Registry name
az acr list -g $RG_NAME --query "[].name" -o tsv

# Get Resource Group (for verification)
Write-Output $RG_NAME
```

## Step 4: Grant ACR Permissions

Ensure the service principal has **AcrPush** permission:

```powershell
# Get the ACR resource ID
$ACR_ID = az acr show -n {acr-name} -g {rg-name} --query id -o tsv

# Get the service principal App ID (clientId from Step 1)
$SP_APP_ID = "<client-id-from-step-1>"

# Assign AcrPush role
az role assignment create `
  --assignee $SP_APP_ID `
  --role AcrPush `
  --scope $ACR_ID
```

## Step 5: Verify Configuration

After configuring secrets and variables:

1. Go to **Actions** tab in your GitHub repository
2. You should see the workflow "Build and Deploy to Azure App Service"
3. Click **Run workflow** to trigger a manual deployment
4. Monitor the workflow execution

## Workflow Trigger

The workflow runs automatically on:

- Every push to the `main` branch
- Manual trigger via GitHub Actions UI

## Troubleshooting

### Error: "az acr login" failed

- Verify the service principal has **AcrPush** role on the Container Registry
- Check that `AZURE_CONTAINER_REGISTRY` variable is the registry name (not the full URL)

### Error: "App Service not found"

- Verify `AZURE_WEBAPP_NAME` matches exactly (case-sensitive)
- Ensure `AZURE_RESOURCE_GROUP` is correct

### Error: Authentication failed

- Verify `AZURE_CREDENTIALS` secret contains valid JSON
- Ensure the service principal hasn't expired
- Check the service principal has Contributor role on the resource group

### Error: Image pull failed

- The App Service uses managed identity to pull images (not the service principal)
- Verify the managed identity has **AcrPull** role on ACR (already configured by Bicep)

## Security Notes

- The `AZURE_CREDENTIALS` secret contains sensitive information - never commit it to the repository
- The service principal should have minimal permissions (Contributor on resource group only)
- Consider using Azure Federated Credentials (OIDC) for passwordless authentication in production
- Rotate service principal credentials regularly

## Advanced: Using OIDC (Recommended for Production)

For enhanced security, consider migrating to OIDC-based authentication which doesn't require storing credentials. See: [Azure Login with OIDC](https://github.com/Azure/login#configure-a-service-principal-with-a-federated-credential-to-use-oidc-based-authentication)
