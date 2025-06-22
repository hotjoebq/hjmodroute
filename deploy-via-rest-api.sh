#!/bin/bash

RESOURCE_GROUP="hj-modroute-rg"
APP_NAME="hjmrdevproj-frontend-dev-nyuxwr"

echo "🔑 Getting deployment token..."
if command -v az &> /dev/null && az account show &> /dev/null; then
  DEPLOYMENT_TOKEN=$(az staticwebapp secrets list \
    --name "$APP_NAME" \
    --resource-group "$RESOURCE_GROUP" \
    --query "properties.apiKey" \
    --output tsv 2>/dev/null)
  
  if [ -n "$DEPLOYMENT_TOKEN" ] && [ "$DEPLOYMENT_TOKEN" != "null" ]; then
    echo "✅ Got deployment token"
    
    echo "📦 Deploying via REST API..."
    if curl -X POST \
      -H "Authorization: Bearer $DEPLOYMENT_TOKEN" \
      -H "Content-Type: application/zip" \
      --data-binary @webapp-code/frontend.zip \
      "https://$APP_NAME.azurestaticapps.net/.auth/api/deployments" \
      --silent --show-error --fail; then
      
      echo "✅ Frontend deployment completed successfully via REST API!"
      echo "🔍 Verify at: https://black-meadow-061e0720f.1.azurestaticapps.net"
    else
      echo "❌ REST API deployment failed"
      exit 1
    fi
  else
    echo "❌ Could not get deployment token"
    exit 1
  fi
else
  echo "❌ Azure CLI not authenticated"
  echo "   Please run: az login"
  exit 1
fi
