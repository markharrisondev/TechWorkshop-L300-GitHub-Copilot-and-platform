# ZavaStorefront Azure Infrastructure

This directory contains Infrastructure as Code (IaC) using Azure Bicep for deploying the ZavaStorefront web application to Azure.

## Architecture

The infrastructure provisions the following Azure resources in the `westus3` region:

- **Resource Group**: Container for all resources
- **User-Assigned Managed Identity**: Secure authentication without passwords
- **Azure Container Registry**: Stores Docker images for the application
- **App Service Plan**: Linux B2 (Basic) tier for hosting
- **App Service**: Runs the containerized .NET 8.0 web application
- **Application Insights**: Application performance monitoring
- **Log Analytics Workspace**: Centralized logging and analytics
- **Microsoft Foundry (AI Services)**: GPT-4 and Phi-3 model deployments

## Security Features

- **RBAC-Only Authentication**: No admin passwords for Container Registry
- **Managed Identity**: App Service uses managed identity to pull container images
- **Role Assignments**:
  - `AcrPull` role on Container Registry
  - `Cognitive Services User` role on Foundry
- **HTTPS Enforcement**: All traffic uses TLS 1.2+
- **Disabled Local Auth**: Storage and registry use identity-based authentication only

## File Structure

```
infra/
├── main.bicep                    # Main orchestration template (subscription scope)
├── main.parameters.json          # Parameter file with environment variables
└── resources/
    ├── identity.bicep           # User-Assigned Managed Identity
    ├── container-registry.bicep # Azure Container Registry with RBAC
    ├── monitoring.bicep         # Application Insights + Log Analytics
    ├── app-service.bicep        # App Service Plan + Web App
    └── foundry.bicep            # Microsoft Foundry AI Services
```

## Prerequisites

- Azure CLI (`az`) version 2.50.0 or later
- Azure Developer CLI (`azd`) version 1.5.0 or later
- Active Azure subscription
- Permissions to create resources and assign roles

## Deployment

### Deploy Phi-4 Model in Azure AI Foundry

The infrastructure automatically deploys the Phi-4 model to Azure AI Foundry (Cognitive Services). Here's what happens:

#### Automated Deployment (via Bicep)

When you deploy using `azd up`, the infrastructure will:

1. **Create Azure AI Services account** (formerly Cognitive Services)
2. **Deploy GPT-4 model** with 10 capacity units
3. **Deploy Phi-4 model** (version 2024-12-12) with 1 capacity unit
4. **Configure managed identity access** with Cognitive Services User role
5. **Output the endpoint URL** as `AZURE_FOUNDRY_ENDPOINT`

The Phi-4 deployment is defined in `infra/resources/foundry.bicep` with these specifications:

- **Model Name**: Phi-4
- **Deployment Name**: Phi-4
- **Version**: 2024-12-12
- **Capacity**: 1 unit (Standard SKU)
- **Region**: westus3 (same as other resources)

#### Manual Deployment via Azure Portal

If you prefer to deploy Phi-4 manually through the Azure Portal:

