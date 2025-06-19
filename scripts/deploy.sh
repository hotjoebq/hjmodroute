#!/bin/bash

set -e

LOCATION="eastus"
ENVIRONMENT="dev"
PARAMETER_FILE=""
WHAT_IF=false

usage() {
    echo "Usage: $0 -g <resource-group-name> [-l <location>] [-e <environment>] [-p <parameter-file>] [-w]"
    echo ""
    echo "Options:"
    echo "  -g, --resource-group    Name of the Azure Resource Group to deploy to (required)"
    echo "  -l, --location         Azure region for deployment (default: eastus)"
    echo "  -e, --environment      Environment type: dev, test, or prod (default: dev)"
    echo "  -p, --parameter-file   Path to parameter file (optional, will use default based on environment)"
    echo "  -w, --what-if          Run deployment in what-if mode to preview changes"
    echo "  -h, --help             Display this help message"
}

while [[ $# -gt 0 ]]; do
    case $1 in
        -g|--resource-group)
            RESOURCE_GROUP_NAME="$2"
            shift 2
            ;;
        -l|--location)
            LOCATION="$2"
            shift 2
            ;;
        -e|--environment)
            ENVIRONMENT="$2"
            shift 2
            ;;
        -p|--parameter-file)
            PARAMETER_FILE="$2"
            shift 2
            ;;
        -w|--what-if)
            WHAT_IF=true
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "Unknown option $1"
            usage
            exit 1
            ;;
    esac
done

if [ -z "$RESOURCE_GROUP_NAME" ]; then
    echo "❌ Error: Resource group name is required"
    usage
    exit 1
fi

if [[ ! "$ENVIRONMENT" =~ ^(dev|test|prod)$ ]]; then
    echo "❌ Error: Environment must be dev, test, or prod"
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

echo "🚀 Starting Azure AI Foundry Model Router deployment..."
echo "📁 Working directory: $ROOT_DIR"
echo "🎯 Target Resource Group: $RESOURCE_GROUP_NAME"
echo "🌍 Location: $LOCATION"
echo "🏷️  Environment: $ENVIRONMENT"

if ! command -v az &> /dev/null; then
    echo "❌ Azure CLI is not installed. Please install Azure CLI first."
    exit 1
fi

if ! az account show &> /dev/null; then
    echo "❌ Not logged in to Azure. Please run 'az login' first."
    exit 1
fi

if [ -z "$PARAMETER_FILE" ]; then
    PARAMETER_FILE="$ROOT_DIR/parameters/parameters-$ENVIRONMENT.json"
fi

if [ ! -f "$PARAMETER_FILE" ]; then
    echo "❌ Parameter file not found: $PARAMETER_FILE"
    exit 1
fi

echo "📄 Using parameter file: $PARAMETER_FILE"

echo "🔍 Checking if resource group exists..."
if ! az group show --name "$RESOURCE_GROUP_NAME" &> /dev/null; then
    echo "📦 Creating resource group: $RESOURCE_GROUP_NAME"
    az group create --name "$RESOURCE_GROUP_NAME" --location "$LOCATION" --output table
    echo "✅ Resource group created successfully"
else
    echo "✅ Resource group already exists"
fi

echo "🔨 Building Bicep template..."
MAIN_BICEP_FILE="$ROOT_DIR/main.bicep"
BUILD_DIR="$ROOT_DIR/build"
mkdir -p "$BUILD_DIR"

az bicep build --file "$MAIN_BICEP_FILE" --outdir "$BUILD_DIR"
echo "✅ Bicep template built successfully"

if [ "$WHAT_IF" = true ]; then
    echo "🔍 Running what-if analysis..."
    az deployment group what-if \
        --resource-group "$RESOURCE_GROUP_NAME" \
        --template-file "$MAIN_BICEP_FILE" \
        --parameters "$PARAMETER_FILE" \
        --output table
    
    echo "✅ What-if analysis completed"
    echo "ℹ️  This was a what-if run. No resources were deployed."
    exit 0
fi

echo "🚀 Starting deployment..."
DEPLOYMENT_NAME="ai-foundry-model-router-$(date +%Y%m%d-%H%M%S)"

az deployment group create \
    --resource-group "$RESOURCE_GROUP_NAME" \
    --template-file "$MAIN_BICEP_FILE" \
    --parameters "$PARAMETER_FILE" \
    --name "$DEPLOYMENT_NAME" \
    --output table

echo "🎉 Deployment completed successfully!"
