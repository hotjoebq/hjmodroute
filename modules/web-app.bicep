@description('Deploy Azure Model Router Web Application')
param location string
param projectName string
param environment string
param uniqueSuffix string
param tags object

@description('App Service Plan SKU')
param appServicePlanSku string = 'B1'

// App Service Plan for backend
resource appServicePlan 'Microsoft.Web/serverfarms@2023-01-01' = {
  name: '${projectName}-webapp-plan-${environment}-${uniqueSuffix}'
  location: location
  tags: tags
  sku: {
    name: appServicePlanSku
    tier: 'Basic'
  }
  kind: 'linux'
  properties: {
    reserved: true
  }
}

// App Service for backend API
resource backendAppService 'Microsoft.Web/sites@2023-01-01' = {
  name: '${projectName}-backend-${environment}-${uniqueSuffix}'
  location: location
  tags: tags
  properties: {
    serverFarmId: appServicePlan.id
    siteConfig: {
      linuxFxVersion: 'PYTHON|3.11'
      appCommandLine: 'python -m uvicorn app.main:app --host 0.0.0.0 --port 8000'
      appSettings: [
        {
          name: 'SCM_DO_BUILD_DURING_DEPLOYMENT'
          value: 'true'
        }
        {
          name: 'AZURE_ENDPOINT'
          value: ''
        }
        {
          name: 'AZURE_API_KEY'
          value: ''
        }
      ]
    }
    httpsOnly: true
  }
}

// Static Web App for frontend
resource staticWebApp 'Microsoft.Web/staticSites@2023-01-01' = {
  name: '${projectName}-frontend-${environment}-${uniqueSuffix}'
  location: location
  tags: tags
  sku: {
    name: 'Free'
    tier: 'Free'
  }
  properties: {
    buildProperties: {
      appLocation: '/frontend'
      outputLocation: 'dist'
    }
  }
}

// Outputs
@description('Backend App Service URL')
output backendUrl string = 'https://${backendAppService.properties.defaultHostName}'

@description('Backend App Service Name')
output backendAppServiceName string = backendAppService.name

@description('Frontend Static Web App URL')
output frontendUrl string = 'https://${staticWebApp.properties.defaultHostname}'

@description('Frontend Static Web App Name')
output frontendStaticWebAppName string = staticWebApp.name

@description('App Service Plan Name')
output appServicePlanName string = appServicePlan.name
