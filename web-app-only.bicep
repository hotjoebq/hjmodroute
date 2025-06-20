@description('Deploy only Azure Model Router Web Application (for existing AI Foundry infrastructure)')
param location string = resourceGroup().location
param projectName string
param environment string
param uniqueSuffix string
param tags object

@description('App Service Plan SKU')
param appServicePlanSku string = 'B1'

// Import the web-app module
module webApp 'modules/web-app.bicep' = {
  name: 'web-app-only-deployment'
  params: {
    location: location
    projectName: projectName
    environment: environment
    uniqueSuffix: uniqueSuffix
    tags: tags
    appServicePlanSku: appServicePlanSku
  }
}

// Outputs
@description('Backend App Service URL')
output backendUrl string = webApp.outputs.backendUrl

@description('Backend App Service Name')
output backendAppServiceName string = webApp.outputs.backendAppServiceName

@description('Frontend Static Web App URL')
output frontendUrl string = webApp.outputs.frontendUrl

@description('Frontend Static Web App Name')
output frontendStaticWebAppName string = webApp.outputs.frontendStaticWebAppName

@description('App Service Plan Name')
output appServicePlanName string = webApp.outputs.appServicePlanName
