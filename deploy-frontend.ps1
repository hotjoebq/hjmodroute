# PowerShell script for frontend deployment on Windows
# Usage: .\deploy-frontend.ps1 -ResourceGroup "hj-modroute-rg" -AppName "hjmrdevproj-frontend-dev-nyuxwr"

param(
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroup,
    
    [Parameter(Mandatory=$true)]
    [string]$AppName,
    
    [string]$FrontendZip = "webapp-code\frontend.zip"
)

Write-Host "🎨 Deploying frontend to Azure Static Web App..." -ForegroundColor Cyan
Write-Host "   Resource Group: $ResourceGroup" -ForegroundColor Gray
Write-Host "   App Name: $AppName" -ForegroundColor Gray
Write-Host "   Frontend Zip: $FrontendZip" -ForegroundColor Gray
Write-Host ""

# Check if frontend.zip exists
if (-not (Test-Path $FrontendZip)) {
    Write-Host "❌ Frontend zip file not found at $FrontendZip" -ForegroundColor Red
    Write-Host "   Please ensure the file exists before running this script" -ForegroundColor Yellow
    exit 1
}

$zipSize = (Get-Item $FrontendZip).Length / 1KB
Write-Host "✅ Frontend zip file found ($([math]::Round($zipSize))KB)" -ForegroundColor Green

$frontendDeployed = $false

# Try deployment methods
Write-Host "   Attempting method 1: az staticwebapp environment set" -ForegroundColor Yellow
try {
    az staticwebapp environment set --name $AppName --environment-name default --source $FrontendZip
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Frontend deployment completed successfully!" -ForegroundColor Green
        $frontendDeployed = $true
    }
} catch {
    Write-Host "   ❌ Method 1 failed, trying with resource group..." -ForegroundColor Red
}

if (-not $frontendDeployed) {
    Write-Host "   Attempting method 2: az staticwebapp environment set with resource group" -ForegroundColor Yellow
    try {
        az staticwebapp environment set --name $AppName --environment-name default --source $FrontendZip --resource-group $ResourceGroup
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ Frontend deployment completed successfully!" -ForegroundColor Green
            $frontendDeployed = $true
        }
    } catch {
        Write-Host "   ❌ Method 2 failed, trying deployment create..." -ForegroundColor Red
    }
}

if (-not $frontendDeployed) {
    Write-Host "   Attempting method 3: az staticwebapp deployment create" -ForegroundColor Yellow
    try {
        az staticwebapp deployment create --name $AppName --resource-group $ResourceGroup --source $FrontendZip
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ Frontend deployment completed successfully!" -ForegroundColor Green
            $frontendDeployed = $true
        }
    } catch {
        Write-Host "   ❌ Method 3 failed" -ForegroundColor Red
    }
}

if (-not $frontendDeployed) {
    Write-Host "❌ All automated deployment methods failed" -ForegroundColor Red
    Write-Host ""
    Write-Host "🔧 Manual Deployment Required:" -ForegroundColor Yellow
    Write-Host "   1. Open https://portal.azure.com" -ForegroundColor Gray
    Write-Host "   2. Navigate to Static Web Apps → $AppName" -ForegroundColor Gray
    Write-Host "   3. Click 'Deployment' → 'Source' → 'Upload'" -ForegroundColor Gray
    Write-Host "   4. Upload $FrontendZip" -ForegroundColor Gray
    Write-Host "   5. Wait 2-3 minutes for deployment" -ForegroundColor Gray
    Write-Host ""
    Write-Host "💡 Common Issues:" -ForegroundColor Cyan
    Write-Host "   - Authentication: Run 'az login' first" -ForegroundColor Gray
    Write-Host "   - Permissions: Ensure 'Static Web Apps Contributor' role" -ForegroundColor Gray
    Write-Host "   - Network: Check VPN/firewall settings" -ForegroundColor Gray
}

Write-Host ""
Write-Host "📝 Verification:" -ForegroundColor Cyan
Write-Host "   Frontend URL: https://black-meadow-061e0720f.1.azurestaticapps.net" -ForegroundColor Gray
Write-Host "   Expected: 'Azure AI Foundry Model Router' interface" -ForegroundColor Gray
Write-Host "   Should NOT see: 'Congratulations on your new site!'" -ForegroundColor Gray
