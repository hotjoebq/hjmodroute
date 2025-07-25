# Azure AI Foundry Model Router - Bicep Deployment

This repository contains comprehensive Bicep templates to deploy Azure AI Foundry with Model Router functionality, providing intelligent AI model routing with cost optimization capabilities.

## 🏗️ Architecture

The deployment creates the following Azure resources:

### Core Resources
- **AI Hub**: Central workspace that connects all dependent resources
- **AI Project**: Project-level workspace for organizing Model Router deployments  
- **Model Router**: Online endpoint providing intelligent model routing capabilities

### Dependent Resources
- **Application Insights**: Monitoring and logging
- **Container Registry**: Model container storage
- **Key Vault**: Secrets management
- **Storage Account**: Model artifacts and data storage
- **AI Services**: Underlying AI capabilities (Cognitive Services)

## 📋 Prerequisites

Before deploying, ensure you have:

1. **Azure CLI** installed and configured
   ```bash
   # Install Azure CLI (if not already installed)
   curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
   
   # Login to Azure
   az login
   
   # Set your subscription (if you have multiple)
   az account set --subscription "your-subscription-id"
   ```

2. **Bicep CLI** installed
   ```bash
   # Install Bicep CLI
   az bicep install
   
   # Verify installation
   az bicep version
   ```

3. **Required Azure permissions**:
   - Contributor role on the target subscription or resource group
   - Ability to create Azure AI services and Machine Learning workspaces

## 🚀 Quick Start

### Option 1: PowerShell (Windows)

```powershell
# Clone or download the templates
# Navigate to the azure-ai-foundry-bicep directory

# Deploy to development environment
.\scripts\deploy.ps1 -ResourceGroupName "YOUR_RESOURCE_GROUP" -Environment "dev"

# Deploy to production environment  
.\scripts\deploy.ps1 -ResourceGroupName "YOUR_RESOURCE_GROUP" -Environment "prod"

# Preview changes before deployment
.\scripts\deploy.ps1 -ResourceGroupName "YOUR_RESOURCE_GROUP" -Environment "dev" -WhatIf
```

### Option 2: Bash (Linux/Mac)

```bash
# Make script executable
chmod +x scripts/deploy.sh

# Deploy to development environment
./scripts/deploy.sh -g "YOUR_RESOURCE_GROUP" -l "YOUR_AZURE_REGION" -e "dev"

# Deploy to production environment
./scripts/deploy.sh -g "YOUR_RESOURCE_GROUP" -l "YOUR_AZURE_REGION" -e "prod"

# Preview changes before deployment
./scripts/deploy.sh -g "YOUR_RESOURCE_GROUP" -l "YOUR_AZURE_REGION" -e "dev" -w
```

### Option 3: Azure CLI Direct

```bash
# Create resource group
az group create --name "YOUR_RESOURCE_GROUP" --location "YOUR_AZURE_REGION"

# Deploy using Azure CLI
az deployment group create \
  --resource-group "YOUR_RESOURCE_GROUP" \
  --template-file main.bicep \
  --parameters parameters/parameters-dev.json
```

## ⚙️ Configuration

### Parameter Files

The deployment uses parameter files for different environments:

- `parameters/parameters-dev.json` - Development environment
- `parameters/parameters-prod.json` - Production environment

### Key Parameters

| Parameter | Description | Default | Options |
|-----------|-------------|---------|---------|
| `projectName` | Base name for all resources | Required | 2-12 characters |
| `location` | Azure region | Required | Any Azure region |
| `environment` | Environment type | `dev` | `dev`, `test`, `prod` |
| `aiServicesSku` | AI Services pricing tier | `F0` | `F0` (free), `S0` (standard) |

### Customizing Parameters

Edit the parameter files to customize your deployment:

