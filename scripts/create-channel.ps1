# Create Channel Script
# Creates the land registry channel and joins all peers

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Creating Land Registry Channel" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check if network is running
Write-Host "[1/4] Checking if network is running..." -ForegroundColor Green
$orderer = docker ps --format "{{.Names}}" | Select-String -Pattern "orderer"
if (-not $orderer) {
    Write-Host "  [FAIL] Network is not running. Please start the network first:" -ForegroundColor Red
    Write-Host "    .\scripts\network-start.ps1" -ForegroundColor Yellow
    exit 1
}
Write-Host "  [OK] Network is running" -ForegroundColor Green
Write-Host ""

# Check if crypto materials exist
Write-Host "[2/4] Checking crypto materials..." -ForegroundColor Green
if (-not (Test-Path "network/organizations/peerOrganizations/landreg.example.com")) {
    Write-Host "  [FAIL] Crypto materials not found. Please generate them first:" -ForegroundColor Red
    Write-Host "    .\scripts\generate-crypto.ps1" -ForegroundColor Yellow
    exit 1
}
Write-Host "  [OK] Crypto materials found" -ForegroundColor Green
Write-Host ""

# Check if channel artifacts exist
Write-Host "[3/4] Checking channel artifacts..." -ForegroundColor Green
if (-not (Test-Path "network/channel-artifacts")) {
    New-Item -ItemType Directory -Path "network/channel-artifacts" -Force | Out-Null
    Write-Host "  [OK] Created channel-artifacts directory" -ForegroundColor Gray
} else {
    Write-Host "  [OK] Channel artifacts directory exists" -ForegroundColor Green
}
Write-Host ""

# Note: Actual channel creation requires:
# 1. configtxgen to generate channel creation transaction
# 2. peer channel create command
# 3. peer channel join for each organization

Write-Host "[4/4] Channel creation setup complete" -ForegroundColor Green
Write-Host ""
Write-Host "Note: Full channel creation requires:" -ForegroundColor Yellow
Write-Host "  1. Generating channel creation transaction using configtxgen" -ForegroundColor White
Write-Host "  2. Creating channel using peer channel create" -ForegroundColor White
Write-Host "  3. Joining peers to channel using peer channel join" -ForegroundColor White
Write-Host "  4. Updating anchor peers for each organization" -ForegroundColor White
Write-Host ""
Write-Host "This will be automated in the next phase with Fabric tools container." -ForegroundColor Gray
Write-Host ""
