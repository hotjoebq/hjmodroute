@description('Azure region of the deployment')
param location string

@description('AI Project name')
param aiProjectName string

@description('AI Project display name')
param aiProjectDisplayName string = aiProjectName

@description('AI Project description')
param aiProjectDescription string

@description('Resource ID of the AI Hub')
param aiHubId string

@description('Tags to add to the resources')
param tags object = {}

// AI Project (Machine Learning Workspace)
resource aiProject 'Microsoft.MachineLearningServices/workspaces@2023-08-01-preview' = {
  name: aiProjectName
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    friendlyName: aiProjectDisplayName
    description: aiProjectDescription
    hubResourceId: aiHubId
    publicNetworkAccess: 'Enabled'
    discoveryUrl: 'https://${location}.api.azureml.ms/discovery'
  }
  kind: 'Project'
}

// Outputs
@description('Resource ID of the AI Project')
output aiProjectId string = aiProject.id

@description('Name of the AI Project')
output aiProjectName string = aiProject.name

@description('Principal ID of the AI Project system assigned identity')
output aiProjectPrincipalId string = aiProject.identity.principalId
