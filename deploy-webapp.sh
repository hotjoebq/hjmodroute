#!/bin/bash


set -e

check_azure_auth() {
  if ! az account show &> /dev/null; then
    echo "❌ Error: Azure CLI not authenticated"
    echo "   Please run 'az login' to authenticate before deployment"
    exit 1
  fi
  
  ACCOUNT_NAME=$(az account show --query 'name' --output tsv)
  echo "✅ Azure CLI authenticated (Account: $ACCOUNT_NAME)"
}

check_dependencies() {
  local missing_deps=false
  
  if ! command -v jq &> /dev/null; then
    echo "⚠️  Warning: jq not found. FTP deployment fallback may not work."
    echo "   Install jq: sudo apt-get install jq (Ubuntu/Debian) or brew install jq (macOS)"
    echo "   Windows: Download from https://stedolan.github.io/jq/download/"
    missing_deps=true
  fi
  
  if [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]] || [[ -n "$WINDIR" ]]; then
    echo "🪟 Windows environment detected"
    echo "   Recommendation: Use Git Bash, PowerShell, or WSL for best compatibility"
    echo "   If you see 'command not found' errors, try running in PowerShell"
  fi
  
  local az_version=$(az --version 2>/dev/null | head -n1 | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+' || echo "unknown")
  if [ "$az_version" != "unknown" ]; then
    echo "✅ Azure CLI version: $az_version"
  else
    echo "⚠️  Warning: Could not determine Azure CLI version"
    echo "   Ensure Azure CLI is properly installed and in PATH"
  fi
  
  if [ "$missing_deps" = true ]; then
    echo ""
    echo "💡 Some dependencies are missing but deployment can continue with reduced functionality"
  fi
}

validate_app_service() {
  local app_name="$1"
  local resource_group="$2"
  
  echo "🔍 Validating Azure App Service connectivity..."
  
  if ! az webapp show --name "$app_name" --resource-group "$resource_group" &> /dev/null; then
    echo "❌ Error: Azure App Service '$app_name' not found in resource group '$resource_group'"
    echo "   Please ensure the infrastructure deployment completed successfully"
    return 1
  fi
  
  local app_state=$(az webapp show --name "$app_name" --resource-group "$resource_group" --query 'state' --output tsv)
  if [ "$app_state" != "Running" ]; then
    echo "⚠️  Warning: Azure App Service '$app_name' is in state: $app_state"
    echo "   Deployment may fail if the service is not running"
  fi
  
  echo "✅ Azure App Service '$app_name' is accessible"
  return 0
}

