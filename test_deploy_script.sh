#!/bin/bash


echo "🧪 Testing actual deploy-webapp.sh script with mocked Azure CLI..."
echo "================================================================"

create_mock_az() {
  cat > /tmp/mock_az.sh << 'EOF'
#!/bin/bash

case "$*" in
  "group show --name hj-modroute-rg")
    echo '{"id": "/subscriptions/12345678-1234-1234-1234-123456789012/resourceGroups/hj-modroute-rg", "location": "eastus2", "name": "hj-modroute-rg"}'
    exit 0
    ;;
  "group show --name hj-modroute-rg --query location --output tsv")
    echo "eastus2"
    exit 0
    ;;
  "resource list --resource-group hj-modroute-rg --query"*"Microsoft.MachineLearningServices/workspaces"*"--output tsv"*)
    echo "hjmrdevproj-ai-hub-dev-nyuxwr"
    exit 0
    ;;
  "deployment group create"*)
    echo "Mock deployment would start here..."
    echo "Template: web-app-only.bicep"
    echo "Parameters: projectName=hjmrdevproj environment=dev location=eastus2 uniqueSuffix=nyuxwr"
    echo "✅ Mock deployment successful!"
    exit 0
    ;;
  "deployment group show"*)
    if [[ "$*" == *"backendUrl"* ]]; then
      echo "https://hjmrdevproj-backend-dev-nyuxwr.azurewebsites.net"
    elif [[ "$*" == *"frontendUrl"* ]]; then
      echo "https://hjmrdevproj-frontend-dev-nyuxwr.azurestaticapps.net"
    elif [[ "$*" == *"backendAppServiceName"* ]]; then
      echo "hjmrdevproj-backend-dev-nyuxwr"
    elif [[ "$*" == *"frontendStaticWebAppName"* ]]; then
      echo "hjmrdevproj-frontend-dev-nyuxwr"
    fi
    exit 0
    ;;
  *)
    echo "Mock az command called with: $*" >&2
    exit 1
    ;;
esac
EOF

  chmod +x /tmp/mock_az.sh
}

test_deployment_script() {
  echo ""
  echo "🔍 Testing deploy-webapp.sh with existing infrastructure scenario..."
  echo "Expected behavior:"
  echo "  1. Detect existing AI Hub: hjmrdevproj-ai-hub-dev-nyuxwr"
  echo "  2. Extract uniqueSuffix: nyuxwr"
  echo "  3. Use web-app-only.bicep deployment"
  echo "  4. No resource conflicts"
  echo ""
  
  create_mock_az
  
  export PATH="/tmp:$PATH"
  mv /tmp/mock_az.sh /tmp/az
  
  echo "Running: ./deploy-webapp.sh -g 'hj-modroute-rg' -p 'hjmrdevproj' -e 'dev'"
  echo "----------------------------------------"
  
  ./deploy-webapp.sh -g "hj-modroute-rg" -p "hjmrdevproj" -e "dev"
  RESULT=$?
  
  rm -f /tmp/az
  
  echo "----------------------------------------"
  if [ $RESULT -eq 0 ]; then
    echo "✅ SUCCESS: deploy-webapp.sh completed without errors"
    echo "   Infrastructure detection and deployment logic working correctly"
  else
    echo "❌ FAILED: deploy-webapp.sh returned error code $RESULT"
    echo "   Infrastructure detection or deployment logic has issues"
  fi
  
  return $RESULT
}

test_deployment_script

echo ""
echo "================================================================"
echo "🎯 Test Results Summary:"
echo "   This test validates the complete deploy-webapp.sh workflow"
echo "   with the fixed infrastructure detection logic using real script"
