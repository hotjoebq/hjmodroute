# Working Deployment Guide - Azure AI Foundry Model Router

## Current Status
The Azure Static Web App at https://black-meadow-061e0720f.1.azurestaticapps.net is showing a default "Congratulations on your new site!" placeholder page instead of the Model Router interface.

## Root Cause
Both SWA CLI and Azure CLI deployment methods require authentication:
- **SWA CLI**: Hangs at "Checking Azure session..." waiting for user authentication
- **Azure CLI**: Requires `az login` authentication to access Static Web Apps resources
- **Extension Status**: ✅ Azure CLI staticwebapp extension now properly installed (v1.0.0)

## Working Solutions (Updated)

### Method 1: GitHub Actions Deployment (Most Reliable) ⭐ RECOMMENDED

**Automated deployment via GitHub Actions:**
```bash
# Trigger deployment workflow
gh workflow run deploy-frontend.yml --ref main

# Monitor deployment
gh run list --workflow=deploy-frontend.yml
```

**Setup Requirements:**
1. Get deployment token from Azure Portal → Static Web Apps → Overview → Manage deployment token
2. Add token as GitHub secret: `AZURE_STATIC_WEB_APPS_API_TOKEN`
3. Push changes to main branch or trigger workflow manually

### Method 2: REST API Deployment (Reliable Fallback)

**Direct deployment using REST API:**
```bash
# Authenticate with Azure CLI
az login

# Run REST API deployment script
chmod +x deploy-via-rest-api.sh
./deploy-via-rest-api.sh
```

### Method 3: Manual Azure Portal (When CLI methods fail)

**Step-by-Step Instructions:**

1. **Download the frontend package**
   - File: `webapp-code/frontend.zip` (132KB)
   - Contains: Model Router web application

2. **Access Azure Portal**
   - Go to: https://portal.azure.com
   - Sign in with your Azure credentials

3. **Navigate to Static Web App**
   - Search: "Static Web Apps"
   - Select: `hjmrdevproj-frontend-dev-nyuxwr`

4. **Current State Verification**
   - Click "Overview" → "Browse"
   - Should show: "Congratulations on your new site!" (placeholder)
   - URL: https://black-meadow-061e0720f.1.azurestaticapps.net

5. **Deploy New Content (Updated Portal Instructions)**
   
   **Option A: Overview → Manage Deployment**
   - Click "Overview" in left sidebar
   - Look for "Manage deployment token" section
   - Copy deployment token for REST API use
   
   **Option B: Functions → App Files**
   - Click "Functions" in left sidebar
   - Look for "App files" section if available
   - Upload `frontend.zip` if option exists
   
   **Note**: Direct file upload may not be available in all portal versions

6. **Monitor Deployment**
   - Go to "Deployment" → "Deployment history"
   - Wait for status: "In Progress" → "Succeeded"
   - Takes 2-3 minutes typically

7. **Verify Success**
   - Refresh: https://black-meadow-061e0720f.1.azurestaticapps.net
   - **Expected**: "Azure AI Foundry Model Router" interface
   - **NOT Expected**: "Congratulations" placeholder

### Method 3: PowerShell Script (Windows Users)

```powershell
# Navigate to repository directory
cd C:\CDrive\AI\AIFoundry\ModelRouterWeb\hjmodroute

# Run PowerShell deployment script
.\deploy-frontend.ps1 -ResourceGroup "hj-modroute-rg" -AppName "hjmrdevproj-frontend-dev-nyuxwr"
```

### Method 4: GitHub Actions (Automated CI/CD)

The repository includes a GitHub Actions workflow at `.github/workflows/deploy-frontend.yml` for automated deployment.

## Verification Steps

After any deployment method:

1. **Check Frontend URL**
   - https://black-meadow-061e0720f.1.azurestaticapps.net
   - Should display Model Router interface

2. **Test Functionality**
   - Chat interface loads
   - Settings button works
   - Message input box functional

3. **Backend Connectivity**
   - Settings page can configure backend URL
   - API calls work correctly

## Troubleshooting

### Still Shows Placeholder?
- Wait 2-3 minutes for Azure CDN update
- Clear browser cache (Ctrl+Shift+Delete)
- Try incognito/private browsing
- Check deployment history in Azure Portal

### Azure CLI Issues?
- Run: `az extension add --name staticwebapp --allow-preview`
- Verify: `az extension list | grep staticwebapp`
- Authenticate: `az login`

### Upload Fails?
- Ensure file is under 100MB (current: 132KB ✅)
- Check file permissions
- Try different browser
- Use Azure CLI as fallback

## Monitoring

The monitoring script is running and will automatically detect successful deployment:
```bash
# Check monitoring status
ps aux | grep monitor-deployment.sh

# View monitoring output
tail -f /tmp/deployment-monitor.log
```

## Success Criteria

✅ **Deployment Successful When:**
- Frontend shows "Azure AI Foundry Model Router" title
- Chat interface with input box visible
- Settings button present and clickable
- No "Congratulations" text anywhere

❌ **Deployment Failed If:**
- Still shows "Congratulations on your new site!"
- Blank page or error messages
- Missing chat interface components

## Next Steps After Success

1. Configure Azure Model Router credentials in Settings
2. Test various prompts to verify routing logic
3. Monitor cost optimization features
4. Verify backend API connectivity

The enhanced deployment scripts now include proper Azure CLI extension installation and multiple fallback methods to ensure reliable deployment.