deploy_run_from_package() {
  local resource_group="$1"
  local app_name="$2"
  local package_path="$3"
  
  echo "📦 Attempting Run from Package deployment..."
  
  local base_name=$(echo "$app_name" | cut -c1-15)  # Limit to 15 chars for safety
  local timestamp=$(date +%s)
  local short_timestamp=$(echo $timestamp | tail -c 6)
  
  local storage_account_names=(
    "${base_name}pkg${short_timestamp}"
    "hjmrpkg${short_timestamp}"
    "modelpkg${short_timestamp}"
    "azpkg${timestamp}"
  )
  
  local container_name="packages"
  local storage_account_name=""
  local storage_created=false
  
  local location=$(az group show --name "$resource_group" --query location --output tsv 2>/dev/null || echo "eastus")
  
  echo "🔧 Attempting to create temporary storage account..."
  for name in "${storage_account_names[@]}"; do
    name=$(echo "$name" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]//g' | cut -c1-24)
    
    echo "   Trying storage account name: $name"
    if az storage account create \
      --name "$name" \
      --resource-group "$resource_group" \
      --location "$location" \
      --sku Standard_LRS \
      --kind StorageV2 \
      --allow-blob-public-access true &> /dev/null; then
      
      storage_account_name="$name"
      storage_created=true
      echo "✅ Created storage account: $storage_account_name"
      break
    else
      echo "   ❌ Failed to create storage account: $name"
    fi
  done
  
  if [ "$storage_created" = false ]; then
    echo "❌ Failed to create storage account with all attempted names"
    echo "   This may be due to:"
    echo "   1. Storage account name conflicts (names must be globally unique)"
    echo "   2. Insufficient permissions to create storage accounts"
    echo "   3. Azure subscription limits or quotas"
    echo "   4. Network connectivity issues"
    echo ""
    echo "🔧 Alternative: Use existing storage account"
    echo "   1. Create a storage account manually in Azure Portal"
    echo "   2. Upload your ZIP file to a blob container"
    echo "   3. Set WEBSITE_RUN_FROM_PACKAGE to the blob URL"
    echo "   4. Example commands:"
    echo "      az storage blob upload --file $package_path --name backend.zip --container-name packages --account-name YOUR_STORAGE"
    echo "      az webapp config appsettings set --resource-group $resource_group --name $app_name --settings WEBSITE_RUN_FROM_PACKAGE='https://YOUR_STORAGE.blob.core.windows.net/packages/backend.zip'"
    return 1
  fi
  
  local storage_key=$(az storage account keys list \
    --account-name "$storage_account_name" \
    --resource-group "$resource_group" \
    --query '[0].value' \
    --output tsv)
  
  if ! az storage container create \
    --name "$container_name" \
    --account-name "$storage_account_name" \
    --account-key "$storage_key" \
    --public-access blob &> /dev/null; then
    echo "❌ Failed to create storage container"
    return 1
  fi
  
  local blob_name="backend-$(date +%Y%m%d-%H%M%S).zip"
  echo "📤 Uploading package to blob storage..."
  if ! az storage blob upload \
    --file "$package_path" \
    --name "$blob_name" \
    --container-name "$container_name" \
    --account-name "$storage_account_name" \
    --account-key "$storage_key" &> /dev/null; then
    echo "❌ Failed to upload package to blob storage"
    return 1
  fi
  
  local package_url=$(az storage blob url \
    --name "$blob_name" \
    --container-name "$container_name" \
    --account-name "$storage_account_name" \
    --account-key "$storage_key" \
    --output tsv)
  
  echo "📦 Package uploaded to: $package_url"
  
  echo "⚙️  Configuring App Service to run from package..."
  if ! az webapp config appsettings set \
    --resource-group "$resource_group" \
    --name "$app_name" \
    --settings WEBSITE_RUN_FROM_PACKAGE="$package_url" &> /dev/null; then
    echo "❌ Failed to configure run from package setting"
    return 1
  fi
  
  echo "🔄 Restarting App Service..."
  if ! az webapp restart \
    --resource-group "$resource_group" \
    --name "$app_name" &> /dev/null; then
    echo "❌ Failed to restart App Service"
    return 1
  fi
  
  echo "✅ Run from Package deployment completed successfully!"
  echo "   Package URL: $package_url"
  echo "   Storage Account: $storage_account_name (can be deleted after deployment)"
  return 0
}

verify_frontend_deployment() {
  local frontend_url="$1"
  local app_name="$2"
  
  echo "🔍 Verifying frontend deployment..."
  echo "   Frontend URL: $frontend_url"
  echo "   Expected: Model Router interface"
  echo "   Current: Check if showing placeholder page"
  echo ""
  echo "💡 To verify deployment success:"
  echo "   1. Open $frontend_url in your browser"
  echo "   2. Look for 'Azure AI Foundry Model Router' title"
  echo "   3. Should see chat interface, not 'Congratulations' placeholder"
  echo ""
  echo "🔧 If still showing placeholder after deployment:"
  echo "   1. Wait 2-3 minutes for Azure Static Web Apps to update"
  echo "   2. Clear browser cache (Ctrl+F5 or Cmd+Shift+R)"
  echo "   3. Try incognito/private browsing mode"
  echo "   4. Check Azure Portal → Static Web Apps → $app_name → Deployment history"
}

