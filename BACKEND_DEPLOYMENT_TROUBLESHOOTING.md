# Backend Deployment Troubleshooting Guide

## Current Issue - STATUS REGRESSION
The Azure App Service backend at `hjmrdevproj-backend-dev-nyuxwr.azurewebsites.net` has **regressed** from HTTP 503 back to HTTP 403 "Site Disabled". This indicates:

- ❌ **Regression**: App Service has stopped running again (reverted from HTTP 503 to HTTP 403)
- 🎯 **Root Cause**: App Service needs to be **started first**, then backend code deployed
- 📋 **Two-Step Process**: 1) Start App Service, 2) Deploy FastAPI code via Advanced Tools (Kudu)

**Status Progression:**
- Initial: HTTP 403 "Site Disabled" (App Service stopped)
- Temporary: HTTP 503 "Application Error" (App Service running, application failing to start)
- **Current**: HTTP 403 "Site Disabled" (App Service stopped again)
- Target: HTTP 200 with proper JSON responses

User reports that the Azure Portal Deployment Center does not show an upload option.

## ⭐ RECOMMENDED: VS Code Azure Extension Deployment

**See the comprehensive deployment guide**: [COMPREHENSIVE_DEPLOYMENT_GUIDE.md](./COMPREHENSIVE_DEPLOYMENT_GUIDE.md)

The **correct** VS Code Azure extension method uses the Azure Explorer sidebar (NOT Command Palette):
1. Install Azure App Service extension
2. Sign in via Command Palette → "Azure: Sign In"
3. Extract `webapp-code/backend.zip` to a local folder
4. Azure Explorer → Right-click App Service → "Deploy to Web App..."
5. Select extracted folder (not ZIP file)

## Two-Step Deployment Process

### Step 1: Start the App Service - REQUIRED FIRST
1. Go to Azure Portal → App Services → `hjmrdevproj-backend-dev-nyuxwr`
2. Click **"Overview"** in the left sidebar
3. If the status shows "Stopped", click **"Start"** button
4. Wait for status to change to "Running"
5. Verify the service is running before proceeding to Step 2

### Step 2: Deploy Backend Code via Advanced Tools (Kudu) - AFTER STARTING

### Method 1: Advanced Tools (Kudu) - RECOMMENDED
1. Go to Azure Portal → App Services → `hjmrdevproj-backend-dev-nyuxwr`
2. Click **"Advanced Tools"** in the left sidebar
3. Click **"Go"** button (opens Kudu console in new tab)
4. In Kudu, click **"Debug console"** → **"CMD"** or **"PowerShell"**
5. Navigate to `/site/wwwroot` directory
6. Extract `webapp-code/backend.zip` locally first
7. Drag and drop all extracted files into the `/site/wwwroot` folder
8. Restart the App Service: Azure Portal → Overview → Restart

### Method 2: FTP Deployment
1. Go to Azure Portal → App Services → `hjmrdevproj-backend-dev-nyuxwr`
2. Click **"Deployment Center"** in the left sidebar
3. Look for **"FTPS credentials"** or **"Local Git"** tab
4. Get FTP endpoint, username, and password
5. Use FTP client (FileZilla, WinSCP) to upload extracted files
6. Upload to `/site/wwwroot/` directory

### Method 3: Configuration → General Settings
1. Go to Azure Portal → App Services → `hjmrdevproj-backend-dev-nyuxwr`
2. Click **"Configuration"** in the left sidebar
3. Go to **"General settings"** tab
4. Look for **"Stack settings"** or **"Runtime stack"** options
5. Verify Python runtime is configured correctly

### Method 4: VS Code Azure Extension
1. Install **Azure App Service** extension in VS Code
2. Sign in to Azure account
3. Right-click on the App Service in Azure explorer
4. Select **"Deploy to Web App"**
5. Choose the extracted backend folder or ZIP file

## Verification Steps

After deployment using any method:

1. **Check App Service Status**:
   ```bash
   curl -I https://hjmrdevproj-backend-dev-nyuxwr.azurewebsites.net/
   ```
   Expected: HTTP 200 (not 403 or 503)

2. **Test Health Endpoint**:
   ```bash
   curl https://hjmrdevproj-backend-dev-nyuxwr.azurewebsites.net/health
   ```
   Expected: `{"status": "healthy", "timestamp": "..."}`

3. **Test Chat Endpoint**:
   ```bash
   curl -X POST https://hjmrdevproj-backend-dev-nyuxwr.azurewebsites.net/chat \
     -H "Content-Type: application/json" \
     -d '{"messages": [{"role": "user", "content": "Hello"}], "azure_endpoint": "test", "azure_api_key": "test"}'
   ```

4. **End-to-End Test**:
   - Open frontend: https://black-meadow-061e0720f.1.azurestaticapps.net
   - Configure Settings with valid Azure AI Foundry credentials
   - Send test message through chat interface
   - Verify no HTTP 405 errors occur

## Troubleshooting Common Issues

### "Site Disabled" Error (HTTP 403) - RESOLVED
- ✅ App Service is now running (no longer stopped or disabled)
- This status has been resolved and progressed to HTTP 503

### "Application Error" (HTTP 503) - CURRENT ISSUE
- **Root Cause**: FastAPI application code not properly deployed to `/site/wwwroot`
- **Solution**: Deploy backend code using Advanced Tools (Kudu) method
- **Verification**: Check that `main.py`, `requirements.txt`, and `startup.sh` exist in `/site/wwwroot`
- **Logs**: Check Application Logs: Monitoring → Log stream for Python startup errors
- **Runtime**: Verify Python runtime is configured correctly in Configuration → General settings

### Missing Files After Upload
- Ensure all files are uploaded to `/site/wwwroot/`
- Check that `main.py` and `requirements.txt` are present
- Verify file permissions and structure

### Runtime Errors
- Check Application Insights or Log Analytics
- Verify environment variables are set correctly
- Ensure Python version compatibility

## Backend Package Details

- **File**: `webapp-code/backend.zip` (8KB)
- **Contents**: FastAPI application with main.py, requirements.txt, startup.sh
- **Runtime**: Python 3.9+ with uvicorn server
- **Endpoints**: `/`, `/health`, `/chat` (POST)

## Next Steps After Successful Deployment

1. **Immediate Verification**:
   ```bash
   # Should return HTTP 200 instead of HTTP 503
   curl https://hjmrdevproj-backend-dev-nyuxwr.azurewebsites.net/health
   # Expected: {"status": "healthy", "timestamp": 1750632400.123}
   ```

2. **Monitor Status Change**:
   ```bash
   ./monitor-backend-deployment.sh --continuous
   # Will automatically detect when backend becomes healthy
   ```

3. **Test Chat Functionality**:
   - Open frontend: https://black-meadow-061e0720f.1.azurestaticapps.net
   - Configure Settings with valid Azure AI Foundry credentials
   - Send test message - should work without HTTP 405 errors

4. **Verify End-to-End Integration**:
   - Test various prompt complexities
   - Verify model routing and cost estimation
   - Confirm no HTTP 405 "Method Not Allowed" errors
