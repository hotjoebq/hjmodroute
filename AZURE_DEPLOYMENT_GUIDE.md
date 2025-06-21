# Azure Model Router Web Application Deployment Guide

This guide will help you deploy the Azure Model Router web application to your Azure subscription using Bicep templates.

## Prerequisites

- Azure CLI installed and authenticated (`az login`)
- Azure subscription with appropriate permissions
- Resource group already created (or use existing one from AI Foundry deployment)

## Deployment Steps

### 1. Deploy Azure Infrastructure

```bash
# Navigate to the Bicep templates directory
cd azure-ai-foundry-bicep

# Deploy the infrastructure (replace with your resource group name)
az deployment group create \
  --resource-group "YOUR_RESOURCE_GROUP" \
  --template-file main.bicep \
  --parameters projectName="YOUR_PROJECT_NAME" environment="YOUR_ENVIRONMENT"
```

### 2. Get Deployment Outputs

```bash
# Get the backend App Service name
BACKEND_APP_NAME=$(az deployment group show \
  --resource-group "YOUR_RESOURCE_GROUP" \
  --name main \
  --query 'properties.outputs.backendAppServiceName.value' \
  --output tsv)

# Get the frontend Static Web App name
FRONTEND_APP_NAME=$(az deployment group show \
  --resource-group "YOUR_RESOURCE_GROUP" \
  --name main \
  --query 'properties.outputs.frontendStaticWebAppName.value' \
  --output tsv)

# Get the URLs
BACKEND_URL=$(az deployment group show \
  --resource-group "YOUR_RESOURCE_GROUP" \
  --name main \
  --query 'properties.outputs.backendUrl.value' \
  --output tsv)

FRONTEND_URL=$(az deployment group show \
  --resource-group "YOUR_RESOURCE_GROUP" \
  --name main \
  --query 'properties.outputs.frontendUrl.value' \
  --output tsv)

echo "Backend URL: $BACKEND_URL"
echo "Frontend URL: $FRONTEND_URL"
```

### 3. Deploy Application Code

#### Backend Deployment
```bash
# Deploy the backend code
az webapp deploy \
  --resource-group "YOUR_RESOURCE_GROUP" \
  --name "$BACKEND_APP_NAME" \
  --src-path webapp-code/backend.zip \
  --type zip
```

#### Alternative Deployment Methods

If the primary deployment fails with DNS resolution errors, the script automatically attempts:

1. **Run from Package**: Uploads ZIP to Azure Blob Storage and configures `WEBSITE_RUN_FROM_PACKAGE`
2. **FTP Deployment**: Provides FTP credentials for manual file upload

##### Manual Run from Package Setup
```bash
# Upload your ZIP to blob storage and get the URL
PACKAGE_URL="https://yourstorageaccount.blob.core.windows.net/packages/backend.zip"

# Configure App Service
az webapp config appsettings set \
  --resource-group "YOUR_RESOURCE_GROUP" \
  --name "$BACKEND_APP_NAME" \
  --settings WEBSITE_RUN_FROM_PACKAGE="$PACKAGE_URL"
```

#### Frontend Deployment
```bash
# Deploy the frontend code
az staticwebapp environment set \
  --name "$FRONTEND_APP_NAME" \
  --environment-name default \
  --source webapp-code/frontend.zip
```

### 4. Configure Environment Variables (Optional)

If you want to pre-configure Azure Model Router credentials:

```bash
# Set backend environment variables
az webapp config appsettings set \
  --resource-group "YOUR_RESOURCE_GROUP" \
  --name "$BACKEND_APP_NAME" \
  --settings AZURE_ENDPOINT="YOUR_MODEL_ROUTER_ENDPOINT" AZURE_API_KEY="YOUR_API_KEY"
```

## What Gets Deployed

- **Backend**: FastAPI application on Azure App Service (Linux, Python 3.11)
- **Frontend**: React TypeScript application on Azure Static Web Apps
- **App Service Plan**: Basic tier (B1) for cost optimization

## Post-Deployment

1. Navigate to the frontend URL
2. Click "Settings" to configure your Azure Model Router credentials
3. Test the application with various prompts
4. Monitor costs and performance in Azure portal

## Troubleshooting

- **Backend not starting**: Check App Service logs in Azure portal
- **Frontend not loading**: Verify Static Web App deployment status
- **Authentication errors**: Ensure Model Router endpoint and API key are correct
- **CORS issues**: Backend is pre-configured with CORS for Static Web Apps

## Architecture

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────────┐
│ Azure Static    │───▶│ Azure App Service│───▶│ Azure AI Foundry    │
│ Web Apps        │    │ (FastAPI)        │    │ Model Router        │
│ (React Frontend)│    │ (Backend API)    │    │ (YOUR_MODEL_ROUTER) │
└─────────────────┘    └──────────────────┘    └─────────────────────┘
```

The web application acts as a proxy and testing interface for your Azure AI Foundry Model Router, providing intelligent routing visualization and cost optimization insights.
