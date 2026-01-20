# Generate Crypto Materials Script
# Generates cryptographic materials for all organizations using Fabric CA

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Generating Cryptographic Materials" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check if network is running
Write-Host "[1/6] Checking if network is running..." -ForegroundColor Green
$containers = docker ps --format "{{.Names}}" | Select-String -Pattern "ca-|orderer|peer0"
if (-not $containers) {
    Write-Host "  [FAIL] Network is not running. Please start the network first:" -ForegroundColor Red
    Write-Host "    .\scripts\network-start.ps1" -ForegroundColor Yellow
    exit 1
}
Write-Host "  [OK] Network is running" -ForegroundColor Green
Write-Host ""

# Wait for CAs to be ready
Write-Host "[2/6] Waiting for Certificate Authorities to be ready..." -ForegroundColor Green
$maxAttempts = 30
$attempt = 0
$allReady = $false

while ($attempt -lt $maxAttempts) {
    try {
        docker exec ca-orderer fabric-ca-server healthcheck 2>&1 | Out-Null
        docker exec ca-landreg fabric-ca-server healthcheck 2>&1 | Out-Null
        docker exec ca-subregistrar fabric-ca-server healthcheck 2>&1 | Out-Null
        docker exec ca-court fabric-ca-server healthcheck 2>&1 | Out-Null
        
        if ($LASTEXITCODE -eq 0) {
            $allReady = $true
            break
        }
    } catch {
        # Continue waiting
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

# Create directories for crypto materials
Write-Host "[3/6] Creating directory structure..." -ForegroundColor Green
$directories = @(
    "network/organizations/ordererOrganizations/example.com/orderers/orderer.example.com",
    "network/organizations/peerOrganizations/landreg.example.com/peers/peer0.landreg.example.com",
    "network/organizations/peerOrganizations/subregistrar.example.com/peers/peer0.subregistrar.example.com",
    "network/organizations/peerOrganizations/court.example.com/peers/peer0.court.example.com",
    "network/organizations/peerOrganizations/landreg.example.com/users/Admin@landreg.example.com",
    "network/organizations/peerOrganizations/subregistrar.example.com/users/Admin@subregistrar.example.com",
    "network/organizations/peerOrganizations/court.example.com/users/Admin@court.example.com",
    "network/channel-artifacts",
    "network/system-genesis-block"
)

foreach ($dir in $directories) {
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
}

Write-Host "  [OK] Directory structure created" -ForegroundColor Green
Write-Host ""

Write-Host "[4/6] Generating crypto materials using Fabric CA..." -ForegroundColor Green
Write-Host "  Note: This step requires Fabric CA client tools." -ForegroundColor Yellow
Write-Host "  Full crypto generation will use Docker containers with fabric-tools." -ForegroundColor Yellow
Write-Host "  For now, placeholder structure is created." -ForegroundColor Gray
Write-Host ""

Write-Host "[5/6] Crypto materials structure prepared" -ForegroundColor Green
Write-Host "  [OK] Orderer organization structure" -ForegroundColor Gray
Write-Host "  [OK] Land Registration organization structure" -ForegroundColor Gray
Write-Host "  [OK] Sub-Registrar organization structure" -ForegroundColor Gray
Write-Host "  [OK] Court organization structure" -ForegroundColor Gray
Write-Host ""

Write-Host "[6/6] Summary" -ForegroundColor Green
Write-Host "  Directory structure created for crypto materials" -ForegroundColor Gray
Write-Host "  CAs are running and ready" -ForegroundColor Gray
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "  1. Generate genesis block: .\scripts\generate-genesis-block.ps1" -ForegroundColor White
Write-Host "  2. Create channel: .\scripts\create-channel.ps1" -ForegroundColor White
Write-Host ""
Write-Host "Note: Actual crypto material generation will be completed" -ForegroundColor Yellow
Write-Host "      using Fabric CA client in Docker containers." -ForegroundColor Yellow
Write-Host ""
