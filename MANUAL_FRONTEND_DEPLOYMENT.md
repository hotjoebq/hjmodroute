# Manual Frontend Deployment - Step by Step

## Current Status
- ❌ Frontend showing: "Congratulations on your new site!" (placeholder page)
- ✅ Backend working: https://hjmrdevproj-backend-dev-nyuxwr.azurewebsites.net
- ✅ Frontend.zip ready: `/home/ubuntu/hjmodroute/webapp-code/frontend.zip` (132KB)
- ❌ Azure CLI not authenticated (preventing automated deployment)

## Manual Deployment via Azure Portal (5 minutes)

### Step 1: Access Azure Portal
1. Open https://portal.azure.com in your browser
2. Sign in with your Azure credentials

### Step 2: Navigate to Static Web App
1. In the search bar, type "Static Web Apps"
2. Click on "Static Web Apps" service
3. Find and click on `hjmrdevproj-frontend-dev-nyuxwr`

### Step 3: Verify Current State
1. Click "Overview" in the left sidebar
2. Click "Browse" to open the current site
3. Confirm you see "Congratulations on your new site!" placeholder

### Step 4: Upload Frontend Code
1. In the Static Web App, click "Deployment" in the left sidebar
2. Click on the "Source" tab
3. Click the "Upload" button
4. Select the file: `webapp-code/frontend.zip` from your local machine
   - **File location**: `/home/ubuntu/hjmodroute/webapp-code/frontend.zip`
   - **File size**: 132KB
5. Click "Upload" to start deployment

### Step 5: Monitor Deployment
1. Watch the deployment progress in "Deployment history"
2. Wait 2-3 minutes for deployment to complete
3. Status should change from "In Progress" to "Succeeded"

### Step 6: Verify Success
1. Refresh the frontend URL: https://black-meadow-061e0720f.1.azurestaticapps.net
2. You should now see:
   - ✅ "Azure AI Foundry Model Router" title
   - ✅ Chat interface with message input box
   - ✅ Settings button in top right
   - ❌ NO "Congratulations on your new site!" message

## Expected Result After Deployment

The frontend should show the Model Router interface:
```
Azure AI Foundry Model Router
[Settings] button

Chat Interface:
┌─────────────────────────────────────┐
│ Type your message here...           │
└─────────────────────────────────────┘
[Send] button
```

## If Manual Deployment Fails

### Alternative 1: GitHub Actions (if repo connected)
1. Connect your GitHub repository to the Static Web App
2. Push changes to trigger automatic deployment

### Alternative 2: Azure CLI (after authentication)
```bash
# Authenticate first
az login

# Deploy frontend
az staticwebapp environment set \
  --name hjmrdevproj-frontend-dev-nyuxwr \
  --environment-name default \
  --source webapp-code/frontend.zip \
  --resource-group hj-modroute-rg
```

### Alternative 3: VS Code Extension
1. Install "Azure Static Web Apps" extension in VS Code
2. Sign in to Azure
3. Deploy directly from VS Code

## Troubleshooting

### Still showing placeholder after upload?
- Wait 2-3 minutes for Azure CDN to update
- Clear browser cache (Ctrl+F5 or Cmd+Shift+R)
- Try incognito/private browsing mode
- Check deployment history for errors

### Upload fails?
- Ensure file size is under 100MB (current: 132KB ✅)
- Try different browser
- Check Azure permissions (need "Static Web Apps Contributor" role)

### Can't find the Static Web App?
- Verify resource group: `hj-modroute-rg`
- App name: `hjmrdevproj-frontend-dev-nyuxwr`
- Check correct Azure subscription

## Next Steps After Successful Deployment

1. **Test the Model Router Interface**
   - Open https://black-meadow-061e0720f.1.azurestaticapps.net
   - Click "Settings" to configure Azure Model Router
   - Enter your Model Router endpoint and credentials

2. **Verify Backend Connection**
   - Test sending a message in the chat interface
   - Check that responses come from the backend API
   - Monitor network requests in browser dev tools (F12)

3. **Configure Model Router**
   - Follow the Azure AI Foundry Model Router setup guide
   - Test different prompt complexities
   - Verify cost calculations and routing decisions