```json
{
  "parameters": {
    "projectName": {
      "value": "YOUR_PROJECT_NAME"
    },
    "location": {
      "value": "YOUR_AZURE_REGION"
    },
    "environment": {
      "value": "YOUR_ENVIRONMENT"
    },
    "aiServicesSku": {
      "value": "F0"
    }
  }
}
```

## 📊 Deployment Outputs

After successful deployment, you'll receive:

- **Model Router Endpoint URL**: For making API calls
- **Authentication Keys**: For accessing the endpoint (if using Key auth)
- **Resource IDs**: For integration with other services
- **Resource Names**: For Azure portal navigation

Example output:
```
Model Router Endpoint URL: https://YOUR_PROJECT-model-router-YOUR_ENV.YOUR_REGION.inference.ml.azure.com/score
Primary Key: YOUR_API_KEY...
AI Hub Name: YOUR_PROJECT-ai-hub-YOUR_ENV-UNIQUE_ID
```

### AI Services SKU Options

- **F0 (Free Tier)**: No quota restrictions, limited usage (20 calls/minute, 1M characters/month)
- **S0 (Standard Tier)**: Requires special quota approval, higher usage limits

For development and testing, F0 tier is recommended as it doesn't require quota approval.

## 🔧 Using the Model Router

### REST API Example

```bash
# Using the deployed Model Router endpoint
curl -X POST "https://YOUR_ENDPOINT_URL/score" \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "messages": [
      {"role": "user", "content": "Hello, how can you help me today?"}
    ],
    "max_tokens": 100
  }'
```

### Python Example

```python
import requests

endpoint_url = "https://YOUR_ENDPOINT_URL/score"
api_key = "YOUR_API_KEY"

headers = {
    "Authorization": f"Bearer {api_key}",
    "Content-Type": "application/json"
}

data = {
    "messages": [
        {"role": "user", "content": "Explain machine learning in simple terms"}
    ],
    "max_tokens": 150
}

response = requests.post(endpoint_url, headers=headers, json=data)
print(response.json())
```

## 🛠️ Troubleshooting

### Common Issues

1. **Deployment Fails - Resource Names**
   - Ensure `projectName` is 2-12 characters, alphanumeric only
   - Some resources require globally unique names

2. **Permission Errors**
   - Verify you have Contributor role on the subscription/resource group
   - Check if Azure AI services are available in your region

3. **Model Router Not Responding**
   - Allow 5-10 minutes for initial deployment to complete
   - Check Application Insights for detailed logs

### Validation Commands

```bash
# Validate Bicep syntax
az bicep build --file main.bicep

# Preview deployment changes
az deployment group what-if \
  --resource-group "your-rg" \
  --template-file main.bicep \
  --parameters parameters/parameters-dev.json

# Check deployment status
az deployment group show \
  --resource-group "your-rg" \
  --name "your-deployment-name"
```

## 💰 Cost Optimization

The Model Router automatically optimizes costs by:

- **Intelligent Routing**: Routes simple queries to cost-effective models
- **Caching**: Reduces redundant API calls
- **Auto-scaling**: Scales compute resources based on demand

### Estimated Costs (Monthly)

| Environment | Estimated Cost | Description |
|-------------|----------------|-------------|
| Development | $50-100 | Basic tier resources, low usage |
| Production | $200-500 | Standard tier, moderate usage |

*Costs vary based on usage patterns and selected Azure regions*

## 🔒 Security Considerations

- **Authentication**: Supports Key, Azure ML Token, and AAD Token authentication
- **Network Security**: Configurable public/private network access
- **Key Management**: Secrets stored in Azure Key Vault
- **RBAC**: Role-based access control for all resources

## Azure AI Foundry Model Router Architecture

### What is the Azure AI Foundry Model Router?

The Azure AI Foundry Model Router in this repository serves as the **intelligent routing engine** for chat scenarios, providing:
- **Cost-optimized model selection** based on query complexity analysis
- **Native Azure intelligent routing** capabilities with built-in load balancing
- **Fallback mechanisms** between different AI models for reliability
- **Real-time cost optimization** features during preview period (no extra charges)

