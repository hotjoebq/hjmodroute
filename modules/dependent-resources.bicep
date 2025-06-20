@description('Azure region of the deployment')
param location string

@description('Project name')
param projectName string

@description('Environment (dev, test, prod)')
param environment string

@description('Unique suffix for globally unique resources')
param uniqueSuffix string

@description('Tags to add to the resources')
param tags object = {}

@description('AI Services pricing tier')
param aiServicesSku string = 'F0'

@description('AI services name')
param aiServiceName string = '${projectName}-ai-services-${environment}-${uniqueSuffix}'

@description('Application Insights resource name')
param applicationInsightsName string = '${projectName}-appinsights-${environment}-${uniqueSuffix}'

@description('Container registry name')
param containerRegistryName string = '${projectName}cr${environment}${uniqueSuffix}'

@description('The name of the Key Vault')
param keyVaultName string = '${projectName}kv${environment}${uniqueSuffix}'

@description('Storage account name')
param storageAccountName string = '${projectName}st${environment}${uniqueSuffix}'

// Clean container registry name (remove hyphens and ensure lowercase)
var containerRegistryNameCleaned = replace(toLower(containerRegistryName), '-', '')

// Application Insights
resource applicationInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: applicationInsightsName
  location: location
  tags: tags
  kind: 'web'
  properties: {
    Application_Type: 'web'
    DisableIpMasking: false
    DisableLocalAuth: false
    Flow_Type: 'Bluefield'
    ForceCustomerStorageForProfiler: false
    ImmediatePurgeDataOn30Days: true
    IngestionMode: 'ApplicationInsights'
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
    Request_Source: 'rest'
  }
}

// Container Registry
resource containerRegistry 'Microsoft.ContainerRegistry/registries@2023-07-01' = {
  name: containerRegistryNameCleaned
  location: location
  tags: tags
  sku: {
    name: 'Basic'
  }
  properties: {
    adminUserEnabled: true
    policies: {
      quarantinePolicy: {
        status: 'disabled'
      }
      trustPolicy: {
        type: 'Notary'
        status: 'disabled'
      }
      retentionPolicy: {
        days: 7
        status: 'disabled'
      }
      exportPolicy: {
        status: 'enabled'
      }

    }
    encryption: {
      status: 'disabled'
    }
    dataEndpointEnabled: false
    publicNetworkAccess: 'Enabled'
    networkRuleBypassOptions: 'AzureServices'
    zoneRedundancy: 'Disabled'
  }
}

// Key Vault
resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: keyVaultName
  location: location
  tags: tags
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: tenant().tenantId
    enabledForDeployment: false
    enabledForDiskEncryption: false
    enabledForTemplateDeployment: false
    enableSoftDelete: true
    softDeleteRetentionInDays: 7
    enableRbacAuthorization: true
    vaultUri: 'https://${keyVaultName}${az.environment().suffixes.keyvaultDns}/'
    provisioningState: 'Succeeded'
    publicNetworkAccess: 'Enabled'
  }
}

// Storage Account
resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: storageAccountName
  location: location
  tags: tags
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    dnsEndpointType: 'Standard'
    defaultToOAuthAuthentication: false
    publicNetworkAccess: 'Enabled'
    allowCrossTenantReplication: false
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: false
    allowSharedKeyAccess: true
    networkAcls: {
      bypass: 'AzureServices'
      virtualNetworkRules: []
      ipRules: []
      defaultAction: 'Allow'
    }
    supportsHttpsTrafficOnly: true
    encryption: {
      requireInfrastructureEncryption: false
      services: {
        file: {
          keyType: 'Account'
          enabled: true
        }
        blob: {
          keyType: 'Account'
          enabled: true
        }
      }
      keySource: 'Microsoft.Storage'
    }
    accessTier: 'Hot'
  }
}

// AI Services (Cognitive Services)
resource aiServices 'Microsoft.CognitiveServices/accounts@2023-05-01' = {
  name: aiServiceName
  location: location
  tags: tags
  sku: {
    name: aiServicesSku
  }
  kind: 'AIServices'
  properties: {
    apiProperties: {}
    customSubDomainName: aiServiceName
    networkAcls: {
      defaultAction: 'Allow'
      virtualNetworkRules: []
      ipRules: []
    }
    publicNetworkAccess: 'Enabled'
    disableLocalAuth: false
  }
}

// Outputs
@description('Resource ID of the Application Insights resource')
output applicationInsightsId string = applicationInsights.id

@description('Name of the Application Insights resource')
output applicationInsightsName string = applicationInsights.name

@description('Resource ID of the Container Registry resource')
output containerRegistryId string = containerRegistry.id

@description('Name of the Container Registry resource')
output containerRegistryName string = containerRegistry.name

@description('Resource ID of the Key Vault resource')
output keyVaultId string = keyVault.id

@description('Name of the Key Vault resource')
output keyVaultName string = keyVault.name

@description('Resource ID of the Storage Account resource')
output storageAccountId string = storageAccount.id

@description('Name of the Storage Account resource')
output storageAccountName string = storageAccount.name

@description('Resource ID of the AI Services resource')
output aiServicesId string = aiServices.id

@description('Name of the AI Services resource')
output aiServicesName string = aiServices.name

@description('Target URI of the AI Services resource')
output aiServicesTarget string = aiServices.properties.endpoint
