# Backend Deployment Troubleshooting Guide

## Current Issue
The Azure App Service backend at `hjmrdevproj-backend-dev-nyuxwr.azurewebsites.net` is returning HTTP 403 "Site Disabled" instead of serving the FastAPI application. User reports that the Azure Portal Deployment Center does not show an upload option.

## Alternative Azure Portal Deployment Methods

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

### "Site Disabled" Error (HTTP 403)
- App Service is stopped or disabled
- Go to Overview → Start the App Service
- Check if there are any configuration issues

### "Application Error" (HTTP 503)
- Application failed to start
- Check Application Logs: Monitoring → Log stream
- Verify Python runtime and dependencies

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

1. Monitor backend status with monitoring script
2. Test frontend-to-backend connectivity
3. Verify Azure AI Foundry Model Router integration
4. Configure proper authentication and routing