deploy_via_ftp() {
  local resource_group="$1"
  local app_name="$2"
  local package_path="$3"
  
  echo "📡 Attempting FTP deployment..."
  
  local ftp_info=$(az webapp deployment list-publishing-profiles \
    --resource-group "$resource_group" \
    --name "$app_name" \
    --query "[?publishMethod=='FTP']" \
    --output json 2>/dev/null)
  
  if [ -z "$ftp_info" ] || [ "$ftp_info" = "[]" ]; then
    echo "❌ Unable to retrieve FTP credentials"
    return 1
  fi
  
  local ftp_url=$(echo "$ftp_info" | jq -r '.[0].publishUrl')
  local ftp_username=$(echo "$ftp_info" | jq -r '.[0].userName')
  local ftp_password=$(echo "$ftp_info" | jq -r '.[0].userPWD')
  
  echo "🔧 FTP deployment requires manual steps:"
  echo "   1. Extract the ZIP file: unzip $package_path -d temp_deploy/"
  echo "   2. Use FTP client to upload files to: $ftp_url"
  echo "   3. Username: $ftp_username"
  echo "   4. Password: [hidden - check Azure Portal for FTP credentials]"
  echo "   5. Upload all files from temp_deploy/ to /site/wwwroot/"
  echo ""
  echo "🔧 FTP Client Options:"
  echo "   - Windows: Use WinSCP, FileZilla, or built-in FTP"
  echo "   - macOS/Linux: Use FileZilla, Cyberduck, or command line ftp"
  echo "   - Command line: ftp $ftp_url (then use username/password)"
  echo ""
  echo "📋 Alternative: Use Azure Portal"
  echo "   1. Go to Azure Portal → App Services → $app_name"
  echo "   2. Click 'Advanced Tools' → 'Go' (opens Kudu)"
  echo "   3. Click 'Debug console' → 'CMD' or 'PowerShell'"
  echo "   4. Navigate to /site/wwwroot and drag/drop files"
  
  return 1
}

deploy_via_existing_storage() {
  local resource_group="$1"
  local app_name="$2"
  local package_path="$3"
  
  echo "🔍 Attempting deployment using existing storage accounts..."
  
  local existing_storage=$(az storage account list \
    --resource-group "$resource_group" \
    --query '[0].name' \
    --output tsv 2>/dev/null)
  
  if [ -n "$existing_storage" ] && [ "$existing_storage" != "null" ]; then
    echo "✅ Found existing storage account: $existing_storage"
    
    local storage_key=$(az storage account keys list \
      --account-name "$existing_storage" \
      --resource-group "$resource_group" \
      --query '[0].value' \
      --output tsv 2>/dev/null)
    
    if [ -n "$storage_key" ]; then
      local container_name="packages"
      local blob_name="backend-$(date +%Y%m%d-%H%M%S).zip"
      
      az storage container create \
        --name "$container_name" \
        --account-name "$existing_storage" \
        --account-key "$storage_key" \
        --public-access blob &> /dev/null
      
      echo "📤 Uploading package to existing storage account..."
      if az storage blob upload \
        --file "$package_path" \
        --name "$blob_name" \
        --container-name "$container_name" \
        --account-name "$existing_storage" \
        --account-key "$storage_key" &> /dev/null; then
        
        local package_url=$(az storage blob url \
          --name "$blob_name" \
          --container-name "$container_name" \
          --account-name "$existing_storage" \
          --account-key "$storage_key" \
          --output tsv)
        
        echo "📦 Package uploaded to: $package_url"
        
        echo "⚙️  Configuring App Service to run from package..."
        if az webapp config appsettings set \
          --resource-group "$resource_group" \
          --name "$app_name" \
          --settings WEBSITE_RUN_FROM_PACKAGE="$package_url" &> /dev/null; then
          
          echo "🔄 Restarting App Service..."
          if az webapp restart \
            --resource-group "$resource_group" \
            --name "$app_name" &> /dev/null; then
            
            echo "✅ Run from Package deployment using existing storage completed successfully!"
            echo "   Package URL: $package_url"
            echo "   Storage Account: $existing_storage"
            return 0
          fi
        fi
      fi
    fi
  fi
  
  echo "❌ No suitable existing storage account found or deployment failed"
  return 1
}

ENVIRONMENT="dev"
RESOURCE_GROUP=""
PROJECT_NAME=""
DEPLOY_CODE=false

while [[ $# -gt 0 ]]; do
  case $1 in
    -g|--resource-group)
      RESOURCE_GROUP="$2"
      shift 2
      ;;
    -e|--environment)
      ENVIRONMENT="$2"
      shift 2
      ;;
    -p|--project-name)
      PROJECT_NAME="$2"
      shift 2
      ;;
    --deploy-code)
      DEPLOY_CODE=true
      shift
      ;;
    -h|--help)
      echo "Usage: $0 -g <resource-group> [-e <environment>] [-p <project-name>] [--deploy-code]"
      echo "  -g, --resource-group    Azure resource group name (required)"
      echo "  -e, --environment       Environment (dev, test, prod) [default: dev]"
      echo "  -p, --project-name      Project name (required)"
      echo "  --deploy-code           Also deploy application code after infrastructure"
      exit 0
      ;;
    *)
      echo "Unknown option $1"
      exit 1
      ;;
  esac
