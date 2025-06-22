# StaticSitesClient Binary Error Troubleshooting

## Error Description
```
Could not find StaticSitesClient local binary
Deployment Failure Reason: Could not load StaticSitesClient metadata from remote. Please check your internet connection.
```

## Root Causes
1. **Network/Proxy Restrictions**: Corporate firewalls blocking binary downloads
2. **Azure CDN Issues**: Temporary service outages affecting binary distribution
3. **Authentication Problems**: Expired or missing Azure credentials

## Working Solutions

### Solution 1: GitHub Actions (Bypasses local binary requirement)
- Uses Azure's official deployment action
- Runs in GitHub's infrastructure with reliable network access
- No local StaticSitesClient binary needed

### Solution 2: REST API Direct Upload
- Uses curl to POST directly to Azure deployment endpoint
- Bypasses SWA CLI entirely
- Requires deployment token from Azure Portal

### Solution 3: Azure DevOps Pipelines
- Alternative CI/CD platform with Azure integration
- Built-in Azure Static Web Apps deployment tasks
- Enterprise-friendly for organizations using Azure DevOps

## Prevention
- Set up automated deployment via GitHub Actions
- Keep deployment tokens secure and rotated
- Document manual deployment procedures for emergencies

## Implementation Steps

### GitHub Actions Setup
1. Create `.github/workflows/deploy-frontend.yml`
2. Get deployment token from Azure Portal
3. Add token as GitHub secret
4. Trigger workflow manually or on push

### REST API Setup
1. Authenticate with Azure CLI: `az login`
2. Run deployment script: `./deploy-via-rest-api.sh`
3. Monitor deployment success

### Verification
- Check https://black-meadow-061e0720f.1.azurestaticapps.net
- Verify Model Router interface loads
- Test chat functionality and settings page
