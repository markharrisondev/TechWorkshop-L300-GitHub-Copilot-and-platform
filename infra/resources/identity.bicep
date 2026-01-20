// User-Assigned Managed Identity for secure authentication
// Used by App Service to access Container Registry and Foundry services

@description('Name of the managed identity')
param name string

@description('Location for the managed identity')
param location string

@description('Tags to apply to the resource')
param tags object = {}

// User-Assigned Managed Identity
resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: name
  location: location
  tags: tags
}

// Outputs
output id string = managedIdentity.id
output principalId string = managedIdentity.properties.principalId
output clientId string = managedIdentity.properties.clientId
output name string = managedIdentity.name
