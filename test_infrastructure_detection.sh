#!/bin/bash


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
    
    echo "✅ AI Foundry infrastructure found (AI Hub: $AI_HUB_NAME)"
    echo "   Using uniqueSuffix: $UNIQUE_STRING"
    return 0
  else
    echo "❌ AI Foundry infrastructure not found. Please deploy infrastructure first using main.bicep"
    echo "   Searched for AI Hub pattern: ${AI_HUB_PATTERN}*"
    return 1
  fi
}

az() {
  case "$*" in
    "group show --name hj-modroute-rg --query id --output tsv")
      echo "/subscriptions/12345678-1234-1234-1234-123456789012/resourceGroups/hj-modroute-rg"
      ;;
    "group show --name hj-modroute-rg")
      echo '{"id": "/subscriptions/12345678-1234-1234-1234-123456789012/resourceGroups/hj-modroute-rg", "location": "eastus2", "name": "hj-modroute-rg"}'
      ;;
    "group show --name hj-modroute-rg --query location --output tsv")
      echo "eastus2"
      ;;
    "resource list --resource-group hj-modroute-rg --query"*"Microsoft.MachineLearningServices/workspaces"*"--output tsv"*)
      echo "hjmrdevproj-ai-hub-dev-nyuxwr"
      ;;
    *)
      echo "Mock az command called with: $*" >&2
      return 1
      ;;
  esac
}

test_infrastructure_detection() {
  echo "🧪 Testing infrastructure detection with mock Azure CLI..."
  echo ""
  
  export RESOURCE_GROUP="hj-modroute-rg"
  export PROJECT_NAME="hjmrdevproj"
  export ENVIRONMENT="dev"
  
  echo "Test parameters:"
  echo "  RESOURCE_GROUP: $RESOURCE_GROUP"
  echo "  PROJECT_NAME: $PROJECT_NAME"
  echo "  ENVIRONMENT: $ENVIRONMENT"
  echo ""
  
  if check_infrastructure_exists; then
    echo ""
    echo "✅ SUCCESS: Infrastructure detection worked correctly!"
    echo "   Expected: ✅ AI Foundry infrastructure found"
    echo "   Expected uniqueSuffix: nyuxwr"
    echo "   Actual uniqueSuffix: $UNIQUE_STRING"
    
    if [ "$UNIQUE_STRING" = "nyuxwr" ]; then
      echo "✅ UniqueString extraction: PASSED"
    else
      echo "❌ UniqueString extraction: FAILED (expected 'nyuxwr', got '$UNIQUE_STRING')"
    fi
  else
    echo ""
    echo "❌ FAILED: Infrastructure detection failed"
    echo "   This means the script would attempt full deployment and cause conflicts"
  fi
}

test_no_infrastructure() {
  echo ""
  echo "🧪 Testing scenario with no existing infrastructure..."
  
  az() {
    case "$*" in
      "group show --name new-rg")
        echo '{"id": "/subscriptions/12345678-1234-1234-1234-123456789012/resourceGroups/new-rg", "location": "westus", "name": "new-rg"}'
        ;;
      "resource list --resource-group new-rg --query"*"Microsoft.MachineLearningServices/workspaces"*"--output tsv"*)
        echo ""
        ;;
      *)
        echo "Mock az command called with: $*" >&2
        return 1
        ;;
    esac
  }
  
  export RESOURCE_GROUP="new-rg"
  export PROJECT_NAME="newproject"
  export ENVIRONMENT="dev"
  
  if ! check_infrastructure_exists; then
    echo "✅ SUCCESS: Correctly detected no existing infrastructure"
    echo "   Script would use main.bicep for full deployment"
  else
    echo "❌ FAILED: Should have detected no infrastructure"
  fi
}

echo "🚀 Running comprehensive infrastructure detection tests..."
echo "=================================================="

test_infrastructure_detection
test_no_infrastructure

echo ""
echo "=================================================="
echo "🎯 Test Summary:"
echo "   These tests validate the fixed infrastructure detection logic"
echo "   The script should now correctly detect existing AI Hub resources"
echo "   and extract the proper uniqueSuffix for web-app-only deployment"
