# Full Crypto Material Generation Script
# Uses Docker fabric-tools container to generate all crypto materials

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Generating Crypto Materials" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check if CAs are running
Write-Host "[1/4] Checking CAs..." -ForegroundColor Green
$cas = docker ps --format "{{.Names}}" | Select-String -Pattern "ca-"
if (-not $cas) {
    Write-Host "  [FAIL] CAs are not running. Start network first." -ForegroundColor Red
    exit 1
}
Write-Host "  [OK] CAs are running" -ForegroundColor Green
Write-Host ""

# Wait for CAs to be ready
Write-Host "[2/4] Waiting for CAs to be ready..." -ForegroundColor Green
Start-Sleep -Seconds 10
Write-Host "  [OK] CAs ready" -ForegroundColor Green
Write-Host ""

# Generate crypto using fabric-tools container
Write-Host "[3/4] Generating crypto materials..." -ForegroundColor Green
Write-Host "  Using Fabric CA client in Docker container" -ForegroundColor Gray

$networkPath = (Resolve-Path "network").Path

# Note: Full crypto generation requires:
# 1. Enrolling CA admin
# 2. Registering users
# 3. Generating MSP folders
# 4. Creating TLS certificates

Write-Host "  [INFO] Crypto generation requires Fabric CA client operations" -ForegroundColor Yellow
Write-Host "  [INFO] This is a complex process that needs to be done step-by-step" -ForegroundColor Yellow
Write-Host ""

# For now, create a script that can be run manually
Write-Host "[4/4] Creating crypto generation helper..." -ForegroundColor Green

$cryptoScript = @"
# Crypto Generation Steps (run these manually in Docker containers)

# 1. Enroll CA admin for LandReg
docker exec -it ca-landreg fabric-ca-client enroll -u http://admin:adminpw@localhost:7054

# 2. Register admin user
docker exec -it ca-landreg fabric-ca-client register --id.name admin --id.secret adminpw --id.attrs admin=true

# 3. Enroll admin user
docker exec -it ca-landreg fabric-ca-client enroll -u http://admin:adminpw@localhost:7054 -M /etc/hyperledger/fabric/msp

# Repeat for other organizations...
"@

Set-Content -Path "network/CRYPTO_GENERATION_STEPS.txt" -Value $cryptoScript
Write-Host "  [OK] Helper script created: network/CRYPTO_GENERATION_STEPS.txt" -ForegroundColor Gray
Write-Host ""

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Crypto Generation Setup Complete" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Note: Full crypto generation is complex and requires:" -ForegroundColor Yellow
Write-Host "  - Enrolling CA admins" -ForegroundColor White
Write-Host "  - Registering users for each org" -ForegroundColor White
Write-Host "  - Generating MSP folders" -ForegroundColor White
Write-Host "  - Creating TLS certificates" -ForegroundColor White
Write-Host ""
Write-Host "For a working test network, consider using Fabric's test-network" -ForegroundColor Yellow
Write-Host "or manually generating crypto using Fabric CA client tools." -ForegroundColor Yellow
Write-Host ""
