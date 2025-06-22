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
  
  if swa login --subscription-id "$(az account show --query id --output tsv)" --resource-group "$RESOURCE_GROUP" --app-name "$FRONTEND_APP_NAME" && \
     swa deploy --env production; then
    echo "✅ Frontend deployment completed successfully via SWA CLI!"
    frontend_deployed=true
  else
    echo "   ❌ SWA CLI method failed, trying Azure CLI methods..."
  fi
  
  cd ..
  rm -rf frontend-deploy-temp
else
  echo "   ❌ SWA CLI not found, installing..."
  if npm install -g @azure/static-web-apps-cli; then
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
    
    if swa login --subscription-id "$(az account show --query id --output tsv)" --resource-group "$RESOURCE_GROUP" --app-name "$FRONTEND_APP_NAME" && \
       swa deploy --env production; then
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
  echo "   Attempting method 2: az staticwebapp environment set"
  if az staticwebapp environment set \
    --name "$FRONTEND_APP_NAME" \
    --environment-name default \
    --source webapp-code/frontend.zip; then
    
    echo "✅ Frontend deployment completed successfully!"
    frontend_deployed=true
  else
    echo "   ❌ Method 2 failed, trying with resource group..."
    
    if az staticwebapp environment set \
      --name "$FRONTEND_APP_NAME" \
      --environment-name default \
      --source webapp-code/frontend.zip \
      --resource-group "$RESOURCE_GROUP"; then
      
      echo "✅ Frontend deployment completed successfully!"
      frontend_deployed=true
    else
      echo "   ❌ Method 3 failed, trying deployment create..."
      
      if az staticwebapp deployment create \
        --name "$FRONTEND_APP_NAME" \
        --resource-group "$RESOURCE_GROUP" \
        --source webapp-code/frontend.zip; then
        
        echo "✅ Frontend deployment completed successfully!"
        frontend_deployed=true
      fi
    fi
  fi
fi

if [ "$frontend_deployed" = false ]; then
  echo "❌ All automated deployment methods failed"
  echo "Please use manual deployment via Azure Portal"
fi