done

if [ -z "$RESOURCE_GROUP" ]; then
  echo "Error: Resource group is required. Use -g <resource-group>"
  exit 1
fi

if [ -z "$PROJECT_NAME" ]; then
  echo "Error: Project name is required. Use -p <project-name>"
  exit 1
fi

check_infrastructure_exists() {
  echo "🔍 Checking if AI Foundry infrastructure already exists..."
  
  if ! az group show --name "$RESOURCE_GROUP" &> /dev/null; then
    echo "❌ Resource group $RESOURCE_GROUP not found"
    return 1
  fi
  
  AI_HUB_PATTERN="${PROJECT_NAME}-ai-hub-${ENVIRONMENT}-"
  
  AI_HUB_RESOURCES=$(az resource list --resource-group "$RESOURCE_GROUP" --query "[?contains(name, '${AI_HUB_PATTERN}') && type=='Microsoft.MachineLearningServices/workspaces'].name" --output tsv 2>/dev/null || echo "")
  
  if [ -n "$AI_HUB_RESOURCES" ]; then
    AI_HUB_NAME=$(echo "$AI_HUB_RESOURCES" | head -n1)
    UNIQUE_STRING="${AI_HUB_NAME#${AI_HUB_PATTERN}}"
    
    AI_HUB_LOCATION=$(az resource show --resource-group "$RESOURCE_GROUP" --name "$AI_HUB_NAME" --resource-type "Microsoft.MachineLearningServices/workspaces" --query 'location' --output tsv 2>/dev/null || echo "")
    
    WEBAPP_PLAN_NAME="${PROJECT_NAME}-webapp-plan-${ENVIRONMENT}-${UNIQUE_STRING}"
    EXISTING_WEBAPP=$(az resource list --resource-group "$RESOURCE_GROUP" --query "[?contains(name, '${WEBAPP_PLAN_NAME}') && type=='Microsoft.Web/serverfarms'].name" --output tsv 2>/dev/null || echo "")
    
    echo "✅ AI Foundry infrastructure found (AI Hub: $AI_HUB_NAME)"
    echo "   Using uniqueSuffix: $UNIQUE_STRING"
    if [ -n "$AI_HUB_LOCATION" ]; then
      echo "   AI Hub location: $AI_HUB_LOCATION"
    fi
    if [ -n "$EXISTING_WEBAPP" ]; then
      echo "   Existing web app resources detected - will skip recreation"
      SKIP_EXISTING_RESOURCES=true
    else
      SKIP_EXISTING_RESOURCES=false
    fi
    return 0
  else
    echo "❌ AI Foundry infrastructure not found. Please deploy infrastructure first using main.bicep"
    echo "   Searched for AI Hub pattern: ${AI_HUB_PATTERN}*"
    return 1
  fi
}

echo "🚀 Deploying Azure Model Router Web Application..."
echo "   Resource Group: $RESOURCE_GROUP"
echo "   Environment: $ENVIRONMENT"
echo "   Project Name: $PROJECT_NAME"
echo "   Deploy Code: $DEPLOY_CODE"
echo ""

check_azure_auth
check_dependencies
echo ""

if check_infrastructure_exists; then
  echo "📦 Deploying web application only (infrastructure exists)..."
  TEMPLATE_FILE="web-app-only.bicep"
  DEPLOYMENT_NAME="web-app-only-$(date +%Y%m%d-%H%M%S)"
  
  if [ -n "$AI_HUB_LOCATION" ]; then
    LOCATION="$AI_HUB_LOCATION"
    echo "   Using existing infrastructure location: $LOCATION"
  else
    LOCATION=$(az group show --name "$RESOURCE_GROUP" --query 'location' --output tsv)
    echo "   Fallback to resource group location: $LOCATION"
  fi
  
  TAGS='{
    "Environment": "'$ENVIRONMENT'",
    "Project": "'$PROJECT_NAME'",
    "DeployedBy": "deploy-webapp-script",
    "Purpose": "Web-Application-Only"
  }'
  
  az deployment group create \
    --resource-group "$RESOURCE_GROUP" \
    --template-file "$TEMPLATE_FILE" \
    --parameters projectName="$PROJECT_NAME" environment="$ENVIRONMENT" location="$LOCATION" uniqueSuffix="$UNIQUE_STRING" tags="$TAGS" skipExistingResources="$SKIP_EXISTING_RESOURCES" \
    --name "$DEPLOYMENT_NAME" \
    --output table
