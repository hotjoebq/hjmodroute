# Frontend Deployment Guide - Azure Static Web Apps

## Issue: Placeholder Page Instead of Model Router Interface

If your Azure Static Web App shows "Congratulations on your new site!" instead of the Model Router interface, the frontend code was not successfully deployed.

**Root Cause**: The automated deployment failed because Azure CLI is not authenticated. The frontend.zip file (132KB) was created successfully but could not be deployed automatically.

## Quick Fix (Recommended)

### Option 1: SWA CLI Method (Most Reliable) ⭐ RECOMMENDED
This method uses the official Static Web Apps CLI and works reliably with existing apps:

```bash
# Install SWA CLI if not already installed
npm install -g @azure/static-web-apps-cli

# Create deployment directory
mkdir frontend-deploy && cd frontend-deploy
unzip ../webapp-code/frontend.zip

# Create SWA CLI configuration
cat > swa-cli.config.json << 'EOF'
{
  "$schema": "https://aka.ms/azure/static-web-apps-cli/schema",
  "configurations": {
    "hjmrdevproj-frontend-dev-nyuxwr": {
      "appLocation": ".",
      "outputLocation": ".",
      "appName": "hjmrdevproj-frontend-dev-nyuxwr",
      "resourceGroup": "hj-modroute-rg"
    }
  }
}
EOF

# Login and deploy
swa login --subscription-id $(az account show --query id --output tsv) --resource-group hj-modroute-rg --app-name hjmrdevproj-frontend-dev-nyuxwr
swa deploy --env production
```

