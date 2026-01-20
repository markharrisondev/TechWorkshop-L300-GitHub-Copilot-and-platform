// Azure App Service for hosting the ZavaStorefront containerized web application
// Configured for Linux with Docker container support

@description('Name of the App Service')
param name string

@description('Name of the App Service Plan')
param appServicePlanName string

@description('Location for the App Service')
param location string

@description('Tags to apply to the resources')
param tags object = {}

@description('Resource ID of the User-Assigned Managed Identity')
param managedIdentityId string

@description('Name of the Container Registry')
param containerRegistryName string

@description('Application Insights connection string')
param applicationInsightsConnectionString string

// App Service Plan (Linux)
resource appServicePlan 'Microsoft.Web/serverfarms@2023-12-01' = {
  name: appServicePlanName
  location: location
  tags: tags
  sku: {
    name: 'B2'
    tier: 'Basic'
    size: 'B2'
    family: 'B'
    capacity: 1
  }
  kind: 'linux'
  properties: {
    reserved: true // Required for Linux
    perSiteScaling: false
    elasticScaleEnabled: false
    maximumElasticWorkerCount: 1
    isSpot: false
    zoneRedundant: false
  }
}

// App Service (Web App)
resource appService 'Microsoft.Web/sites@2023-12-01' = {
  name: name
  location: location
  tags: tags
  kind: 'app,linux,container'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${managedIdentityId}': {}
    }
  }
  properties: {
    serverFarmId: appServicePlan.id
    httpsOnly: true
    clientAffinityEnabled: false
    siteConfig: {
      linuxFxVersion: 'DOCKER|${containerRegistryName}.azurecr.io/zavastorefrontweb:latest'
      acrUseManagedIdentityCreds: true
      acrUserManagedIdentityID: managedIdentityId
      alwaysOn: true
      ftpsState: 'Disabled'
      minTlsVersion: '1.2'
      http20Enabled: true
      appSettings: [
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: applicationInsightsConnectionString
        }
        {
          name: 'ApplicationInsightsAgent_EXTENSION_VERSION'
          value: '~3'
        }
        {
          name: 'ASPNETCORE_ENVIRONMENT'
          value: 'Development'
        }
        {
          name: 'DOCKER_REGISTRY_SERVER_URL'
          value: 'https://${containerRegistryName}.azurecr.io'
        }
        {
          name: 'WEBSITES_ENABLE_APP_SERVICE_STORAGE'
          value: 'false'
        }
      ]
    }
  }
}

// App Service Site Extension for Application Insights
resource siteExtension 'Microsoft.Web/sites/siteextensions@2023-12-01' = {
  name: 'Microsoft.ApplicationInsights.AzureWebSites'
  parent: appService
}

// Outputs
output id string = appService.id
output name string = appService.name
output uri string = 'https://${appService.properties.defaultHostName}'
output defaultHostName string = appService.properties.defaultHostName
