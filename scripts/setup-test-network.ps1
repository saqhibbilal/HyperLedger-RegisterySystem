# Complete Test Network Setup
# Based on Hyperledger Fabric's test-network approach
# Reference: https://hyperledger-fabric.readthedocs.io/en/latest/test_network.html
#
# This script orchestrates the complete network setup:
# 1. Clean up
# 2. Generate crypto materials
# 3. Generate genesis block
# 4. Start network
# 5. Create channel
# 6. Deploy chaincode

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Complete Test Network Setup" -ForegroundColor Cyan
Write-Host "Based on Fabric's test-network approach" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Step 1: Clean up
Write-Host "[STEP 1/6] Cleaning up existing network..." -ForegroundColor Green
Push-Location network
docker-compose down -v 2>&1 | Out-Null
Pop-Location

# Remove old crypto and artifacts
if (Test-Path "network/organizations") {
    Remove-Item -Recurse -Force "network/organizations" -ErrorAction SilentlyContinue
}
if (Test-Path "network/channel-artifacts") {
    Remove-Item -Recurse -Force "network/channel-artifacts" -ErrorAction SilentlyContinue
}
if (Test-Path "network/system-genesis-block") {
    Remove-Item -Recurse -Force "network/system-genesis-block" -ErrorAction SilentlyContinue
}
Write-Host "  [OK] Cleanup complete" -ForegroundColor Gray
Write-Host ""

# Step 2: Start CAs
Write-Host "[STEP 2/6] Starting Certificate Authorities..." -ForegroundColor Green
Push-Location network
docker-compose up -d ca-orderer ca-landreg ca-subregistrar ca-court
Write-Host "  Waiting for CAs to initialize..." -ForegroundColor Yellow
Start-Sleep -Seconds 20
Pop-Location
Write-Host "  [OK] CAs started" -ForegroundColor Gray
Write-Host ""

# Step 3: Generate crypto materials
Write-Host "[STEP 3/6] Generating crypto materials..." -ForegroundColor Green
Write-Host "  Running enrollment script..." -ForegroundColor Yellow
& ".\scripts\enroll-crypto.ps1"
if ($LASTEXITCODE -ne 0) {
    Write-Host "  [WARN] Crypto enrollment had issues, but continuing..." -ForegroundColor Yellow
}
Write-Host ""

# Step 4: Generate genesis block
Write-Host "[STEP 4/6] Generating genesis block..." -ForegroundColor Green
& ".\scripts\generate-genesis-block.ps1"
if ($LASTEXITCODE -ne 0) {
    Write-Host "  [FAIL] Genesis block generation failed" -ForegroundColor Red
    Write-Host "  Check crypto materials are properly generated" -ForegroundColor Yellow
    exit 1
}
Write-Host ""

# Step 5: Start full network
Write-Host "[STEP 5/6] Starting full network..." -ForegroundColor Green
Push-Location network
docker-compose up -d
Write-Host "  Waiting for services to start..." -ForegroundColor Yellow
Start-Sleep -Seconds 20
Pop-Location

Write-Host ""
Write-Host "Container Status:" -ForegroundColor Cyan
docker ps --format "table {{.Names}}\t{{.Status}}"
Write-Host ""

# Check if orderer and peers are running
$ordererRunning = docker ps --format "{{.Names}}" | Select-String -Pattern "orderer.example.com"
$peersRunning = docker ps --format "{{.Names}}" | Select-String -Pattern "peer0"

if (-not $ordererRunning -or -not $peersRunning) {
    Write-Host "  [WARN] Some containers may not be running" -ForegroundColor Yellow
    Write-Host "  Check logs: docker logs orderer.example.com" -ForegroundColor Gray
    Write-Host "  Check logs: docker logs peer0.landreg.example.com" -ForegroundColor Gray
}
Write-Host ""

# Step 6: Create channel and deploy chaincode
Write-Host "[STEP 6/6] Creating channel and deploying chaincode..." -ForegroundColor Green
Write-Host "  This will be done in next steps:" -ForegroundColor Yellow
Write-Host "    1. Create channel: .\scripts\create-channel-full.ps1" -ForegroundColor White
Write-Host "    2. Deploy chaincode: .\scripts\deploy-chaincode.ps1" -ForegroundColor White
Write-Host ""

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Network Setup Complete" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "  1. Verify containers: docker ps" -ForegroundColor White
Write-Host "  2. Create channel: .\scripts\create-channel-full.ps1" -ForegroundColor White
Write-Host "  3. Deploy chaincode: .\scripts\deploy-chaincode.ps1" -ForegroundColor White
Write-Host "  4. Start backend: cd backend; npm start" -ForegroundColor White
Write-Host "  5. Start frontend: cd frontend; npm run dev" -ForegroundColor White
Write-Host ""
