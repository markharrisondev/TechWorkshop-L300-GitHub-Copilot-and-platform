// Microsoft Foundry (Azure OpenAI/AI Services) for GPT-4 and Phi models
// Provides AI/ML capabilities for the application

@description('Name of the Foundry service')
param name string

@description('Location for the Foundry service')
param location string

@description('Tags to apply to the resource')
param tags object = {}

@description('Principal ID of the managed identity to grant access')
param principalId string

// Azure Cognitive Services Account (Foundry)
resource cognitiveServices 'Microsoft.CognitiveServices/accounts@2024-10-01' = {
  name: name
  location: location
  tags: tags
  kind: 'AIServices'
  sku: {
    name: 'S0'
  }
  properties: {
    customSubDomainName: name
    publicNetworkAccess: 'Enabled'
    networkAcls: {
      defaultAction: 'Allow'
    }
    disableLocalAuth: false
  }
}

// Phi-4 Model Deployment
resource phi4Deployment 'Microsoft.CognitiveServices/accounts/deployments@2024-10-01' = {
  parent: cognitiveServices
  name: 'Phi-4'
  sku: {
    name: 'Standard'
    capacity: 1
  }
  properties: {
    model: {
      format: 'OpenAI'
      name: 'Phi-4'
      version: '2024-12-12'
    }
    raiPolicyName: 'Microsoft.Default'
  }
}

// Cognitive Services User Role Definition ID
var cognitiveServicesUserRoleId = subscriptionResourceId(
  'Microsoft.Authorization/roleDefinitions',
  'a97b65f3-24c7-4388-baec-2e87135dc908'
)

// Role Assignment: Grant Cognitive Services User to Managed Identity
resource cognitiveServicesRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(cognitiveServices.id, principalId, cognitiveServicesUserRoleId)
  scope: cognitiveServices
  properties: {
    roleDefinitionId: cognitiveServicesUserRoleId
    principalId: principalId
    principalType: 'ServicePrincipal'
  }
}

// Outputs
output id string = cognitiveServices.id
output name string = cognitiveServices.name
output endpoint string = cognitiveServices.properties.endpoint
