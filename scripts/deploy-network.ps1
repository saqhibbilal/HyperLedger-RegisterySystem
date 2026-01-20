# Complete Network Deployment Script
# Orchestrates the entire deployment process

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Complete Network Deployment" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "This script orchestrates the complete network deployment:" -ForegroundColor Yellow
Write-Host "  1. Start network" -ForegroundColor White
Write-Host "  2. Generate crypto materials" -ForegroundColor White
Write-Host "  3. Generate genesis block" -ForegroundColor White
Write-Host "  4. Create channel" -ForegroundColor White
Write-Host "  5. Deploy chaincode" -ForegroundColor White
Write-Host ""

$continue = Read-Host "Continue with deployment? (y/n)"
if ($continue -ne "y" -and $continue -ne "Y") {
    Write-Host "Deployment cancelled." -ForegroundColor Yellow
    exit 0
}

Write-Host ""

# Step 1: Start network
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Step 1: Starting Network" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
& .\scripts\network-start.ps1
if ($LASTEXITCODE -ne 0) {
    Write-Host "[FAIL] Network startup failed" -ForegroundColor Red
    exit 1
}

Write-Host ""
Start-Sleep -Seconds 5

# Step 2: Generate crypto materials
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Step 2: Generating Crypto Materials" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
& .\scripts\generate-crypto-materials.ps1
if ($LASTEXITCODE -ne 0) {
    Write-Host "[FAIL] Crypto generation failed" -ForegroundColor Red
    exit 1
}

Write-Host ""

# Step 3: Generate genesis block
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Step 3: Generating Genesis Block" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
& .\scripts\generate-genesis-block.ps1
if ($LASTEXITCODE -ne 0) {
    Write-Host "[FAIL] Genesis block generation failed" -ForegroundColor Red
    Write-Host "Note: This may fail if crypto materials are not fully generated." -ForegroundColor Yellow
    Write-Host "      Continue with manual crypto generation if needed." -ForegroundColor Yellow
}

Write-Host ""

# Step 4: Create channel
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Step 4: Creating Channel" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
& .\scripts\create-channel-full.ps1
if ($LASTEXITCODE -ne 0) {
    Write-Host "[FAIL] Channel creation failed" -ForegroundColor Red
    Write-Host "Note: This may fail if crypto materials are not fully generated." -ForegroundColor Yellow
}

Write-Host ""

# Step 5: Deploy chaincode
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Step 5: Deploying Chaincode" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
& .\scripts\deploy-chaincode.ps1
if ($LASTEXITCODE -ne 0) {
    Write-Host "[FAIL] Chaincode deployment preparation failed" -ForegroundColor Red
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Deployment Summary" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Network Status:" -ForegroundColor Green
docker ps --format "table {{.Names}}\t{{.Status}}" | Select-String -Pattern "orderer|peer0|ca-"
Write-Host ""

Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "  1. Verify network is running: docker ps" -ForegroundColor White
Write-Host "  2. Check logs if needed: docker logs <container-name>" -ForegroundColor White
Write-Host "  3. Complete crypto generation if needed" -ForegroundColor White
Write-Host "  4. Complete channel creation and chaincode deployment" -ForegroundColor White
Write-Host ""
Write-Host "For detailed instructions, see:" -ForegroundColor Yellow
Write-Host "  docs/DEPLOYMENT.md" -ForegroundColor White
Write-Host ""
