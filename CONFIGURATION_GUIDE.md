# Azure Model Router Configuration Guide

This guide explains how to configure the Azure Model Router deployment package for your specific environment.

## Required Configuration Parameters

Before deploying, you must provide the following configuration values:

### 1. Project Configuration
- **PROJECT_NAME**: Base name for all Azure resources (2-12 characters, alphanumeric)
- **ENVIRONMENT**: Environment type (`dev`, `test`, or `prod`)
- **AZURE_REGION**: Azure region for deployment (e.g., `eastus`, `westus2`, `centralus`)
- **RESOURCE_GROUP**: Name of your Azure resource group

### 2. Parameter File Configuration

Update the parameter files with your specific values:

#### For Development Environment (`parameters/parameters-dev.json`):
```json
{
  "parameters": {
    "projectName": {
      "value": "mycompany"
    },
    "location": {
      "value": "eastus"
    },
    "environment": {
      "value": "dev"
    }
  }
}
```

#### For Production Environment (`parameters/parameters-prod.json`):
```json
{
  "parameters": {
    "projectName": {
      "value": "mycompany"
    },
    "location": {
      "value": "westus2"
    },
    "environment": {
      "value": "prod"
    }
  }
}
```

### 3. Deployment Script Usage

#### Option 1: Using deploy-webapp.sh
```bash
./deploy-webapp.sh -g "my-resource-group" -p "mycompany" -e "dev" --deploy-code
```

#### Option 2: Using scripts/deploy.sh
```bash
./scripts/deploy.sh -g "my-resource-group" -l "eastus" -e "dev"
```

#### Option 3: Direct Azure CLI
```bash
az deployment group create \
  --resource-group "my-resource-group" \
  --template-file main.bicep \
  --parameters @parameters/parameters-dev.json
```

## Runtime Configuration

The Azure Model Router endpoint and API key are configured at runtime through the web application:

1. Deploy the infrastructure and web application
2. Open the frontend URL in your browser
3. Click "Settings" to configure:
   - **Azure Model Router Endpoint**: Your deployed model router URL
   - **API Key**: Authentication key for your model router

## Example Complete Configuration

Here's a complete example for a company called "Contoso":

### Parameter File (`parameters/parameters-prod.json`):
```json
{
  "parameters": {
    "projectName": {
      "value": "contoso"
    },
    "location": {
      "value": "eastus"
    },
    "environment": {
      "value": "prod"
    }
  }
}
```

### Deployment Command:
```bash
./deploy-webapp.sh -g "contoso-ai-resources" -p "contoso" -e "prod" --deploy-code
```

### Runtime Configuration (in web app):
- **Endpoint**: `https://contoso-model-router-prod.eastus.inference.ml.azure.com/score`
- **API Key**: `your-actual-api-key-from-azure`

## Validation

After configuration, verify that:
- [ ] All parameter files contain your specific values (no placeholders)
- [ ] Deployment scripts receive all required parameters
- [ ] Resource group exists in your Azure subscription
- [ ] Azure CLI is authenticated to your subscription
- [ ] Model Router endpoint and API key are available for runtime configuration

## Troubleshooting

### Common Configuration Issues:
- **Missing required parameters**: Ensure all scripts receive required arguments
- **Invalid project name**: Must be 2-12 alphanumeric characters
- **Resource group doesn't exist**: Create it first or use existing one
- **Authentication errors**: Run `az login` and verify subscription access

### Getting Your Model Router Details:
After deploying the AI Foundry infrastructure, get your Model Router details from:
1. Azure Portal → AI Foundry → Your Project → Model Router
2. Copy the endpoint URL and primary key for runtime configuration
