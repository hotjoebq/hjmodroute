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
