#!/bin/bash
set -e

BACKEND_URL="$1"
if [ -z "$BACKEND_URL" ]; then
  echo "Usage: $0 <backend-url>"
  exit 1
fi

echo "🔧 Updating Model Router application code with backend URL: $BACKEND_URL"

mkdir -p /home/ubuntu/hjmodroute/webapp-code

echo "📦 Packaging backend code..."
cd /home/ubuntu/azure-model-router-webapp/backend
zip -r /home/ubuntu/hjmodroute/webapp-code/backend.zip . -x "*.pyc" "__pycache__/*" ".env"

echo "🎨 Building frontend with production API URL..."
cd /home/ubuntu/azure-model-router-webapp/frontend
sed "s|__BACKEND_URL__|$BACKEND_URL|g" .env.production > .env.local
npm run build

echo "📦 Packaging frontend code..."
cd dist
zip -r /home/ubuntu/hjmodroute/webapp-code/frontend.zip .

echo "✅ Updated webapp-code packages with backend URL: $BACKEND_URL"
