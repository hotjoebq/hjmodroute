# VS Code Azure Extension Deployment Guide - Azure AI Foundry Model Router

## Current Issue Summary
The user reports that VS Code Azure extension commands don't match the interface described in previous instructions. The backend at `hjmrdevproj-backend-dev-nyuxwr.azurewebsites.net` is returning HTTP 403 "Site Disabled", causing HTTP 405 errors in the frontend chat interface.

## ✅ Corrected VS Code Azure Extension Method

Based on the official Azure App Service extension documentation, here are the **exact steps** that should work:

### Prerequisites
1. **Install Azure App Service Extension**
   - Open VS Code Extensions (Ctrl+Shift+X)
   - Search for "Azure App Service" 
   - Install the extension by Microsoft

2. **Sign In to Azure**
   - Open Command Palette (Ctrl+Shift+P)
   - Type "Azure: Sign In"
   - Complete browser authentication

### Step-by-Step Deployment Process

#### Step 1: Extract Backend Files
```bash
# Create a local folder and extract the backend ZIP
mkdir backend-extracted
cd backend-extracted
unzip ../webapp-code/backend.zip
```

#### Step 2: Deploy via Azure Explorer (NOT Command Palette)
1. **Open Azure Explorer**
   - Click the Azure icon in VS Code sidebar (left side)
   - If you don't see it, go to View → Command Palette → "Azure: Focus on Azure View"

2. **Navigate to Your App Service**
   - In Azure Explorer, expand **"App Services"** section
   - Find your subscription and expand it
   - Locate `hjmrdevproj-backend-dev-nyuxwr`

3. **Deploy Using Right-Click Menu**
   - **Right-click** on `hjmrdevproj-backend-dev-nyuxwr`
   - Select **"Deploy to Web App..."** from the context menu
   - Choose the `backend-extracted` folder (NOT the ZIP file)
   - Confirm deployment when prompted

#### Step 3: Monitor Deployment
- VS Code will show deployment progress in the Output panel
- Wait for "Deployment successful" message
- Check for any error messages in the output

## 🔧 Alternative Methods If VS Code Fails

### Method 1: Azure CLI Direct Deployment
```bash
# Authenticate first
az login

# Deploy ZIP file directly
az webapp deploy \
  --resource-group "hj-modroute-rg" \
  --name "hjmrdevproj-backend-dev-nyuxwr" \
  --src-path webapp-code/backend.zip \
  --type zip \
  --timeout 600
```

### Method 2: PowerShell Deployment (Windows)
```powershell
# Install Azure PowerShell if needed
Install-Module -Name Az -AllowClobber -Scope CurrentUser

# Connect to Azure
Connect-AzAccount

# Deploy using PowerShell
Publish-AzWebApp `
  -ResourceGroupName "hj-modroute-rg" `
  -Name "hjmrdevproj-backend-dev-nyuxwr" `
  -ArchivePath "webapp-code\backend.zip" `
  -Force
```

### Method 3: GitHub Actions Automated Deployment
1. **Get Publish Profile**
   ```bash
   az webapp deployment list-publishing-profiles \
     --resource-group "hj-modroute-rg" \
     --name "hjmrdevproj-backend-dev-nyuxwr" \
     --xml
   ```

2. **Add as GitHub Secret**
   - Go to GitHub repository → Settings → Secrets and variables → Actions
   - Add new secret: `AZURE_WEBAPP_PUBLISH_PROFILE`
   - Paste the XML content from step 1

3. **Create Workflow File**
   Create `.github/workflows/deploy-backend.yml`:
   ```yaml
   name: Deploy Backend to Azure App Service
   on:
     workflow_dispatch:
   
   jobs:
     deploy:
       runs-on: ubuntu-latest
       steps:
       - uses: actions/checkout@v3
       
       - name: Extract Backend
         run: |
           mkdir -p backend-extracted
           unzip webapp-code/backend.zip -d backend-extracted
       
       - name: Deploy to Azure App Service
         uses: azure/webapps-deploy@v2
         with:
           app-name: 'hjmrdevproj-backend-dev-nyuxwr'
           publish-profile: ${{ secrets.AZURE_WEBAPP_PUBLISH_PROFILE }}
           package: backend-extracted
   ```

