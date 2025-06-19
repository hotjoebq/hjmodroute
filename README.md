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
.\scripts\deploy.ps1 -ResourceGroupName "rg-ai-model-router-dev" -Environment "dev"

# Deploy to production environment  
.\scripts\deploy.ps1 -ResourceGroupName "rg-ai-model-router-prod" -Environment "prod"

# Preview changes before deployment
.\scripts\deploy.ps1 -ResourceGroupName "rg-ai-model-router-dev" -Environment "dev" -WhatIf
```

### Option 2: Bash (Linux/Mac)

```bash
# Make script executable
chmod +x scripts/deploy.sh

# Deploy to development environment
./scripts/deploy.sh -g "rg-ai-model-router-dev" -e "dev"

# Deploy to production environment
./scripts/deploy.sh -g "rg-ai-model-router-prod" -e "prod"

# Preview changes before deployment
./scripts/deploy.sh -g "rg-ai-model-router-dev" -e "dev" -w
```

### Option 3: Azure CLI Direct

```bash
# Create resource group
az group create --name "rg-ai-model-router-dev" --location "eastus"

# Deploy using Azure CLI
az deployment group create \
  --resource-group "rg-ai-model-router-dev" \
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
| `projectName` | Base name for all resources | `aimodelrouter` | 2-12 characters |
| `location` | Azure region | `eastus` | Any Azure region |
| `environment` | Environment type | `dev` | `dev`, `test`, `prod` |
| `authMode` | Authentication mode | `Key` | `Key`, `AMLToken`, `AADToken` |
| `publicNetworkAccess` | Enable public access | `true` | `true`, `false` |

### Customizing Parameters

Edit the parameter files to customize your deployment:

```json
{
  "parameters": {
    "projectName": {
      "value": "myaiproject"
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

## 📊 Deployment Outputs

After successful deployment, you'll receive:

- **Model Router Endpoint URL**: For making API calls
- **Authentication Keys**: For accessing the endpoint (if using Key auth)
- **Resource IDs**: For integration with other services
- **Resource Names**: For Azure portal navigation

Example output:
```
Model Router Endpoint URL: https://myproject-model-router-prod.eastus.inference.ml.azure.com/score
Primary Key: abc123...
AI Hub Name: myproject-ai-hub-prod-abc123
```

## 🔧 Using the Model Router

### REST API Example

```bash
# Using the deployed Model Router endpoint
curl -X POST "https://your-endpoint-url/score" \
  -H "Authorization: Bearer YOUR_KEY" \
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

endpoint_url = "https://your-endpoint-url/score"
api_key = "your-api-key"

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

---

**Note**: This deployment replaces custom FastAPI implementations with Azure AI Foundry's native Model Router capabilities, providing enterprise-grade intelligent routing with built-in cost optimization.
