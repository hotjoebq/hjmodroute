@description('Main deployment template for Azure AI Foundry infrastructure')
@minLength(2)
@maxLength(12)
param projectName string

@description('Azure region for all resources')
param location string = resourceGroup().location

@description('Environment (dev, test, prod)')
@allowed(['dev', 'test', 'prod'])
param environment string = 'dev'

@description('Tags to apply to all resources')
param tags object = {
  Environment: environment
  Project: projectName
  DeployedBy: 'Bicep'
  Purpose: 'AI-Foundry-Infrastructure'
}

@description('AI Services pricing tier')
@allowed(['F0', 'S0'])
param aiServicesSku string = 'F0'

@description('AI Hub display name')
param aiHubDisplayName string = '${projectName}-ai-hub-${environment}'

@description('AI Hub description')
param aiHubDescription string = 'AI Hub for ${projectName} with Model Router capabilities'

@description('AI Project display name')
param aiProjectDisplayName string = '${projectName}-ai-project-${environment}'

@description('AI Project description')
param aiProjectDescription string = 'AI Project for ${projectName} - ready for manual Model Router deployment'

// Generate unique suffix for globally unique resources
var uniqueSuffix = substring(uniqueString(resourceGroup().id, projectName), 0, 6)

// Deploy dependent resources (Storage, Key Vault, etc.)
module dependentResources 'modules/dependent-resources.bicep' = {
  name: 'dependent-resources-deployment'
  params: {
    location: location
    projectName: projectName
    environment: environment
    uniqueSuffix: uniqueSuffix
    aiServicesSku: aiServicesSku
    tags: tags
  }
}

// Deploy AI Hub
module aiHub 'modules/ai-hub.bicep' = {
  name: 'ai-hub-deployment'
  params: {
    location: location
    aiHubName: '${projectName}-ai-hub-${environment}-${uniqueSuffix}'
    aiHubDisplayName: aiHubDisplayName
    aiHubDescription: aiHubDescription
    applicationInsightsId: dependentResources.outputs.applicationInsightsId
    containerRegistryId: dependentResources.outputs.containerRegistryId
    keyVaultId: dependentResources.outputs.keyVaultId
    storageAccountId: dependentResources.outputs.storageAccountId
    aiServicesId: dependentResources.outputs.aiServicesId
    aiServicesTarget: dependentResources.outputs.aiServicesTarget
    tags: tags
  }
}

// Deploy AI Project
module aiProject 'modules/ai-project.bicep' = {
  name: 'ai-project-deployment'
  params: {
    location: location
    aiProjectName: '${projectName}-ai-project-${environment}-${uniqueSuffix}'
    aiProjectDisplayName: aiProjectDisplayName
    aiProjectDescription: aiProjectDescription
    aiHubId: aiHub.outputs.aiHubId
    tags: tags
  }
}

// Deploy Web Application
module webApp 'modules/web-app.bicep' = {
  name: 'web-app-deployment'
  params: {
    location: location
    projectName: projectName
    environment: environment
    uniqueSuffix: uniqueSuffix
    tags: tags
  }
}

// Note: Model Router must be deployed manually through Azure AI Foundry portal
// The AI Project created above is ready for manual Model Router deployment

// Outputs
@description('Resource Group Name')
output resourceGroupName string = resourceGroup().name

@description('AI Hub Resource ID')
output aiHubId string = aiHub.outputs.aiHubId

@description('AI Hub Name')
output aiHubName string = aiHub.outputs.aiHubName

@description('AI Project Resource ID')
output aiProjectId string = aiProject.outputs.aiProjectId

@description('AI Project Name')
output aiProjectName string = aiProject.outputs.aiProjectName

// Model Router outputs removed - deploy manually through Azure AI Foundry portal

@description('Storage Account Name')
output storageAccountName string = dependentResources.outputs.storageAccountName

@description('Key Vault Name')
output keyVaultName string = dependentResources.outputs.keyVaultName

@description('Application Insights Name')
output applicationInsightsName string = dependentResources.outputs.applicationInsightsName

@description('Container Registry Name')
output containerRegistryName string = dependentResources.outputs.containerRegistryName

@description('AI Services Name')
output aiServicesName string = dependentResources.outputs.aiServicesName

@description('Backend App Service URL')
output backendUrl string = webApp.outputs.backendUrl

@description('Backend App Service Name')
output backendAppServiceName string = webApp.outputs.backendAppServiceName

@description('Frontend Static Web App URL')
output frontendUrl string = webApp.outputs.frontendUrl

@description('Frontend Static Web App Name')
output frontendStaticWebAppName string = webApp.outputs.frontendStaticWebAppName