### Method 4: REST API Deployment
```bash
#!/bin/bash
# Get access token
ACCESS_TOKEN=$(az account get-access-token --query accessToken --output tsv)

# Upload ZIP file
curl -X POST \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/zip" \
  --data-binary @webapp-code/backend.zip \
  "https://hjmrdevproj-backend-dev-nyuxwr.scm.azurewebsites.net/api/zipdeploy"
```

## 🔍 Verification Steps

After any deployment method, verify success:

### 1. Check App Service Status
```bash
az webapp show \
  --resource-group "hj-modroute-rg" \
  --name "hjmrdevproj-backend-dev-nyuxwr" \
  --query "state" \
  --output tsv
```
Expected: "Running"

### 2. Test Health Endpoint
```bash
curl https://hjmrdevproj-backend-dev-nyuxwr.azurewebsites.net/health
```
Expected: `{"status": "healthy", "timestamp": "..."}`

### 3. Test Chat Endpoint
```bash
curl -X POST https://hjmrdevproj-backend-dev-nyuxwr.azurewebsites.net/chat \
  -H "Content-Type: application/json" \
  -d '{
    "messages": [{"role": "user", "content": "Hello"}],
    "azure_endpoint": "test",
    "azure_api_key": "test"
  }'
```

### 4. Monitor with Script
```bash
./monitor-backend-deployment.sh --continuous
```

### 5. End-to-End Frontend Test
- Open: https://black-meadow-061e0720f.1.azurestaticapps.net
- Configure Settings with valid Azure AI Foundry credentials
- Send test message through chat interface
- Verify no HTTP 405 errors occur

## 🚨 Troubleshooting Common VS Code Issues

### Issue: "Deploy to Web App" Option Not Visible
**Solutions:**
1. Ensure you're right-clicking on the App Service itself, not a parent folder
2. Try refreshing Azure Explorer (right-click → Refresh)
3. Sign out and sign back in: Command Palette → "Azure: Sign Out" then "Azure: Sign In"
4. Check that the Azure App Service extension is enabled and up to date

### Issue: Authentication Errors
**Solutions:**
1. Run `az login` in terminal first
2. Verify you have "Website Contributor" role on the App Service
3. Try signing out and back in to VS Code Azure extension

### Issue: Network Connectivity Problems
**Solutions:**
1. Try different network (mobile hotspot)
2. Check VPN/proxy settings
3. Use GitHub Actions deployment method instead

### Issue: File Permission Errors
**Solutions:**
1. Ensure App Service is running (not stopped)
2. Verify deployment slots are not causing conflicts
3. Check that the App Service is not in read-only mode

## ✅ Success Criteria

**Deployment Successful When:**
- Backend health endpoint returns HTTP 200 (not 403/503)
- Chat endpoint accepts POST requests without HTTP 405 errors
- Frontend chat interface sends messages successfully
- No "Application Error" or "Site Disabled" messages

**Current Status:**
- Backend URL: https://hjmrdevproj-backend-dev-nyuxwr.azurewebsites.net
- Current Status: HTTP 403 "Site Disabled" (App Service stopped)
- Target Status: HTTP 200 with proper JSON responses

## 📋 Next Steps After Successful Deployment

1. **Immediate Verification**
   - Run monitoring script to confirm HTTP 200 status
   - Test chat functionality through frontend interface

2. **Performance Testing**
   - Send various prompt complexities to test routing logic
   - Verify cost estimation and model selection working correctly

3. **Documentation Update**
   - Update README.md with successful deployment method
   - Document any environment-specific requirements discovered

## 📞 Support Information

- **Backend Package**: webapp-code/backend.zip (8KB FastAPI application)
- **Resource Group**: hj-modroute-rg
- **App Service**: hjmrdevproj-backend-dev-nyuxwr
- **Frontend URL**: https://black-meadow-061e0720f.1.azurestaticapps.net
- **Backend URL**: https://hjmrdevproj-backend-dev-nyuxwr.azurewebsites.net

This guide provides multiple deployment methods to ensure successful backend deployment regardless of VS Code interface variations or network restrictions.
