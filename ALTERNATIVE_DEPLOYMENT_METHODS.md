# Alternative Deployment Methods for Azure Static Web Apps

## Issue: SWA CLI and Azure CLI Authentication Failures

Both SWA CLI and Azure CLI deployment methods have failed due to:
- SWA CLI: "StaticSitesClient" binary and network connectivity issues
- Azure CLI: Authentication requires interactive device code login

## Working Alternative Methods

### Method 1: Azure Portal Manual Upload (Most Reliable) ⭐ RECOMMENDED

1. **Download the frontend.zip file** (132KB) from your local repository
2. **Navigate to Azure Portal**: https://portal.azure.com
3. **Find your Static Web App**:
   - Search for "Static Web Apps"
   - Click on `hjmrdevproj-frontend-dev-nyuxwr`
4. **Upload the application**:
   - Go to "Overview" → Click "Browse" to confirm placeholder page
   - Go to "Deployment" → "Source" 
   - Look for upload or deployment options
   - Upload `webapp-code/frontend.zip`
5. **Wait for deployment** (2-3 minutes)
6. **Verify success**: https://black-meadow-061e0720f.1.azurestaticapps.net

### Method 2: GitHub Actions Deployment (Automated)

Create a GitHub Actions workflow for automated deployment:

```yaml
name: Deploy Frontend to Azure Static Web Apps
on:
  push:
    branches: [ main ]
  workflow_dispatch:

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3
    
    - name: Extract Frontend
      run: |
        mkdir -p frontend-extracted
        unzip webapp-code/frontend.zip -d frontend-extracted
    
    - name: Deploy to Azure Static Web Apps
      uses: Azure/static-web-apps-deploy@v1
      with:
        azure_static_web_apps_api_token: ${{ secrets.AZURE_STATIC_WEB_APPS_API_TOKEN }}
        repo_token: ${{ secrets.GITHUB_TOKEN }}
        action: "upload"
        app_location: "frontend-extracted"
        output_location: ""
```

### Method 3: PowerShell Deployment Script (Windows)

```powershell
# PowerShell script for Windows deployment
param(
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroup = "hj-modroute-rg",
    
    [Parameter(Mandatory=$true)]
    [string]$AppName = "hjmrdevproj-frontend-dev-nyuxwr"
)

Write-Host "🎨 Deploying frontend to Azure Static Web App..." -ForegroundColor Green

# Check if frontend.zip exists
if (-not (Test-Path "webapp-code\frontend.zip")) {
    Write-Error "❌ Frontend zip file not found at webapp-code\frontend.zip"
    exit 1
}

Write-Host "✅ Frontend zip file found" -ForegroundColor Green

# Try Azure CLI deployment
try {
    Write-Host "   Attempting Azure CLI deployment..." -ForegroundColor Yellow
    
    # Ensure user is logged in
    $account = az account show 2>$null | ConvertFrom-Json
    if (-not $account) {
        Write-Host "   Please login to Azure CLI first: az login" -ForegroundColor Red
        az login
    }
    
    # Deploy using Azure CLI
    az staticwebapp environment set `
        --name $AppName `
        --environment-name "default" `
        --source "webapp-code\frontend.zip" `
        --resource-group $ResourceGroup
    
    Write-Host "✅ Frontend deployment completed successfully!" -ForegroundColor Green
}
catch {
    Write-Error "❌ Azure CLI deployment failed: $_"
    Write-Host "📋 Manual deployment required via Azure Portal" -ForegroundColor Yellow
}
```

### Method 4: REST API Deployment (Advanced)

Direct deployment using Azure Static Web Apps REST API:

```bash
#!/bin/bash
# REST API deployment script

RESOURCE_GROUP="hj-modroute-rg"
APP_NAME="hjmrdevproj-frontend-dev-nyuxwr"
SUBSCRIPTION_ID=$(az account show --query id --output tsv)

# Get deployment token
DEPLOYMENT_TOKEN=$(az staticwebapp secrets list \
    --name $APP_NAME \
    --resource-group $RESOURCE_GROUP \
    --query "properties.apiKey" \
    --output tsv)

# Upload via REST API
curl -X POST \
    -H "Authorization: Bearer $DEPLOYMENT_TOKEN" \
    -H "Content-Type: application/zip" \
    --data-binary @webapp-code/frontend.zip \
    "https://$APP_NAME.azurestaticapps.net/.auth/api/deployments"
```

## Verification Steps

After any deployment method:

1. **Check the URL**: https://black-meadow-061e0720f.1.azurestaticapps.net
2. **Expected Result**: "Azure AI Foundry Model Router" interface
3. **NOT Expected**: "Congratulations on your new site!" placeholder
4. **Test Features**:
   - Chat interface loads
   - Settings button works
   - Backend API connectivity
   - Message sending functionality

## Troubleshooting

### Still showing placeholder after deployment?
- Wait 2-3 minutes for Azure CDN to update
- Clear browser cache (Ctrl+F5)
- Try incognito/private browsing
- Check Azure Portal deployment history

### Authentication errors?
- Use Azure Portal manual upload (Method 1)
- Ensure proper permissions in Azure subscription
- Check Static Web Apps Contributor role assignment

### File upload issues?
- Verify frontend.zip is under 100MB (current: 132KB ✅)
- Ensure zip file contains valid web application files
- Check for corrupted zip file

## Current Status

- ✅ Frontend.zip file ready (132KB)
- ❌ SWA CLI failed (network connectivity)
- ❌ Azure CLI failed (authentication required)
- ✅ Manual Azure Portal method available
- ✅ GitHub Actions workflow ready
- ✅ PowerShell script available
- ✅ Monitoring script running

## Next Steps

1. **Immediate**: Use Azure Portal manual upload (Method 1)
2. **Long-term**: Set up GitHub Actions for automated deployment
3. **Verification**: Confirm Model Router interface loads
4. **Testing**: Verify all functionality works correctly

The monitoring script will automatically detect when deployment succeeds.
