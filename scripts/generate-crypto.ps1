# Generate Crypto Materials Script
# Generates cryptographic materials for all organizations using Fabric CA

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Generating Cryptographic Materials" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check if network is running
Write-Host "[1/3] Checking if network is running..." -ForegroundColor Green
$containers = docker ps --format "{{.Names}}" | Select-String -Pattern "ca-|orderer|peer0"
if (-not $containers) {
    Write-Host "  [FAIL] Network is not running. Please start the network first:" -ForegroundColor Red
    Write-Host "    .\scripts\network-start.ps1" -ForegroundColor Yellow
    exit 1
}
Write-Host "  [OK] Network is running" -ForegroundColor Green
Write-Host ""

# Wait for CAs to be ready
Write-Host "[2/3] Waiting for Certificate Authorities to be ready..." -ForegroundColor Green
$maxAttempts = 30
$attempt = 0
$allReady = $false

while ($attempt -lt $maxAttempts) {
    $caOrderer = docker exec ca-orderer fabric-ca-server healthcheck 2>&1
    $caLandreg = docker exec ca-landreg fabric-ca-server healthcheck 2>&1
    $caSubregistrar = docker exec ca-subregistrar fabric-ca-server healthcheck 2>&1
    $caCourt = docker exec ca-court fabric-ca-server healthcheck 2>&1
    
    if ($LASTEXITCODE -eq 0) {
        $allReady = $true
        break
    }
    
    $attempt++
    Write-Host "  Waiting... ($attempt/$maxAttempts)" -ForegroundColor Gray
    Start-Sleep -Seconds 2
}

if (-not $allReady) {
    Write-Host "  [FAIL] Certificate Authorities are not ready. Please check logs." -ForegroundColor Red
    exit 1
}

Write-Host "  [OK] Certificate Authorities are ready" -ForegroundColor Green
Write-Host ""

# Note: Actual crypto generation will be done using Fabric CA client or configtxgen
# This script provides the structure. The actual generation requires:
# 1. Using fabric-ca-client to enroll admins and register users
# 2. Using configtxgen to generate genesis block and channel artifacts

Write-Host "[3/3] Crypto generation setup complete" -ForegroundColor Green
Write-Host ""
Write-Host "Note: Full crypto material generation requires:" -ForegroundColor Yellow
Write-Host "  1. Enrolling CA admins" -ForegroundColor White
Write-Host "  2. Registering organization users" -ForegroundColor White
Write-Host "  3. Generating MSP folders" -ForegroundColor White
Write-Host "  4. Creating TLS certificates" -ForegroundColor White
Write-Host ""
Write-Host "This will be automated in the next phase with a complete setup script." -ForegroundColor Gray
Write-Host ""
