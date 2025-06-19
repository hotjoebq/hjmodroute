# Azure Model Router Web Application - Deployment Package

This package contains everything needed to deploy the Azure Model Router web application to your Azure subscription.

## 📁 Package Contents

```
azure-ai-foundry-bicep/
├── main.bicep                          # Main Bicep template (includes web app)
├── modules/
│   ├── web-app.bicep                   # Web application resources
│   ├── ai-hub.bicep                    # AI Hub resources
│   ├── ai-project.bicep                # AI Project resources
│   └── dependent-resources.bicep       # Storage, Key Vault, etc.
├── parameters/
│   └── parameters-webapp.json          # Parameter file for deployment
├── webapp-code/
│   ├── backend.zip                     # FastAPI backend application
│   └── frontend.zip                    # React frontend application
├── deploy-webapp.sh                    # Automated deployment script
├── AZURE_DEPLOYMENT_GUIDE.md          # Detailed deployment guide
└── README_WEBAPP_DEPLOYMENT.md        # This file
```

## 🚀 Quick Start

### Option 1: Automated Deployment (Recommended)
```bash
# Deploy infrastructure and application code
./deploy-webapp.sh -g "your-resource-group-name" --deploy-code
```

### Option 2: Step-by-Step Deployment
```bash
# 1. Deploy infrastructure only
./deploy-webapp.sh -g "your-resource-group-name"

# 2. Deploy application code manually (follow the output instructions)
```

### Option 3: Manual Bicep Deployment
```bash
# Deploy using Azure CLI directly
az deployment group create \
  --resource-group "your-resource-group-name" \
  --template-file main.bicep \
  --parameters @parameters/parameters-webapp.json
```

## 🏗️ What Gets Deployed

### Azure Resources
- **Azure App Service**: FastAPI backend (Linux, Python 3.11)
- **Azure Static Web Apps**: React frontend
- **App Service Plan**: Basic tier (B1) for cost optimization
- **AI Hub & Project**: For Azure AI Foundry integration (if not already deployed)
- **Supporting Resources**: Storage Account, Key Vault, Container Registry

### Application Features
- 🤖 Interactive chat interface for testing Azure Model Router
- 🧠 Intelligent routing visualization
- 💰 Real-time cost tracking and optimization
- ⚡ Performance metrics and complexity scoring
- 🔐 Secure runtime credential configuration

## 📋 Prerequisites

- Azure CLI installed and authenticated (`az login`)
- Azure subscription with appropriate permissions
- Resource group created (or use existing one)
- Azure AI Foundry Model Router deployed (`hj619-model-router`)

## 🔧 Configuration

After deployment, configure your Azure Model Router credentials:

1. Open the frontend URL in your browser
2. Click the "Settings" button
3. Enter your Azure Model Router endpoint URL and API key
4. Test with various prompts to see intelligent routing in action

## 📊 Expected Costs

- **App Service Plan (B1)**: ~$13/month
- **Static Web Apps (Free tier)**: $0/month
- **Storage Account**: ~$1-2/month
- **Application Insights**: ~$1-2/month

**Total estimated cost**: ~$15-17/month for the web application infrastructure.

## 🔍 Troubleshooting

### Common Issues
- **Deployment fails**: Check Azure CLI authentication and permissions
- **Backend not starting**: Review App Service logs in Azure portal
- **Frontend not loading**: Verify Static Web App deployment status
- **Authentication errors**: Ensure Model Router endpoint and API key are correct

### Getting Help
1. Check the detailed deployment guide: `AZURE_DEPLOYMENT_GUIDE.md`
2. Review Azure portal for resource status and logs
3. Test backend API directly using the provided endpoints

## 🌐 Architecture

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────────┐
│ Azure Static    │───▶│ Azure App Service│───▶│ Azure AI Foundry    │
│ Web Apps        │    │ (FastAPI)        │    │ Model Router        │
│ (React Frontend)│    │ (Backend API)    │    │ (hj619-model-router)│
└─────────────────┘    └──────────────────┘    └─────────────────────┘
```

The web application provides a user-friendly interface for testing and visualizing the intelligent routing capabilities of your Azure AI Foundry Model Router.
