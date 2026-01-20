# ZavaStorefront Deployment Guide

## Overview

This guide provides step-by-step instructions for deploying the ZavaStorefront web application to Azure using Azure Developer CLI (azd) and Bicep Infrastructure as Code.

## Prerequisites

### Required Tools

1. **Azure Developer CLI (azd)**

   ```bash
   # Windows (PowerShell)
   winget install microsoft.azd

   # Verify installation
   azd version
   ```

2. **Azure CLI**

   ```bash
   # Windows (PowerShell)
   winget install Microsoft.AzureCLI

   # Verify installation
   az --version
   ```

3. **Docker Desktop** (for local testing - optional)
   - Download from https://www.docker.com/products/docker-desktop/

### Azure Requirements

- Active Azure subscription
- Permissions to:
  - Create resource groups
  - Create Azure resources (App Service, Container Registry, etc.)
  - Assign roles (RBAC)

## Deployment Steps

### Step 1: Authenticate to Azure

```bash
# Login to Azure
azd auth login

# Verify login
az account show
```

### Step 2: Initialize AZD Environment

From the project root directory:

```bash
# Initialize azd (if not already done)
azd init

# Create a new environment
azd env new dev

# Set the Azure location
azd env set AZURE_LOCATION westus3
```

### Step 3: Preview Infrastructure Changes

Before deploying, preview what resources will be created:

```bash
azd provision --preview
```

Review the output to ensure all expected resources are listed:

- Resource Group
- User-Assigned Managed Identity
- Azure Container Registry
- App Service Plan
- App Service (Web App)
- Application Insights
- Log Analytics Workspace
- Microsoft Foundry (AI Services)

### Step 4: Deploy Infrastructure and Application

Deploy everything with a single command:

```bash
azd up
```

This command will:

1. Provision all Azure infrastructure
2. Build the Docker container image
3. Push the image to Azure Container Registry
4. Deploy the container to App Service

**Expected duration**: 10-15 minutes

### Step 5: Verify Deployment

After deployment completes, you'll see output including:

```
SUCCESS: Your application was provisioned and deployed to Azure in X minutes Y seconds.

Deployed resources:
  Resource group: rg-dev
  Web app: https://azapp{token}.azurewebsites.net
```

**Test the application**:

1. Click the web app URL or visit it in your browser
2. Verify the ZavaStorefront homepage loads
3. Test cart functionality

### Step 6: Monitor the Application

View application logs:

```bash
# Stream live logs
azd monitor --logs

# Or use Azure CLI
az webapp log tail --name <WEB_APP_NAME> --resource-group <RESOURCE_GROUP_NAME>
```

Access Application Insights:

1. Go to Azure Portal
2. Navigate to your resource group
3. Open Application Insights
4. View Live Metrics, Performance, and Failures

## Configuration

### Environment Variables

Set additional environment variables if needed:

```bash
azd env set ASPNETCORE_ENVIRONMENT Production
```

### Application Settings

Update App Service configuration:

```bash
az webapp config appsettings set \
  --name <WEB_APP_NAME> \
  --resource-group <RESOURCE_GROUP_NAME> \
  --settings KEY=VALUE
```

## Local Development

### Build and Run Docker Container Locally

```bash
cd src

# Build the Docker image
docker build -t zavastorefrontweb:local .

# Run the container
docker run -p 8080:80 zavastorefrontweb:local

# Access at http://localhost:8080
```

### Test Before Deploying

Always test Docker images locally before pushing to Azure:

```bash
# Build
docker build -t zavastorefrontweb:test ./src

# Run
docker run -p 8080:80 zavastorefrontweb:test

# Test in browser
# Then deploy with azd up
```

## Updating the Application

### Deploy Code Changes

After making code changes:

```bash
# Rebuild and redeploy
azd deploy
```

This will:

1. Build new Docker image
2. Push to Container Registry
3. Restart App Service with new image

### Update Infrastructure

If you modify Bicep files:

```bash
# Preview infrastructure changes
azd provision --preview

# Apply changes
azd provision
```

## Troubleshooting

### Issue: Container fails to start

**Solution**: Check App Service logs