else
  echo "📦 Deploying full Azure infrastructure..."
  TEMPLATE_FILE="main.bicep"
  DEPLOYMENT_NAME="main"
  
  az deployment group create \
    --resource-group "$RESOURCE_GROUP" \
    --template-file "$TEMPLATE_FILE" \
    --parameters projectName="$PROJECT_NAME" environment="$ENVIRONMENT" \
    --output table
fi

echo ""
echo "📋 Getting deployment outputs..."
BACKEND_URL=$(az deployment group show \
  --resource-group "$RESOURCE_GROUP" \
  --name "$DEPLOYMENT_NAME" \
  --query 'properties.outputs.backendUrl.value' \
  --output tsv)

FRONTEND_URL=$(az deployment group show \
  --resource-group "$RESOURCE_GROUP" \
  --name "$DEPLOYMENT_NAME" \
  --query 'properties.outputs.frontendUrl.value' \
  --output tsv)

BACKEND_APP_NAME=$(az deployment group show \
  --resource-group "$RESOURCE_GROUP" \
  --name "$DEPLOYMENT_NAME" \
  --query 'properties.outputs.backendAppServiceName.value' \
  --output tsv)

FRONTEND_APP_NAME=$(az deployment group show \
  --resource-group "$RESOURCE_GROUP" \
  --name "$DEPLOYMENT_NAME" \
  --query 'properties.outputs.frontendStaticWebAppName.value' \
  --output tsv)

echo ""
echo "✅ Infrastructure deployment completed successfully!"
echo ""
echo "🌐 Application URLs:"
echo "   Backend API:  $BACKEND_URL"
echo "   Frontend App: $FRONTEND_URL"
echo ""

