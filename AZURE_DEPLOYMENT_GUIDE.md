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
  --resource-group "your-resource-group-name" \
  --template-file main.bicep \
  --parameters projectName="myaiproject" environment="dev"
```

### 2. Get Deployment Outputs

```bash
# Get the backend App Service name
BACKEND_APP_NAME=$(az deployment group show \
  --resource-group "your-resource-group-name" \
  --name main \
  --query 'properties.outputs.backendAppServiceName.value' \
  --output tsv)

# Get the frontend Static Web App name
FRONTEND_APP_NAME=$(az deployment group show \
  --resource-group "your-resource-group-name" \
  --name main \
  --query 'properties.outputs.frontendStaticWebAppName.value' \
  --output tsv)

# Get the URLs
BACKEND_URL=$(az deployment group show \
  --resource-group "your-resource-group-name" \
  --name main \
  --query 'properties.outputs.backendUrl.value' \
  --output tsv)

FRONTEND_URL=$(az deployment group show \
  --resource-group "your-resource-group-name" \
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
az webapp deployment source config-zip \
  --resource-group "your-resource-group-name" \
  --name "$BACKEND_APP_NAME" \
  --src webapp-code/backend.zip
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
  --resource-group "your-resource-group-name" \
  --name "$BACKEND_APP_NAME" \
  --settings AZURE_ENDPOINT="your-model-router-endpoint" AZURE_API_KEY="your-api-key"
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
│ (React Frontend)│    │ (Backend API)    │    │ (hj619-model-router)│
└─────────────────┘    └──────────────────┘    └─────────────────────┘
```

The web application acts as a proxy and testing interface for your Azure AI Foundry Model Router, providing intelligent routing visualization and cost optimization insights.
