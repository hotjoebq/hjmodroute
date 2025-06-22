# Manual Azure Portal Deployment Guide

## When CLI Methods Fail

If both SWA CLI and Azure CLI methods fail, use this manual deployment method via Azure Portal.

## Step-by-Step Instructions

### 1. Download the Frontend Package
- Locate `webapp-code/frontend.zip` in your repository (132KB)
- Download this file to your local machine

### 2. Access Azure Portal
1. Open https://portal.azure.com in your browser
2. Sign in with your Azure credentials
3. Ensure you're in the correct subscription

### 3. Navigate to Static Web App
1. In the search bar, type "Static Web Apps"
2. Click on "Static Web Apps" service
3. Find and click on `hjmrdevproj-frontend-dev-nyuxwr`

### 4. Verify Current State
1. Click "Overview" in the left sidebar
2. Click "Browse" to open the current site
3. You should see "Congratulations on your new site!" placeholder page
4. Note the URL: https://black-meadow-061e0720f.1.azurestaticapps.net

### 5. Deploy New Content

#### Method A: Deployment Center (Recommended)
1. In the Static Web App, click "Deployment" in the left sidebar
2. Look for "Deployment Center" or "Source" tab
3. If you see "Upload" or "Manual deployment" option, click it
4. Upload the `frontend.zip` file
5. Wait for deployment to complete (2-3 minutes)

#### Method B: Configuration (Alternative)
1. Click "Configuration" in the left sidebar
2. Look for "Application files" or "Static content" section
3. Upload the `frontend.zip` file
4. Save the configuration

#### Method C: API Management (Advanced)
1. Click "API Management" in the left sidebar
2. Look for deployment or upload options
3. Upload the `frontend.zip` file

### 6. Monitor Deployment
1. Go to "Deployment" → "Deployment history"
2. Watch for the new deployment to appear
3. Status should change from "In Progress" to "Succeeded"
4. This typically takes 2-3 minutes

### 7. Verify Success
1. Refresh the frontend URL: https://black-meadow-061e0720f.1.azurestaticapps.net
2. **Expected Result**: "Azure AI Foundry Model Router" interface
3. **NOT Expected**: "Congratulations on your new site!" placeholder
4. Test the chat interface and Settings button

### 8. Clear Cache if Needed
If you still see the placeholder page:
1. Clear browser cache (Ctrl+Shift+Delete)
2. Try incognito/private browsing mode
3. Wait 2-3 minutes for Azure CDN to update
4. Check deployment history for any errors

## Troubleshooting

### Can't Find Upload Option?
- Try different sections: Deployment, Configuration, API Management
- Look for "Browse" or "Files" sections
- Check if there's a "GitHub" or "Source control" section with manual options

### Upload Fails?
- Ensure file is under 100MB (current: 132KB ✅)
- Try extracting the ZIP and uploading individual files
- Check file permissions and browser settings

### Still Shows Placeholder?
- Wait 5 minutes for propagation
- Clear all browser data
- Try different browser or device
- Check Azure Portal deployment logs

### Permission Errors?
- Ensure you have "Static Web Apps Contributor" role
- Check subscription permissions
- Contact Azure administrator if needed

## Alternative: Extract and Upload Files

If ZIP upload doesn't work:

1. Extract `frontend.zip` locally
2. Upload individual files:
   - `index.html` (main file)
   - `assets/` folder (contains JS and CSS)
3. Maintain the same directory structure

## Success Verification

✅ **Deployment Successful When:**
- Frontend URL shows "Azure AI Foundry Model Router" title
- Chat interface with message input box is visible
- Settings button is present and clickable
- No "Congratulations" text anywhere on the page
- Browser console shows no critical errors (F12 → Console)

❌ **Deployment Failed If:**
- Still shows "Congratulations on your new site!"
- Blank page or error messages
- Missing chat interface or buttons
- Console shows 404 errors for assets

## Next Steps After Success

1. Test the Settings page functionality
2. Configure backend API connection
3. Test message sending and receiving
4. Verify cost calculations and routing work correctly

The monitoring script will automatically detect successful deployment and notify you.
