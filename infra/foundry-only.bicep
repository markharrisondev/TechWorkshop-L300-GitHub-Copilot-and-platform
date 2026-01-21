// Deploy only Azure AI Foundry with Phi-4 model
targetScope = 'resourceGroup'

@description('Location for resources')
param location string = resourceGroup().location

@description('Name of the Foundry service')
param foundryName string = 'zavafoundry${uniqueString(resourceGroup().id)}'

// Azure Cognitive Services Account (Foundry)
resource cognitiveServices 'Microsoft.CognitiveServices/accounts@2024-10-01' = {
  name: foundryName
  location: location
  kind: 'AIServices'
  sku: {
    name: 'S0'
  }
  properties: {
    customSubDomainName: foundryName
    publicNetworkAccess: 'Enabled'
    networkAcls: {
      defaultAction: 'Allow'
    }
    disableLocalAuth: false
  }
}

// Phi-3.5 Model Deployment (Phi-4 not available in all regions yet)
resource phi35Deployment 'Microsoft.CognitiveServices/accounts/deployments@2024-10-01' = {
  parent: cognitiveServices
  name: 'Phi-4'
  sku: {
    name: 'Standard'
    capacity: 1
  }
  properties: {
    model: {
      format: 'OpenAI'
      name: 'Phi-3.5-mini-instruct'
    }
    raiPolicyName: 'Microsoft.Default'
  }
}

// Outputs
output endpoint string = cognitiveServices.properties.endpoint
output foundryName string = cognitiveServices.name
output resourceId string = cognitiveServices.id
