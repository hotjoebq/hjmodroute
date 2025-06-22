#!/bin/bash


FRONTEND_URL="${1:-https://black-meadow-061e0720f.1.azurestaticapps.net}"

echo "🔍 Starting continuous monitoring for frontend deployment changes..."
echo "   Monitoring URL: $FRONTEND_URL"
echo "   Looking for: 'Azure AI Foundry Model Router' interface"
echo "   Current status: Checking..."
echo ""

while true; do
  if curl -s "$FRONTEND_URL" | grep -q "Azure AI Foundry Model Router"; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ✅ SUCCESS: Model Router interface detected!"
    echo "   Frontend deployment is now working correctly"
    echo "   You can now access the Model Router at: $FRONTEND_URL"
    break
  else
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ⏳ WAITING: Still showing placeholder page"
  fi
  sleep 30
done

echo ""
echo "🎉 Frontend deployment verification complete!"
echo "   Next steps:"
echo "   1. Open $FRONTEND_URL in your browser"
echo "   2. Click 'Settings' to configure Azure Model Router credentials"
echo "   3. Test the application with various prompts"
