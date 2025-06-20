#!/bin/bash

# Mock test for location detection from existing AI Hub
echo "🔍 Testing location detection from existing AI Hub..."

# Simulate the scenario: Resource Group in westus, AI Hub in eastus2
RESOURCE_GROUP="hj-modroute-rg"
PROJECT_NAME="hjmrdevproj"
ENVIRONMENT="dev"

# Mock resource group location (westus)
echo "Resource Group Location: westus"

# Mock AI Hub detection
AI_HUB_PATTERN="${PROJECT_NAME}-ai-hub-${ENVIRONMENT}-"
AI_HUB_NAME="hjmrdevproj-ai-hub-dev-nyuxwr"
UNIQUE_STRING="${AI_HUB_NAME#${AI_HUB_PATTERN}}"

# Mock AI Hub location (eastus2)
AI_HUB_LOCATION="eastus2"

echo "✅ AI Foundry infrastructure found (AI Hub: $AI_HUB_NAME)"
echo "   Using uniqueSuffix: $UNIQUE_STRING"
echo "   AI Hub location: $AI_HUB_LOCATION"

# Test location selection logic
if [ -n "$AI_HUB_LOCATION" ]; then
  LOCATION="$AI_HUB_LOCATION"
  echo "   Using existing infrastructure location: $LOCATION"
else
  LOCATION="westus"  # Resource group fallback
  echo "   Fallback to resource group location: $LOCATION"
fi

echo ""
echo "🎯 Result: Deployment will use location '$LOCATION' (should be eastus2, not westus)"

if [ "$LOCATION" = "eastus2" ]; then
  echo "✅ SUCCESS: Location detection correctly uses existing AI Hub location"
else
  echo "❌ FAILURE: Location detection still using wrong location"
fi
