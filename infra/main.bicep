// Main Bicep template for ZavaStorefront infrastructure
// Deploys all Azure resources required for the application

targetScope = 'subscription'

@minLength(1)
@maxLength(64)
@description('Name of the environment (used for resource naming and tagging)')
param environmentName string

@minLength(1)
@description('Primary location for all resources')
param location string

@description('Name of the resource group')
param resourceGroupName string = 'rg-${environmentName}'

@description('Id of the user or app to assign application roles')
param principalId string = ''

// Generate unique token for resource naming
var resourceToken = uniqueString(subscription().id, location, environmentName)

// Tags applied to all resources
var tags = {
  'azd-env-name': environmentName
  project: 'ZavaStorefront'
  environment: 'development'
}

// Resource Group
resource rg 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: resourceGroupName
  location: location
  tags: tags
}

// Managed Identity Module
module identity 'resources/identity.bicep' = {
  name: 'identity-deployment'
  scope: rg
  params: {
    name: 'azid${resourceToken}'
    location: location
    tags: tags
  }
}

// Container Registry Module
module containerRegistry 'resources/container-registry.bicep' = {
  name: 'acr-deployment'
  scope: rg
  params: {
    name: 'azacr${resourceToken}'
    location: location
    tags: tags
    principalId: identity.outputs.principalId
  }
}

// Monitoring Module (Application Insights + Log Analytics)
module monitoring 'resources/monitoring.bicep' = {
  name: 'monitoring-deployment'
  scope: rg
  params: {
    logAnalyticsName: 'azlaw${resourceToken}'
    applicationInsightsName: 'azai${resourceToken}'
    location: location
    tags: tags
  }
}

// App Service Module
module appService 'resources/app-service.bicep' = {
  name: 'appservice-deployment'
  scope: rg
  params: {
    name: 'azapp${resourceToken}'
    appServicePlanName: 'azplan${resourceToken}'
    location: location
    tags: union(tags, {
      'azd-service-name': 'web'
    })
    managedIdentityId: identity.outputs.id
    containerRegistryName: containerRegistry.outputs.name
    applicationInsightsConnectionString: monitoring.outputs.applicationInsightsConnectionString
  }
}

// Microsoft Foundry Module (AI/ML Services)
module foundry 'resources/foundry.bicep' = {
  name: 'foundry-deployment'
  scope: rg
  params: {
    name: 'azfnd${resourceToken}'
    location: location
    tags: tags
    principalId: identity.outputs.principalId
  }
}

// Outputs
output RESOURCE_GROUP_ID string = rg.id
output RESOURCE_GROUP_NAME string = rg.name
output WEB_APP_URL string = appService.outputs.uri
output WEB_APP_NAME string = appService.outputs.name
output CONTAINER_REGISTRY_NAME string = containerRegistry.outputs.name
output CONTAINER_REGISTRY_LOGIN_SERVER string = containerRegistry.outputs.loginServer
output APPLICATIONINSIGHTS_CONNECTION_STRING string = monitoring.outputs.applicationInsightsConnectionString
output AZURE_FOUNDRY_ENDPOINT string = foundry.outputs.endpoint