```bash
az webapp log tail --name <WEB_APP_NAME> --resource-group <RESOURCE_GROUP_NAME>
```

Common causes:

- Port mismatch (ensure Dockerfile EXPOSE matches App Service configuration)
- Missing environment variables
- Application startup errors

### Issue: Cannot pull from Container Registry

**Solution**: Verify managed identity permissions

```bash
# Check role assignments
az role assignment list --scope /subscriptions/{subscription-id}/resourceGroups/{rg-name}/providers/Microsoft.ContainerRegistry/registries/{acr-name}
```

Ensure User-Assigned Managed Identity has `AcrPull` role.

### Issue: Application Insights not receiving data

**Solution**: Verify connection string

```bash
# Check app settings
az webapp config appsettings list --name <WEB_APP_NAME> --resource-group <RESOURCE_GROUP_NAME>
```

Ensure `APPLICATIONINSIGHTS_CONNECTION_STRING` is set correctly.

### Issue: Foundry models not accessible

**Solution**: Check role assignments

```bash
# Verify Cognitive Services User role
az role assignment list --scope /subscriptions/{subscription-id}/resourceGroups/{rg-name}/providers/Microsoft.CognitiveServices/accounts/{foundry-name}
```

## Environment Management

### List Environments

```bash
azd env list
```

### Switch Environments

```bash
azd env select <environment-name>
```

### Delete Environment

```bash
azd down
```

This removes all Azure resources but keeps local environment configuration.

### Complete Cleanup

```bash
# Remove Azure resources
azd down --purge

# Remove local environment
azd env remove <environment-name>
```

## CI/CD Integration

### GitHub Actions (Future)

To set up automated deployments:

```bash
azd pipeline config
```

This will:

1. Create a service principal
2. Set up GitHub secrets
3. Generate GitHub Actions workflow

## Cost Management

### Monitor Costs

1. Azure Portal → Cost Management + Billing
2. Filter by resource group: `rg-{environmentName}`
3. View daily breakdown

### Optimize Costs

**For development**:

- Use B1 (Basic) instead of B2 for App Service Plan
- Stop App Service when not in use:
  ```bash
  az webapp stop --name <WEB_APP_NAME> --resource-group <RESOURCE_GROUP_NAME>
  ```

**For production**:

- Consider P1V2 or P2V2 (Premium) for better performance
- Enable autoscaling
- Use retention policies for logs

## Security Best Practices

### Implemented

✅ HTTPS enforcement (TLS 1.2+)
✅ Managed Identity for authentication
✅ RBAC-only (no admin passwords)
✅ Disabled anonymous pull on ACR
✅ Application Insights for monitoring
✅ Disabled local auth for storage

### Recommendations

- Enable Azure Key Vault for secrets management
- Configure network restrictions (VNet integration)
- Enable Microsoft Defender for Cloud
- Implement Azure Front Door for WAF
- Configure backup and disaster recovery

## Additional Commands

### View Deployment History

```bash
az deployment sub list --query "[?name=='zavastorefrontTechWorkshop-L300-GitHub-Copilot-and-platform-deployment']"
```

### Get Resource URLs

```bash
# Get outputs from deployment
az deployment sub show \
  --name zavastorefrontTechWorkshop-L300-GitHub-Copilot-and-platform-deployment \
  --query properties.outputs
```

### Restart App Service

```bash
az webapp restart --name <WEB_APP_NAME> --resource-group <RESOURCE_GROUP_NAME>
```

## Support

For issues related to:

- **Azure services**: [Azure Support](https://azure.microsoft.com/support/)
- **Azure Developer CLI**: [AZD GitHub](https://github.com/Azure/azure-dev)
- **Bicep**: [Bicep GitHub](https://github.com/Azure/bicep)

## Next Steps

1. ✅ Deploy infrastructure
2. ✅ Verify application is running
3. Configure custom domain
4. Set up SSL certificate
5. Implement CI/CD pipeline
6. Configure autoscaling
7. Set up staging environment
8. Implement monitoring alerts

---

**Note**: This deployment creates a development environment. For production deployments, review and adjust SKUs, security settings, and scaling configuration accordingly.