1. **Navigate to Azure AI Foundry**:
   - Go to [Azure Portal](https://portal.azure.com)
   - Search for "Azure AI services" or "Cognitive Services"

2. **Create or Select AI Services Resource**:
   - Click **Create** → **Azure AI services multi-service account**
   - Fill in:
     - Subscription: Your subscription
     - Resource Group: Your resource group
     - Region: **West US 3** (recommended for Phi-4 availability)
     - Name: Unique name for your service
     - Pricing Tier: **S0 (Standard)**
   - Click **Review + Create** → **Create**

3. **Deploy Phi-4 Model**:
   - Open your AI Services resource
   - In the left menu, click **Model deployments** (under Resource Management)
   - Click **+ Create new deployment**
   - Fill in:
     - Select model: **Phi-4**
     - Model version: **2024-12-12** (or latest available)
     - Deployment name: **Phi-4**
     - Deployment type: **Standard**
     - Tokens per Minute Rate Limit: 1K-10K (based on your needs)
   - Click **Deploy**

4. **Get the Endpoint URL**:
   - Go to **Keys and Endpoint** in the left menu
   - Copy the **Endpoint** URL (e.g., `https://your-service.cognitiveservices.azure.com/`)

5. **Configure Managed Identity Access**:
   - Go to **Access control (IAM)**
   - Click **+ Add** → **Add role assignment**
   - Select **Cognitive Services User** role
   - Click **Next**
   - Select **Managed identity**
   - Click **+ Select members**
   - Find your App Service's managed identity
   - Click **Review + assign**

#### Configure the Endpoint in Your Application

After deployment (automated or manual), configure the endpoint:

1. **For Azure deployment** - Set as App Service environment variable:

   ```bash
   az webapp config appsettings set \
     --name <WEB_APP_NAME> \
     --resource-group <RESOURCE_GROUP_NAME> \
     --settings AZURE_FOUNDRY_ENDPOINT="https://your-service.cognitiveservices.azure.com/"
   ```

2. **For local development** - Add to `src/appsettings.json`:

   ```json
   {
     "AZURE_FOUNDRY_ENDPOINT": "https://your-service.cognitiveservices.azure.com/"
   }
   ```

   Or set as environment variable:

   ```powershell
   $env:AZURE_FOUNDRY_ENDPOINT="https://your-service.cognitiveservices.azure.com/"
   dotnet run --project src
   ```

#### Verify Phi-4 Deployment

```bash
# List all model deployments
az cognitiveservices account deployment list \
  --name <AI_SERVICE_NAME> \
  --resource-group <RESOURCE_GROUP_NAME>

# Get specific deployment details
az cognitiveservices account deployment show \
  --name <AI_SERVICE_NAME> \
  --resource-group <RESOURCE_GROUP_NAME> \
  --deployment-name Phi-4
```

### Using Azure Developer CLI (Recommended)

1. **Initialize environment** (if not already done):

   ```bash
   azd init
   ```

2. **Set environment variables**:

   ```bash
   azd env set AZURE_LOCATION westus3
   ```

3. **Preview the deployment**:

   ```bash
   azd provision --preview
   ```

4. **Deploy infrastructure and application**:
   ```bash
   azd up
   ```

### Using Azure CLI

1. **Create a deployment**:

   ```bash
   az deployment sub create \
     --name zavastorefrontTechWorkshop-L300-GitHub-Copilot-and-platform-deployment \
     --location westus3 \
     --template-file infra/main.bicep \
     --parameters infra/main.parameters.json
   ```

2. **Preview with what-if**:
   ```bash
   az deployment sub what-if \
     --name zavastorefrontTechWorkshop-L300-GitHub-Copilot-and-platform-deployment \
     --location westus3 \
     --template-file infra/main.bicep \
     --parameters infra/main.parameters.json
   ```

## Parameters

| Parameter           | Description                          | Default                | Required |
| ------------------- | ------------------------------------ | ---------------------- | -------- |
| `environmentName`   | Environment name for resource naming | -                      | Yes      |
| `location`          | Azure region for resources           | -                      | Yes      |
| `resourceGroupName` | Name of resource group               | `rg-{environmentName}` | No       |
| `principalId`       | Principal ID for role assignments    | -                      | No       |

## Outputs

After deployment, the following outputs are available:

- `RESOURCE_GROUP_ID`: Resource group resource ID
- `RESOURCE_GROUP_NAME`: Resource group name
- `WEB_APP_URL`: Public URL of the deployed web application
- `WEB_APP_NAME`: Name of the App Service
- `CONTAINER_REGISTRY_NAME`: Name of the container registry
- `CONTAINER_REGISTRY_LOGIN_SERVER`: Login server for container registry
- `APPLICATIONINSIGHTS_CONNECTION_STRING`: Connection string for Application Insights
- `AZURE_FOUNDRY_ENDPOINT`: Endpoint for Foundry AI services

## Resource Naming Convention

Resources follow this naming pattern:

- Resource token: `uniqueString(subscription().id, location, environmentName)`
- Format: `az{prefix}{resourceToken}` (max 32 characters, alphanumeric only)

Examples:

- Container Registry: `azacr{token}`
- App Service: `azapp{token}`
- Application Insights: `azai{token}`

## Tags

All resources are tagged with:

- `azd-env-name`: Environment name
- `project`: ZavaStorefront
- `environment`: development
- `azd-service-name`: web (App Service only)

## Cost Considerations

**Development environment estimated monthly costs** (approximate):

- App Service Plan (B2): ~$55/month
- Container Registry (Basic): ~$5/month
- Application Insights: Pay-as-you-go (minimal for dev)
- Log Analytics: Pay-as-you-go (minimal for dev)
- Foundry (S0): ~$1/1K tokens (usage-based)

**Total**: ~$60-100/month (excluding Foundry usage)

## Validation

After deployment, verify:

1. **App Service is running**:

   ```bash
   az webapp show --name <WEB_APP_NAME> --resource-group <RESOURCE_GROUP_NAME>
   ```

2. **Check application logs**:

   ```bash
   azd env list
   azd monitor --logs
   ```

3. **Test the application**:
   Visit the `WEB_APP_URL` from the deployment outputs

## Troubleshooting

### Container fails to pull

- Verify managed identity has `AcrPull` role on ACR
- Check App Service configuration for `acrUseManagedIdentityCreds`

### Application Insights not receiving data

- Verify connection string is set in App Service settings
- Check that Application Insights extension is installed

### Foundry models not accessible

- Verify managed identity has `Cognitive Services User` role
- Confirm models are deployed successfully

## Clean Up

To delete all resources:

```bash
azd down
```

Or manually delete the resource group:

```bash
az group delete --name rg-<environmentName> --yes
```

## Additional Resources

- [Azure App Service Documentation](https://learn.microsoft.com/azure/app-service/)
- [Azure Container Registry Documentation](https://learn.microsoft.com/azure/container-registry/)
- [Azure Developer CLI Documentation](https://learn.microsoft.com/azure/developer/azure-developer-cli/)
- [Bicep Documentation](https://learn.microsoft.com/azure/azure-resource-manager/bicep/)
