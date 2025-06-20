# Manual Model Router Deployment Guide

After deploying the Azure AI Foundry infrastructure using these Bicep templates, you can manually deploy Model Router through the Azure AI Foundry portal.

## Prerequisites
- Azure AI Foundry infrastructure deployed using the Bicep templates in this repository
- Access to Azure AI Foundry portal

## Steps to Deploy Model Router

1. **Navigate to Azure AI Foundry Portal**
   - Go to [Azure AI Foundry](https://ai.azure.com)
   - Sign in with your Azure credentials

2. **Select Your AI Project**
   - Find and select the AI project created by the Bicep deployment
   - The project name will be in format: `{projectName}-ai-project-{environment}-{uniqueSuffix}`

3. **Deploy Model Router**
   - Navigate to the "Models + endpoints" section
   - Click "Create new deployment"
   - In the Models list, select "model-router"
   - Configure deployment settings:
     - Deployment name: Choose a meaningful name (e.g., `{projectName}-model-router-{environment}`)
     - Authentication: Key, AMLToken, or AADToken
     - Instance type: Standard_DS3_v2 (recommended)
     - Instance count: 1 (can be scaled later)

4. **Configure Model Router Settings**
   - Set routing strategy to "cost-optimized" for best cost savings
   - Configure content filtering as needed
   - Set rate limiting based on your requirements

5. **Test the Deployment**
   - Use the playground to test Model Router functionality
   - Verify intelligent routing is working correctly
   - Monitor metrics and cost optimization

## Important Notes
- Model Router is a preview feature and requires manual deployment through the portal
- Each Model Router version is associated with a fixed set of underlying models
- Deployment settings apply uniformly to all underlying chat models
- No extra charges for model routing function (as of current preview)

## Troubleshooting
- Ensure your AI project has the necessary permissions and resources
- Verify that the AI Services connection is properly configured
- Check that the underlying models are available in your region

For more information, see the [official Microsoft documentation](https://learn.microsoft.com/en-us/azure/ai-services/openai/how-to/model-router).
