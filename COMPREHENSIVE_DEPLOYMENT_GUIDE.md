# Comprehensive Backend Deployment Guide - Azure AI Foundry Model Router

## Current Issue Summary
The Azure App Service backend at `hjmrdevproj-backend-dev-nyuxwr.azurewebsites.net` is returning HTTP 503 "Application Error", causing HTTP 405 errors in the frontend chat interface. Multiple deployment methods have been attempted:

- ❌ **Kudu Advanced Tools**: User reports interface issues
- ❌ **FTP Deployment**: Authentication disabled for this web app
- ❌ **Previous VS Code Instructions**: Commands don't match user's actual VS Code interface

## Method 1: Corrected VS Code Azure Extension Deployment ⭐ RECOMMENDED

Based on the official Azure App Service extension documentation, here are the **correct** steps:

### Prerequisites
1. **Install Azure App Service Extension** (v0.26.2 or later)
   - VS Code Extensions → Search "Azure App Service" → Install
2. **Sign In to Azure**
   - Command Palette (Ctrl+Shift+P) → "Azure: Sign In"
   - Complete browser authentication

### Deployment Steps
1. **Extract Backend Files First**
   ```bash
   mkdir backend-extracted
   cd backend-extracted
   unzip ../webapp-code/backend.zip
   ```

2. **Deploy via Azure Explorer** (NOT Command Palette)
   - Open **Azure Explorer** in VS Code sidebar (Azure icon)
   - Expand **App Services** section
   - Find your subscription → Expand it
   - Locate `hjmrdevproj-backend-dev-nyuxwr`
   - **Right-click** the App Service → **"Deploy to Web App..."**
   - Select the `backend-extracted` folder (not the ZIP file)
   - Confirm deployment when prompted

3. **Monitor Deployment Progress**
   - VS Code will show deployment progress in Output panel
   - Wait for "Deployment successful" message

## Method 2: Azure CLI Direct Deployment

If VS Code method fails, try Azure CLI with different parameters:

```bash
# Authenticate first
az login

# Method 2A: Direct ZIP deployment
az webapp deploy \
  --resource-group "hj-modroute-rg" \
  --name "hjmrdevproj-backend-dev-nyuxwr" \
  --src-path webapp-code/backend.zip \
  --type zip \
  --timeout 600

# Method 2B: Alternative deployment command
az webapp deployment source config-zip \
  --resource-group "hj-modroute-rg" \
  --name "hjmrdevproj-backend-dev-nyuxwr" \
  --src webapp-code/backend.zip
```

## Method 3: PowerShell Deployment (Windows)

For Windows environments with PowerShell:

```powershell
# Install Azure PowerShell module if not installed
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

## Method 4: GitHub Actions Automated Deployment

Create automated deployment via GitHub Actions:

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
     push:
       paths:
         - 'webapp-code/backend.zip'
   
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

## Method 5: REST API Deployment

Direct deployment using Azure REST API:

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

## Verification Steps

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

## Troubleshooting Common Issues

### VS Code Azure Extension Issues
- **Problem**: "Deploy to Web App" option not visible
- **Solution**: Ensure you're right-clicking on the App Service itself, not a parent folder
- **Alternative**: Try refreshing Azure Explorer or signing out/in again

### Authentication Errors
- **Problem**: "Authentication failed" or "Access denied"
- **Solution**: Run `az login` or re-authenticate in VS Code
- **Check**: Verify you have "Website Contributor" role on the App Service

### Network Connectivity Issues
- **Problem**: DNS resolution errors or timeouts
- **Solution**: Try different network (mobile hotspot) or check VPN/proxy settings
- **Alternative**: Use GitHub Actions deployment method

### File Permission Issues
- **Problem**: "Cannot write to /site/wwwroot"
- **Solution**: Ensure App Service is running and not in read-only mode
- **Check**: Verify deployment slots are not causing conflicts

## Success Criteria

✅ **Deployment Successful When:**
- Backend health endpoint returns HTTP 200 (not 503)
- Chat endpoint accepts POST requests without HTTP 405 errors
- Frontend chat interface sends messages successfully
- No "Application Error" messages in browser

❌ **Deployment Failed If:**
- Still shows HTTP 503 "Application Error"
- HTTP 405 errors persist in frontend
- Health endpoint unreachable or returns errors
- VS Code deployment shows errors in Output panel

## Next Steps After Successful Deployment

1. **Immediate Verification**
   - Run monitoring script to confirm HTTP 200 status
   - Test chat functionality through frontend interface

2. **Performance Testing**
   - Send various prompt complexities to test routing logic
   - Verify cost estimation and model selection working correctly

3. **Documentation Update**
   - Update README.md with successful deployment method
   - Document any environment-specific requirements discovered

## Support Information

- **Backend Package**: webapp-code/backend.zip (8KB FastAPI application)
- **Resource Group**: hj-modroute-rg
- **App Service**: hjmrdevproj-backend-dev-nyuxwr
- **Frontend URL**: https://black-meadow-061e0720f.1.azurestaticapps.net
- **Backend URL**: https://hjmrdevproj-backend-dev-nyuxwr.azurewebsites.net

This guide provides multiple deployment methods to ensure successful backend deployment regardless of network restrictions or authentication issues.
