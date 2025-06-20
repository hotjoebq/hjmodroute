#!/bin/bash

test_uniquesuffix_extraction() {
  PROJECT_NAME="hjmrdevproj"
  ENVIRONMENT="dev"
  AI_HUB_PATTERN="${PROJECT_NAME}-ai-hub-${ENVIRONMENT}-"
  
  AI_HUB_NAME="hjmrdevproj-ai-hub-dev-nyuxwr"
  UNIQUE_STRING="${AI_HUB_NAME#${AI_HUB_PATTERN}}"
  
  echo "Testing uniqueSuffix extraction:"
  echo "AI_HUB_NAME: $AI_HUB_NAME"
  echo "AI_HUB_PATTERN: $AI_HUB_PATTERN"
  echo "Extracted UNIQUE_STRING: $UNIQUE_STRING"
  
  if [ "$UNIQUE_STRING" = "nyuxwr" ]; then
    echo "✅ Test passed: Correctly extracted uniqueSuffix"
  else
    echo "❌ Test failed: Expected 'nyuxwr', got '$UNIQUE_STRING'"
  fi
}

test_azure_cli_query() {
  echo ""
  echo "Testing Azure CLI query structure:"
  echo "az resource list --resource-group 'hj-modroute-rg' --query \"[?contains(name, 'hjmrdevproj-ai-hub-dev-') && type=='Microsoft.MachineLearningServices/workspaces'].name\" --output tsv"
}

echo "🧪 Testing infrastructure detection logic..."
test_uniquesuffix_extraction
test_azure_cli_query
echo ""
echo "✅ All tests completed"
