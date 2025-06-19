#!/bin/bash


set -e

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

echo "🚀 Deploying Azure Model Router Web Application..."
echo "   Resource Group: $RESOURCE_GROUP"
echo "   Environment: $ENVIRONMENT"
echo "   Project Name: $PROJECT_NAME"
echo "   Deploy Code: $DEPLOY_CODE"
echo ""

echo "📦 Deploying Azure infrastructure..."
az deployment group create \
  --resource-group "$RESOURCE_GROUP" \
  --template-file main.bicep \
  --parameters projectName="$PROJECT_NAME" environment="$ENVIRONMENT" \
  --output table

echo ""
echo "📋 Getting deployment outputs..."
BACKEND_URL=$(az deployment group show \
  --resource-group "$RESOURCE_GROUP" \
  --name main \
  --query 'properties.outputs.backendUrl.value' \
  --output tsv)

FRONTEND_URL=$(az deployment group show \
  --resource-group "$RESOURCE_GROUP" \
  --name main \
  --query 'properties.outputs.frontendUrl.value' \
  --output tsv)

BACKEND_APP_NAME=$(az deployment group show \
  --resource-group "$RESOURCE_GROUP" \
  --name main \
  --query 'properties.outputs.backendAppServiceName.value' \
  --output tsv)

FRONTEND_APP_NAME=$(az deployment group show \
  --resource-group "$RESOURCE_GROUP" \
  --name main \
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
  echo "📱 Deploying application code..."
  
  if [ ! -f "webapp-code/backend.zip" ]; then
    echo "❌ Error: webapp-code/backend.zip not found"
    exit 1
  fi
  
  if [ ! -f "webapp-code/frontend.zip" ]; then
    echo "❌ Error: webapp-code/frontend.zip not found"
    exit 1
  fi
  
  echo "🔧 Deploying backend code..."
  az webapp deployment source config-zip \
    --resource-group "$RESOURCE_GROUP" \
    --name "$BACKEND_APP_NAME" \
    --src webapp-code/backend.zip
  
  echo "🎨 Deploying frontend code..."
  az staticwebapp environment set \
    --name "$FRONTEND_APP_NAME" \
    --environment-name default \
    --source webapp-code/frontend.zip
  
  echo ""
  echo "🎉 Full deployment completed successfully!"
  echo ""
  echo "🌐 Your Azure Model Router Web App is ready:"
  echo "   Frontend: $FRONTEND_URL"
  echo "   Backend:  $BACKEND_URL"
  echo ""
  echo "📝 Next Steps:"
  echo "1. Open the frontend URL in your browser"
  echo "2. Click 'Settings' to configure your Azure Model Router credentials"
  echo "3. Test the application with various prompts"
else
  echo "📝 Next Steps:"
  echo "1. Deploy backend code: az webapp deployment source config-zip --resource-group $RESOURCE_GROUP --name $BACKEND_APP_NAME --src webapp-code/backend.zip"
  echo "2. Deploy frontend code: az staticwebapp environment set --name $FRONTEND_APP_NAME --environment-name default --source webapp-code/frontend.zip"
  echo "3. Configure Azure Model Router credentials in the app"
fi