### Repository Architecture Overview

This repository provides a **4-phase deployment workflow**:

**Phase 1: Infrastructure Deployment** (Automated via Bicep)
- Deploys AI Hub, AI Project, AI Services, and web application infrastructure
- Creates prerequisite resources for Model Router setup
- **Note**: Does NOT deploy the Model Router itself

**Phase 2: Manual Model Router Deployment** (Azure Portal)
- Model Router is a **preview feature** requiring manual deployment
- Must be configured through Azure AI Foundry portal after infrastructure creation
- Generates endpoint URL pattern: `https://{project}-model-router-{env}.{region}.inference.ml.azure.com/score`

**Phase 3: Web Application Deployment** (Automated)
- Deploys React frontend and FastAPI backend as testing interface
- Provides user-friendly UI for Model Router interaction and configuration

**Phase 4: Configuration & Testing**
- Configure Model Router endpoint and API key through web application
- Test intelligent routing capabilities with various query complexities

### Integration Approach

The web application **integrates with** (not replaces) Azure AI Foundry Model Router:
- Frontend accepts manual configuration of Model Router endpoint URL and API key
- Backend makes direct API calls to the manually deployed Model Router endpoint  
- Provides enhanced analytics layer with complexity scoring and cost estimation
- Serves as a **bridge** between users and Azure's native Model Router functionality

## Application Code Deployment

The repository includes a complete Azure Model Router web application that can be deployed to the infrastructure.

### Prerequisites
```bash
# Authenticate with Azure CLI
az login

# Verify authentication
az account show
```

### Automatic Deployment
```bash
# Deploy infrastructure and application code together
./deploy-webapp.sh -g "your-resource-group" -p "your-project" -e "dev" --deploy-code
```

### Manual Application Code Update
```bash
# Get backend URL from deployment
BACKEND_URL=$(az deployment group show --resource-group "your-rg" --name "web-app-only-..." --query 'properties.outputs.backendUrl.value' --output tsv)

# Update and deploy application code
./update-webapp-code.sh "$BACKEND_URL"
./deploy-webapp.sh -g "your-resource-group" -p "your-project" -e "dev" --deploy-code
```

The application includes:
- **Frontend**: React-based web interface with Azure Model Router integration
- **Backend**: FastAPI application with intelligent model routing and cost optimization
- **Features**: Complexity scoring, cost estimation, test prompts, and Azure credential configuration

## 🔧 Troubleshooting

### Common Issues

#### Authentication Errors
```bash
# Error: Azure CLI not authenticated
az login

# Error: Insufficient permissions
az role assignment list --assignee $(az account show --query user.name --output tsv)
```

#### Application Code Deployment Issues
- **Frontend shows placeholder page**: Ensure you used the `--deploy-code` flag and Azure CLI is authenticated
- **Backend API not responding**: Check App Service deployment logs in Azure Portal
- **Static Web App deployment failed**: Verify Azure CLI has Static Web Apps permissions

## 📚 Additional Resources

- [Azure AI Foundry Documentation](https://docs.microsoft.com/azure/ai-foundry/)
- [Model Router Overview](https://docs.microsoft.com/azure/ai-foundry/model-router)
- [Bicep Documentation](https://docs.microsoft.com/azure/azure-resource-manager/bicep/)
- [Azure CLI Reference](https://docs.microsoft.com/cli/azure/)

## 🤝 Support

For issues with:
- **Azure AI Foundry**: Contact Azure Support
- **Bicep Templates**: Create an issue in this repository
- **Deployment Scripts**: Check the troubleshooting section above
- **Application Code Deployment**: If the frontend shows a placeholder page, ensure you used the `--deploy-code` flag and Azure CLI is authenticated

---

**Note**: This deployment replaces custom FastAPI implementations with Azure AI Foundry's native Model Router capabilities, providing enterprise-grade intelligent routing with built-in cost optimization.
