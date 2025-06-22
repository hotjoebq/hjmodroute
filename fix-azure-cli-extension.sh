#!/bin/bash

echo "🔧 Fixing Azure CLI Static Web Apps Extension Issues..."

if ! command -v az &> /dev/null; then
    echo "❌ Azure CLI not found. Please install Azure CLI first:"
    echo "   Windows: https://aka.ms/installazurecliwindows"
    echo "   macOS: brew install azure-cli"
    echo "   Linux: curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash"
    exit 1
fi

echo "✅ Azure CLI found: $(az --version | head -1)"

echo "📋 Current Azure CLI extensions:"
az extension list --query "[].{Name:name, Version:version}" --output table

echo "🗑️  Removing existing staticwebapp extension..."
az extension remove --name staticwebapp 2>/dev/null || echo "   No existing extension to remove"

echo "📦 Installing latest staticwebapp extension..."
az extension add --name staticwebapp --allow-preview

echo "✅ Verifying staticwebapp extension installation..."
if az extension list --query "[?name=='staticwebapp']" --output table | grep -q staticwebapp; then
    echo "✅ staticwebapp extension installed successfully"
    
    echo "📋 Available staticwebapp commands:"
    az staticwebapp --help | grep -A 20 "Commands:"
    
    echo "🔐 Testing Azure authentication..."
    if az account show &>/dev/null; then
        echo "✅ Azure CLI authenticated"
        az account show --query "{Name:name, SubscriptionId:id}" --output table
    else
        echo "❌ Azure CLI not authenticated. Please run: az login"
    fi
else
    echo "❌ Failed to install staticwebapp extension"
    exit 1
fi

echo "🎯 Ready to deploy Static Web Apps!"
