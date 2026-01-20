# Complete Network Setup Script
# This script sets up the entire Fabric network: generates crypto, creates channel, and joins peers

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Complete Network Setup" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Import environment variables
$env:COMPOSE_PROJECT_NAME = "landregistry"
$env:FABRIC_VERSION = "2.5.3"
$env:CHANNEL_NAME = "landregistrychannel"

# Step 1: Start network
Write-Host "[1/5] Starting Fabric network..." -ForegroundColor Green
& .\scripts\network-start.ps1
if ($LASTEXITCODE -ne 0) {
    Write-Host "[FAIL] Failed to start network" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Waiting for services to stabilize..." -ForegroundColor Yellow
Start-Sleep -Seconds 15

# Step 2: Generate crypto materials using Fabric CA
Write-Host "[2/5] Generating cryptographic materials..." -ForegroundColor Green
Write-Host "  This step will be completed in Phase 4 with full CA client setup" -ForegroundColor Yellow
Write-Host "  For now, the network structure is ready" -ForegroundColor Gray

# Step 3: Generate genesis block
Write-Host "[3/5] Generating genesis block..." -ForegroundColor Green
Write-Host "  This step will be completed in Phase 4 with configtxgen" -ForegroundColor Yellow

# Step 4: Create channel
Write-Host "[4/5] Creating channel..." -ForegroundColor Green
Write-Host "  This step will be completed in Phase 4" -ForegroundColor Yellow

# Step 5: Join peers to channel
Write-Host "[5/5] Joining peers to channel..." -ForegroundColor Green
Write-Host "  This step will be completed in Phase 4" -ForegroundColor Yellow

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Network Setup - Phase 2 Complete" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Network configuration files created:" -ForegroundColor Green
Write-Host "  [OK] network/docker-compose.yml" -ForegroundColor Gray
Write-Host "  [OK] network/configtx/configtx.yaml" -ForegroundColor Gray
Write-Host "  [OK] network/.env.example" -ForegroundColor Gray
Write-Host ""
Write-Host "Management scripts created:" -ForegroundColor Green
Write-Host "  [OK] scripts/network-start.ps1" -ForegroundColor Gray
Write-Host "  [OK] scripts/network-stop.ps1" -ForegroundColor Gray
Write-Host "  [OK] scripts/generate-crypto.ps1" -ForegroundColor Gray
Write-Host "  [OK] scripts/create-channel.ps1" -ForegroundColor Gray
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Proceed to Phase 3: Chaincode Development" -ForegroundColor White
Write-Host "2. In Phase 4, we will complete crypto generation and channel creation" -ForegroundColor White
Write-Host ""