### Option 2: Azure Portal (No CLI Required)
1. Go to [Azure Portal](https://portal.azure.com)
2. Navigate to **Static Web Apps** → `hjmrdevproj-frontend-dev-nyuxwr`
3. Click **Overview** → **Browse** to confirm placeholder page
4. Go to **Deployment** → **Source** → **Upload**
5. Upload `webapp-code/frontend.zip`
6. Wait 2-3 minutes for deployment
7. Refresh the frontend URL

### Option 3: Azure CLI (Fallback)
```bash
# Ensure Azure CLI is authenticated
az login

# Deploy using Azure CLI
az staticwebapp environment set \
  --name hjmrdevproj-frontend-dev-nyuxwr \
  --environment-name default \
  --source webapp-code/frontend.zip \
  --resource-group hj-modroute-rg
```

### Option 4: Standalone Script
```bash
chmod +x deploy-frontend-only.sh
./deploy-frontend-only.sh -g hj-modroute-rg -n hjmrdevproj-frontend-dev-nyuxwr
```

## Verification

After deployment:
1. Open https://black-meadow-061e0720f.1.azurestaticapps.net
2. Should see "Azure AI Foundry Model Router" title
3. Should see chat interface with message input
4. Should NOT see "Congratulations on your new site!"

## Troubleshooting

### Still showing placeholder after deployment?
- Wait 2-3 minutes for Azure to update
- Clear browser cache (Ctrl+F5)
- Try incognito/private browsing
- Check deployment history in Azure Portal

### Azure CLI authentication errors?
**This is the most common issue preventing automated deployment.**

```bash
# Authenticate with Azure
az login

# Verify correct subscription
az account show

# Check if Static Web Apps extension is installed
az extension list --query "[?name=='staticwebapp']"

# Install if missing
az extension add --name staticwebapp
```

### Permission errors?
- Ensure you have "Static Web Apps Contributor" role
- Check resource group permissions

### File size issues?
- Current frontend.zip is ~132KB (well under 100MB limit)
- If modified, ensure zip stays under 100MB

## Architecture

```
Azure Static Web Apps (Frontend)
├── Default Environment (Production)
│   ├── Source: webapp-code/frontend.zip
│   ├── Build: Pre-built React app
│   └── URL: https://black-meadow-061e0720f.1.azurestaticapps.net
└── Configuration
    ├── Backend API: https://hjmrdevproj-backend-dev-nyuxwr.azurewebsites.net
    └── Model Router: Manual configuration via UI
```

## Manual Deployment Steps (Detailed)

### Using Azure Portal
1. **Navigate to Static Web App**
   - Go to https://portal.azure.com
   - Search for "Static Web Apps"
   - Click on `hjmrdevproj-frontend-dev-nyuxwr`

2. **Verify Current State**
   - Click "Overview" → "Browse"
   - Should see placeholder page with "Congratulations on your new site!"

3. **Upload New Content**
   - Go to "Deployment" in left sidebar
   - Click "Source" tab
   - Click "Upload" button
   - Select `webapp-code/frontend.zip` from your local machine
   - Click "Upload"

4. **Monitor Deployment**
   - Watch deployment progress in "Deployment history"
   - Wait 2-3 minutes for completion
   - Status should change to "Succeeded"

5. **Verify Success**
   - Refresh the frontend URL
   - Should now see Model Router interface
   - Look for "Azure AI Foundry Model Router" title

### Using Azure CLI (Alternative)
```bash
# Ensure you're authenticated
az login

# Verify subscription
az account show

# Deploy frontend
az staticwebapp environment set \
  --name hjmrdevproj-frontend-dev-nyuxwr \
  --environment-name default \
  --source webapp-code/frontend.zip \
  --resource-group hj-modroute-rg

# Check deployment status
az staticwebapp show \
  --name hjmrdevproj-frontend-dev-nyuxwr \
  --resource-group hj-modroute-rg \
  --query "defaultHostname"
```

## Common Issues and Solutions

### Issue: "Command not found: az"
**Solution**: Install Azure CLI
```bash
# Windows (PowerShell)
Invoke-WebRequest -Uri https://aka.ms/installazurecliwindows -OutFile .\AzureCLI.msi; Start-Process msiexec.exe -Wait -ArgumentList '/I AzureCLI.msi /quiet'

# macOS
brew install azure-cli

# Linux
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
```

### Issue: "Authentication required"
**Solution**: Login to Azure
```bash
az login
az account set --subscription "your-subscription-id"
```

### Issue: "Permission denied"
**Solution**: Check role assignments
```bash
# Check your permissions
az role assignment list --assignee $(az account show --query user.name -o tsv)

# Required role: Static Web Apps Contributor
```

### Issue: "File not found: webapp-code/frontend.zip"
**Solution**: Ensure you're in the correct directory
```bash
# Check current directory
pwd

# Should be in /home/ubuntu/hjmodroute or similar
# List files to verify
ls -la webapp-code/

# If missing, run the full deployment script first
./deploy-webapp.sh -g hj-modroute-rg -p hjmrdevproj -e dev
```

### Issue: Deployment succeeds but still shows placeholder
**Solution**: Clear cache and wait
```bash
# Clear browser cache
# Chrome/Edge: Ctrl+Shift+Delete
# Firefox: Ctrl+Shift+Delete
# Safari: Cmd+Option+E

# Or use incognito/private browsing mode
# Wait 2-3 minutes for Azure CDN to update
```

## Verification Checklist

After deployment, verify:
- [ ] Frontend URL loads without errors
- [ ] Page title shows "Azure AI Foundry Model Router"
- [ ] Chat interface is visible
- [ ] Settings button is present
- [ ] No "Congratulations" placeholder text
- [ ] Console shows no critical errors (F12 → Console)
- [ ] Network requests to backend API work (F12 → Network)

## Next Steps After Successful Deployment

1. **Configure Model Router Connection**
   - Click "Settings" in the web app
   - Enter your Azure Model Router endpoint URL
   - Enter your API key
   - Test connection

2. **Test Functionality**
   - Send a test message
   - Verify response from Model Router
   - Check cost calculations
   - Test different prompt complexities

3. **Monitor Performance**
   - Check Azure Portal for Static Web App metrics
   - Monitor backend API performance
   - Review Model Router usage and costs
