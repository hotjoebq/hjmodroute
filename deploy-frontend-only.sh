#!/bin/bash

RESOURCE_GROUP=""
FRONTEND_APP_NAME=""

while [[ $# -gt 0 ]]; do
  case $1 in
    -g|--resource-group)
      RESOURCE_GROUP="$2"
      shift 2
      ;;
    -n|--app-name)
      FRONTEND_APP_NAME="$2"
      shift 2
      ;;
    -h|--help)
      echo "Usage: $0 -g <resource-group> -n <app-name>"
      echo "  -g, --resource-group    Azure resource group name (required)"
      echo "  -n, --app-name          Frontend Static Web App name (required)"
      echo ""
      echo "Example:"
      echo "  $0 -g hj-modroute-rg -n hjmrdevproj-frontend-dev-nyuxwr"
      exit 0
      ;;
    *)
      echo "Unknown option $1"
      exit 1
      ;;
  esac
done

if [ -z "$RESOURCE_GROUP" ] || [ -z "$FRONTEND_APP_NAME" ]; then
  echo "Error: Both resource group and app name are required"
  echo "Use -h for help"
  exit 1
fi

echo "🎨 Deploying frontend to Azure Static Web App..."
echo "   Resource Group: $RESOURCE_GROUP"
echo "   App Name: $FRONTEND_APP_NAME"
echo ""

if [ ! -f "webapp-code/frontend.zip" ]; then
  echo "❌ Frontend zip file not found at webapp-code/frontend.zip"
  exit 1
fi

echo "✅ Frontend zip file found ($(du -h webapp-code/frontend.zip | cut -f1))"

echo "🔧 Checking Azure CLI staticwebapp extension..."
if ! az extension list --query "[?name=='staticwebapp']" --output table | grep -q staticwebapp; then
  echo "   Installing staticwebapp extension..."
  if az extension add --name staticwebapp --allow-preview; then
    echo "   ✅ staticwebapp extension installed successfully"
  else
    echo "   ❌ Failed to install staticwebapp extension"
  fi
else
  echo "   ✅ staticwebapp extension already installed"
fi

echo "🔐 Checking Azure CLI authentication..."
if ! az account show &>/dev/null; then
  echo "   ❌ Azure CLI not authenticated. Please run: az login"
  echo "   Continuing with SWA CLI and manual methods..."
fi

frontend_deployed=false

echo "   Attempting method 1: SWA CLI deployment"
if command -v swa &> /dev/null; then
  mkdir -p frontend-deploy-temp
  cd frontend-deploy-temp
  unzip -q ../webapp-code/frontend.zip
  
  cat > swa-cli.config.json << EOF
{
  "\$schema": "https://aka.ms/azure/static-web-apps-cli/schema",
  "configurations": {
    "$FRONTEND_APP_NAME": {
      "appLocation": ".",
      "outputLocation": ".",
      "appName": "$FRONTEND_APP_NAME",
      "resourceGroup": "$RESOURCE_GROUP"
    }
  }
}
EOF
  
  if swa login --subscription-id "$(az account show --query id --output tsv 2>/dev/null)" --resource-group "$RESOURCE_GROUP" --app-name "$FRONTEND_APP_NAME" 2>/dev/null && \
     swa deploy --env production 2>/dev/null; then
    echo "✅ Frontend deployment completed successfully via SWA CLI!"
    frontend_deployed=true
  else
    echo "   ❌ SWA CLI method failed, trying Azure CLI methods..."
  fi
  
  cd ..
  rm -rf frontend-deploy-temp
else
  echo "   ❌ SWA CLI not found, installing..."
  if npm install -g @azure/static-web-apps-cli 2>/dev/null; then
    echo "   ✅ SWA CLI installed, retrying deployment..."
    mkdir -p frontend-deploy-temp
    cd frontend-deploy-temp
    unzip -q ../webapp-code/frontend.zip
    
    cat > swa-cli.config.json << EOF
{
  "\$schema": "https://aka.ms/azure/static-web-apps-cli/schema",
  "configurations": {
    "$FRONTEND_APP_NAME": {
      "appLocation": ".",
      "outputLocation": ".",
      "appName": "$FRONTEND_APP_NAME",
      "resourceGroup": "$RESOURCE_GROUP"
    }
  }
}
EOF
    
    if swa login --subscription-id "$(az account show --query id --output tsv 2>/dev/null)" --resource-group "$RESOURCE_GROUP" --app-name "$FRONTEND_APP_NAME" 2>/dev/null && \
       swa deploy --env production 2>/dev/null; then
      echo "✅ Frontend deployment completed successfully via SWA CLI!"
      frontend_deployed=true
    else
      echo "   ❌ SWA CLI method failed, trying Azure CLI methods..."
    fi
    
    cd ..
    rm -rf frontend-deploy-temp
  else
    echo "   ❌ Failed to install SWA CLI, using Azure CLI methods..."
  fi
fi

if [ "$frontend_deployed" = false ]; then
  echo "   Attempting method 2: Azure CLI with correct commands"
  
  if az staticwebapp --help &>/dev/null; then
    echo "   ✅ Azure CLI staticwebapp extension is working"
    
    if az account show &>/dev/null; then
      echo "   Attempting to get deployment token..."
      DEPLOYMENT_TOKEN=$(az staticwebapp secrets list \
        --name "$FRONTEND_APP_NAME" \
        --resource-group "$RESOURCE_GROUP" \
        --query "properties.apiKey" \
        --output tsv 2>/dev/null)
      
      if [ -n "$DEPLOYMENT_TOKEN" ] && [ "$DEPLOYMENT_TOKEN" != "null" ]; then
        echo "   ✅ Got deployment token, attempting REST API deployment..."
        
        if curl -X POST \
          -H "Authorization: Bearer $DEPLOYMENT_TOKEN" \
          -H "Content-Type: application/zip" \
          --data-binary @webapp-code/frontend.zip \
          "https://$FRONTEND_APP_NAME.azurestaticapps.net/.auth/api/deployments" \
          --silent --show-error; then
          
          echo "✅ Frontend deployment completed successfully via REST API!"
          frontend_deployed=true
        else
          echo "   ❌ REST API deployment failed"
        fi
      else
        echo "   ❌ Could not get deployment token"
      fi
    else
      echo "   ❌ Azure CLI not authenticated"
    fi
  else
    echo "   ❌ Azure CLI staticwebapp extension not working properly"
  fi
fi

if [ "$frontend_deployed" = false ]; then
  echo "❌ All automated deployment methods failed"
  echo ""
  echo "📋 Manual Deployment Required:"
  echo "   1. Go to Azure Portal: https://portal.azure.com"
  echo "   2. Navigate to Static Web Apps → $FRONTEND_APP_NAME"
  echo "   3. Go to Deployment → Source or Configuration"
  echo "   4. Upload webapp-code/frontend.zip ($(du -h webapp-code/frontend.zip | cut -f1))"
  echo "   5. Wait 2-3 minutes for deployment"
  echo "   6. Verify at: https://black-meadow-061e0720f.1.azurestaticapps.net"
  echo ""
  echo "📖 Detailed instructions: deploy-manual-portal.md"
  echo "🔧 Extension fix script: ./fix-azure-cli-extension.sh"
fi
