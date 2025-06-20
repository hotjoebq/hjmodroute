@description('Azure region of the deployment')
param location string

@description('AI Hub name')
param aiHubName string

@description('AI Hub display name')
param aiHubDisplayName string = aiHubName

@description('AI Hub description')
param aiHubDescription string

@description('Resource ID of the application insights resource for storing diagnostics logs')
param applicationInsightsId string

@description('Resource ID of the container registry resource for storing docker images')
param containerRegistryId string

@description('Resource ID of the key vault resource for storing connection strings')
param keyVaultId string

@description('Resource ID of the storage account resource for storing experimentation outputs')
param storageAccountId string

@description('Resource ID of the AI Services resource')
param aiServicesId string

@description('Target URI of the AI Services resource')
param aiServicesTarget string

@description('Tags to add to the resources')
param tags object = {}

// AI Hub (Machine Learning Workspace)
resource aiHub 'Microsoft.MachineLearningServices/workspaces@2023-08-01-preview' = {
  name: aiHubName
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    friendlyName: aiHubDisplayName
    description: aiHubDescription
    storageAccount: storageAccountId
    keyVault: keyVaultId
    applicationInsights: applicationInsightsId
    containerRegistry: containerRegistryId
    publicNetworkAccess: 'Enabled'
    discoveryUrl: 'https://${location}.api.azureml.ms/discovery'
    workspaceHubConfig: {
      additionalWorkspaceStorageAccounts: []
      defaultWorkspaceResourceGroup: resourceGroup().id
    }
  }
  kind: 'Hub'
}

// AI Services Connection
resource aiServicesConnection 'Microsoft.MachineLearningServices/workspaces/connections@2024-01-01-preview' = {
  parent: aiHub
  name: '${aiHubName}-connection-AzureOpenAI'
  properties: {
    category: 'AzureOpenAI'
    target: aiServicesTarget
    authType: 'ApiKey'
    isSharedToAll: true
    credentials: {
      key: listKeys(aiServicesId, '2023-05-01').key1
    }
    metadata: {
      ApiType: 'Azure'
      ResourceId: aiServicesId
    }
  }
}

// Outputs
@description('Resource ID of the AI Hub')
output aiHubId string = aiHub.id

@description('Name of the AI Hub')
output aiHubName string = aiHub.name

@description('Principal ID of the AI Hub system assigned identity')
output aiHubPrincipalId string = aiHub.identity.principalId
