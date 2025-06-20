# Azure AI Foundry Model Router - Complete Deployment Guide

This is the **master deployment guide** that walks you through the complete process of deploying Azure AI Foundry with Model Router functionality. Follow these steps in order for a successful deployment.

## 📋 Overview

The deployment process consists of **4 main phases**:

1. **Infrastructure Deployment** - Deploy Azure AI Foundry resources using Bicep
2. **Manual Model Router Setup** - ⚠️ **CRITICAL MANUAL STEP** - Deploy Model Router through Azure portal
3. **Web Application Deployment** - Deploy testing interface (optional)
4. **Configuration & Testing** - Configure runtime settings and test functionality

---

## 🚀 Phase 1: Infrastructure Deployment

**📖 Follow:** [`README.md`](./README.md) - Main infrastructure deployment guide

### Quick Start Options:

#### Option A: Automated Script (Recommended)
```bash
./deploy-webapp.sh -g "YOUR_RESOURCE_GROUP" -p "YOUR_PROJECT_NAME" -e "dev"
```

#### Option B: Direct Azure CLI
```bash
az deployment group create \
  --resource-group "YOUR_RESOURCE_GROUP" \
  --template-file main.bicep \
  --parameters @parameters/parameters-dev.json
```

### What Gets Deployed:
- ✅ AI Hub (central workspace)
- ✅ AI Project (project-level workspace)
- ✅ Supporting resources (Storage, Key Vault, Container Registry, AI Services)
- ✅ Web application infrastructure (App Service, Static Web Apps)

### ⚠️ Important Notes:
- **S0 SKU** is used for AI Services (requires quota approval in some regions)
- **Model Router is NOT deployed yet** - this happens in Phase 2
- Save the deployment outputs (AI Hub name, AI Project name) for Phase 2

---

## 🔧 Phase 2: Manual Model Router Setup

**📖 Follow:** [`MANUAL_MODEL_ROUTER_DEPLOYMENT.md`](./MANUAL_MODEL_ROUTER_DEPLOYMENT.md)

### ⚠️ **CRITICAL MANUAL STEP**

**Why Manual?** Model Router is a preview feature that requires manual deployment through the Azure AI Foundry portal. The Bicep templates create the infrastructure, but you must manually deploy the Model Router endpoint.

### Step-by-Step Process:

1. **Navigate to Azure AI Foundry Portal**
   - Go to [https://ai.azure.com](https://ai.azure.com)
   - Sign in with your Azure credentials

2. **Select Your AI Project**
   - Find the project created in Phase 1: `{projectName}-ai-project-{environment}-{uniqueSuffix}`

3. **Deploy Model Router**
   - Navigate to "Models + endpoints" → "Create new deployment"
   - Select "model-router" from the models list
   - Configure deployment settings:
     - **Deployment name**: `{projectName}-model-router-{environment}`
     - **Authentication**: Key (recommended for testing)
     - **Instance type**: Standard_DS3_v2
     - **Instance count**: 1

4. **Configure Routing Strategy**
   - Set to "cost-optimized" for best cost savings
   - Configure content filtering as needed

5. **Save Deployment Details**
   - **Endpoint URL**: Copy for Phase 4 configuration
   - **Primary Key**: Copy for Phase 4 configuration

### ✅ Verification:
- Test the Model Router in the Azure portal playground
- Verify intelligent routing is working
- Confirm endpoint URL and API key are accessible

---

## 🌐 Phase 3: Web Application Deployment (Optional)

**📖 Follow:** [`README_WEBAPP_DEPLOYMENT.md`](./README_WEBAPP_DEPLOYMENT.md)

### When to Use:
- You want a user-friendly testing interface for your Model Router
- You need to demonstrate intelligent routing capabilities
- You want real-time cost tracking and metrics

### ⚡ Intelligent Deployment:
The deployment script automatically detects existing infrastructure and deploys accordingly:

```bash
# Deploy with application code (auto-detects existing infrastructure)
./deploy-webapp.sh -g "YOUR_RESOURCE_GROUP" -p "YOUR_PROJECT_NAME" -e "dev" --deploy-code
```

### 🔍 How It Works:
- **Existing Infrastructure**: Script detects AI Foundry components and deploys only web application
- **Fresh Deployment**: Script deploys complete infrastructure + web application
- **Automatic Detection**: Uses AI Hub presence to determine deployment strategy

### What Gets Deployed:
- 🌐 React frontend (Azure Static Web Apps)
- 🔧 FastAPI backend (Azure App Service)
- 📊 Interactive testing interface
- 💰 Real-time cost tracking

---

## ⚙️ Phase 4: Configuration & Testing

**📖 Follow:** [`CONFIGURATION_GUIDE.md`](./CONFIGURATION_GUIDE.md)

### Runtime Configuration:

1. **Open the Web Application** (if deployed in Phase 3)
   - Use the frontend URL from deployment outputs

2. **Configure Model Router Connection**
   - Click "Settings" in the web interface
   - Enter the **Endpoint URL** from Phase 2
   - Enter the **Primary Key** from Phase 2

3. **Test Functionality**
   - Try simple prompts (should route to cost-effective models)
   - Try complex prompts (should route to more capable models)
   - Monitor cost optimization and routing decisions

### Direct API Testing:
```bash
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

---

## 📚 Additional Documentation

### Detailed Guides:
- **[`README.md`](./README.md)** - Complete infrastructure deployment reference
- **[`MANUAL_MODEL_ROUTER_DEPLOYMENT.md`](./MANUAL_MODEL_ROUTER_DEPLOYMENT.md)** - Detailed Model Router setup
- **[`README_WEBAPP_DEPLOYMENT.md`](./README_WEBAPP_DEPLOYMENT.md)** - Web application deployment
- **[`CONFIGURATION_GUIDE.md`](./CONFIGURATION_GUIDE.md)** - Configuration examples and troubleshooting

### Parameter Files:
- **[`parameters/parameters-dev.json`](./parameters/parameters-dev.json)** - Development environment
- **[`parameters/parameters-prod.json`](./parameters/parameters-prod.json)** - Production environment

### Deployment Scripts:
- **[`deploy-webapp.sh`](./deploy-webapp.sh)** - Main deployment automation script

---

## 🔍 Troubleshooting

### Common Issues:

1. **Phase 1 - Infrastructure Deployment Fails**
   - Check Azure CLI authentication: `az login`
   - Verify resource group exists
   - Ensure S0 SKU quota is available in your region

2. **Phase 2 - Model Router Not Available**
   - Verify AI Project was created successfully
   - Check that AI Services connection is configured
   - Ensure Model Router is available in your Azure region

3. **Phase 3 - Web App Deployment Issues**
   - Review App Service logs in Azure portal
   - Check Static Web App deployment status
   - Verify all required resources are deployed

4. **Phase 4 - Configuration Problems**
   - Double-check endpoint URL format
   - Verify API key is correct and active
   - Test Model Router directly in Azure portal first

### Getting Help:
- Check Azure portal for resource status and logs
- Review the detailed documentation files listed above
- Test each phase independently before proceeding to the next

---

## ✅ Success Checklist

- [ ] **Phase 1**: Infrastructure deployed successfully (AI Hub, AI Project, supporting resources)
- [ ] **Phase 2**: Model Router deployed manually through Azure portal
- [ ] **Phase 3**: Web application deployed (if desired)
- [ ] **Phase 4**: Runtime configuration completed and tested
- [ ] **Verification**: Model Router responds to API calls with intelligent routing

**🎉 Congratulations!** Your Azure AI Foundry Model Router is now fully deployed and ready for intelligent AI model routing with cost optimization.
