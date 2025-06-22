# Frontend Deployment Instructions

## Quick Start - SWA CLI Method (Recommended)

The frontend-deploy directory is ready with extracted files and configuration. Run these commands:

```bash
# Navigate to the deployment directory
cd frontend-deploy

# Authenticate and deploy (requires Azure CLI login first)
swa login --subscription-id $(az account show --query id --output tsv) --resource-group hj-modroute-rg --app-name hjmrdevproj-frontend-dev-nyuxwr
swa deploy --env production
```

## Directory Structure

```
frontend-deploy/
├── index.html                 # Main application file
├── assets/                    # Application assets
│   ├── index-5ff14ca1.js     # JavaScript bundle
│   ├── index-b2d9560a.js     # Additional JS
│   └── index-e0fa1303.css    # Stylesheet
└── swa-cli.config.json       # SWA CLI configuration
```

## Verification

After deployment, check:
- Frontend URL: https://black-meadow-061e0720f.1.azurestaticapps.net
- Should show: "Azure AI Foundry Model Router" interface
- Should NOT show: "Congratulations on your new site!" placeholder

## Alternative Methods

If SWA CLI fails, use:
1. Azure Portal manual upload
2. Azure CLI commands
3. Standalone deployment script: `./deploy-frontend-only.sh -g hj-modroute-rg -n hjmrdevproj-frontend-dev-nyuxwr`

## Monitoring

The monitoring script is running and will automatically detect when deployment succeeds.