if [ "$DEPLOY_CODE" = true ]; then
  echo "📱 Updating and deploying application code..."
  
  echo "🔧 Updating application code with backend URL: $BACKEND_URL"
  ./update-webapp-code.sh "$BACKEND_URL"
  
  if [ ! -f "webapp-code/backend.zip" ]; then
    echo "❌ Error: webapp-code/backend.zip not found"
    exit 1
  fi
  
  if [ ! -f "webapp-code/frontend.zip" ]; then
    echo "❌ Error: webapp-code/frontend.zip not found"
    exit 1
  fi
  
  echo "🔧 Deploying backend code..."
  
  if ! validate_app_service "$BACKEND_APP_NAME" "$RESOURCE_GROUP"; then
    echo "❌ Backend deployment aborted due to App Service validation failure"
    exit 1
  fi
  
  if ! az webapp deploy \
    --resource-group "$RESOURCE_GROUP" \
    --name "$BACKEND_APP_NAME" \
    --src-path webapp-code/backend.zip \
    --type zip \
    --timeout 600; then
    
    echo "❌ Primary deployment method failed with connectivity error."
    echo ""
    echo "🔧 Attempting alternative deployment method 1: Run from Package..."
    
    if deploy_run_from_package "$RESOURCE_GROUP" "$BACKEND_APP_NAME" "webapp-code/backend.zip"; then
      echo "✅ Run from Package deployment succeeded!"
    else
      echo "❌ Run from Package deployment also failed."
      echo ""
      echo "🔧 Attempting alternative deployment method 2: Existing Storage..."
      
      if deploy_via_existing_storage "$RESOURCE_GROUP" "$BACKEND_APP_NAME" "webapp-code/backend.zip"; then
        echo "✅ Existing storage deployment succeeded!"
      else
        echo "❌ Existing storage deployment also failed."
        echo ""
        echo "🔧 Attempting alternative deployment method 3: FTP..."
        
        if deploy_via_ftp "$RESOURCE_GROUP" "$BACKEND_APP_NAME" "webapp-code/backend.zip"; then
          echo "✅ FTP deployment succeeded!"
        else
          echo "❌ All automated deployment methods failed."
          echo ""
          echo "🔍 Network Connectivity Troubleshooting:"
          echo "   This appears to be a persistent DNS resolution issue preventing connection to Azure endpoints."
          echo "   The error 'getaddrinfo failed' indicates network connectivity problems."
          echo ""
          echo "📋 Manual Deployment Options:"
          echo "   1. Azure Portal: Go to App Service → Deployment Center → Upload zip file"
          echo "   2. VS Code: Use Azure App Service extension to deploy"
          echo "   3. PowerShell: Use Publish-AzWebApp cmdlet"
          echo "   4. FTP: Use FTP credentials from Azure Portal (see above)"
          echo "   5. Run from Package: Upload ZIP to your own blob storage and set WEBSITE_RUN_FROM_PACKAGE"
          echo ""
          echo "🔧 Network Troubleshooting Steps:"
          echo "   1. Check VPN/proxy settings that might block Azure endpoints"
          echo "   2. Test DNS resolution: nslookup $BACKEND_APP_NAME.scm.azurewebsites.net"
          echo "   3. Try from different network (mobile hotspot, etc.)"
          echo "   4. Check corporate firewall blocking *.scm.azurewebsites.net"
          echo "   5. Verify Azure CLI version: az --version"
          echo ""
          echo "🔧 Storage Account Troubleshooting:"
          echo "   1. Check Azure subscription quotas: az account show"
          echo "   2. Verify permissions: az role assignment list --assignee \$(az account show --query user.name -o tsv)"
          echo "   3. Try different Azure region: az account list-locations --query '[].name'"
          echo "   4. Check storage account naming conflicts (names must be globally unique)"
          echo "   5. Verify resource group exists: az group show --name $RESOURCE_GROUP"
          echo ""
          echo "📁 Backend zip file ready at: $(pwd)/webapp-code/backend.zip"
          echo "   You can upload this file manually through Azure Portal"
          echo ""
          
          BACKEND_DEPLOYMENT_FAILED=true
        fi
      fi
    fi
  fi
  
  echo "🎨 Deploying frontend code..."
  
  local frontend_deployed=false
  
  if [ ! -f "webapp-code/frontend.zip" ]; then
    echo "❌ Frontend zip file not found at webapp-code/frontend.zip"
    echo "   Please run the deployment script with infrastructure deployment first"
    FRONTEND_DEPLOYMENT_FAILED=true
  else
    echo "✅ Frontend zip file found ($(du -h webapp-code/frontend.zip | cut -f1))"
    
    echo "   Attempting method 1: az staticwebapp environment set"
    if az staticwebapp environment set \
      --name "$FRONTEND_APP_NAME" \
      --environment-name default \
      --source webapp-code/frontend.zip 2>/dev/null; then
      
      echo "✅ Frontend deployment completed successfully!"
      frontend_deployed=true
    else
      echo "   ❌ Method 1 failed"
      
      echo "   Attempting method 2: az staticwebapp environment set with resource group"
      if az staticwebapp environment set \
        --name "$FRONTEND_APP_NAME" \
        --environment-name default \
        --source webapp-code/frontend.zip \
        --resource-group "$RESOURCE_GROUP" 2>/dev/null; then
        
        echo "✅ Frontend deployment completed successfully!"
        frontend_deployed=true
      else
        echo "   ❌ Method 2 failed"
        
        echo "   Attempting method 3: az staticwebapp deployment create"
        if az staticwebapp deployment create \
          --name "$FRONTEND_APP_NAME" \
          --resource-group "$RESOURCE_GROUP" \
          --source webapp-code/frontend.zip 2>/dev/null; then
          
          echo "✅ Frontend deployment completed successfully!"
          frontend_deployed=true
        else
          echo "   ❌ Method 3 failed"
        fi
      fi
    fi
  fi
  
  if [ "$frontend_deployed" = false ]; then
    echo "❌ All frontend deployment methods failed"
    echo "📁 Frontend zip file ready at: $(pwd)/webapp-code/frontend.zip"
    echo ""
    echo "🔧 Manual Frontend Deployment Options:"
    echo "   1. Azure Portal Method (Recommended):"
    echo "      a. Go to https://portal.azure.com"
    echo "      b. Navigate to Static Web Apps → $FRONTEND_APP_NAME"
    echo "      c. Click 'Overview' → 'Browse' to see current placeholder"
    echo "      d. Go to 'Deployment' → 'Source' → 'Upload'"
    echo "      e. Upload webapp-code/frontend.zip"
    echo "      f. Wait 2-3 minutes for deployment to complete"
    echo ""
    echo "   2. Azure CLI Method (if authenticated):"
    echo "      az staticwebapp environment set \\"
    echo "        --name $FRONTEND_APP_NAME \\"
    echo "        --environment-name default \\"
    echo "        --source webapp-code/frontend.zip \\"
    echo "        --resource-group $RESOURCE_GROUP"
    echo ""
    echo "   3. GitHub Actions Method:"
    echo "      Connect your repository for automated deployment"
    echo ""
    echo "💡 Common issues and solutions:"
    echo "   - Authentication: Run 'az login' before using Azure CLI"
    echo "   - Windows: Use PowerShell or Git Bash instead of Command Prompt"
    echo "   - Permissions: Ensure you have Static Web Apps Contributor role"
    echo "   - File size: Ensure frontend.zip is under 100MB (current: $(du -h webapp-code/frontend.zip | cut -f1))"
    echo "   - Network: Check VPN/firewall if Azure CLI commands fail"
    FRONTEND_DEPLOYMENT_FAILED=true
  fi
  
  echo ""
  if [ "$BACKEND_DEPLOYMENT_FAILED" = true ] || [ "$FRONTEND_DEPLOYMENT_FAILED" = true ]; then
    echo "⚠️  Deployment completed with issues - manual steps required"
    echo ""
    if [ "$BACKEND_DEPLOYMENT_FAILED" = true ]; then
      echo "🔧 Backend Manual Deployment:"
      echo "   1. Go to Azure Portal → App Services → $BACKEND_APP_NAME"
      echo "   2. Click 'Deployment Center' → 'FTPS credentials' or 'Local Git'"
      echo "   3. Upload webapp-code/backend.zip or use Git deployment"
    fi
    if [ "$FRONTEND_DEPLOYMENT_FAILED" = true ]; then
      echo "🔧 Frontend Manual Deployment:"
      echo "   1. Go to Azure Portal → Static Web Apps → $FRONTEND_APP_NAME"
      echo "   2. Click 'Overview' → 'Manage deployment token'"
      echo "   3. Upload webapp-code/frontend.zip manually"
    fi
  else
    echo "🎉 Full deployment completed successfully!"
  fi
  echo ""
  echo "🌐 Your Azure Model Router Web App is ready:"
  echo "   Frontend: $FRONTEND_URL"
  echo "   Backend:  $BACKEND_URL"
  echo ""
  
  if [ "$FRONTEND_DEPLOYMENT_FAILED" = true ]; then
    echo "⚠️  Frontend showing placeholder page - manual deployment required"
    verify_frontend_deployment "$FRONTEND_URL" "$FRONTEND_APP_NAME"
  else
    echo "✅ Frontend deployment completed - verifying..."
    verify_frontend_deployment "$FRONTEND_URL" "$FRONTEND_APP_NAME"
  fi
  
  echo ""
  echo "📝 Next Steps:"
  echo "1. Open the frontend URL in your browser: $FRONTEND_URL"
  echo "2. Verify you see the Model Router interface (not placeholder page)"
  echo "3. Click 'Settings' to configure your Azure Model Router credentials"
  echo "4. Test the application with various prompts"
else
  echo "📝 Next Steps:"
  echo "1. Deploy backend code:"
  echo "   Primary: az webapp deploy --resource-group $RESOURCE_GROUP --name $BACKEND_APP_NAME --src-path webapp-code/backend.zip --type zip"
  echo "   Alternative: Upload webapp-code/backend.zip via Azure Portal if connectivity issues occur"
  echo "2. Deploy frontend code:"
  echo "   Primary: az staticwebapp environment set --name $FRONTEND_APP_NAME --environment-name default --source webapp-code/frontend.zip"
  echo "   Alternative: Upload webapp-code/frontend.zip via Azure Portal"
  echo "3. Configure Azure Model Router credentials in the app"
  echo ""
  echo "💡 If you encounter DNS resolution errors (getaddrinfo failed):"
  echo "   This indicates network connectivity issues. Use Azure Portal for manual deployment."
fi
