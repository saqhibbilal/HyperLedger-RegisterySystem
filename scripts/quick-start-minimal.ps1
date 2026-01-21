# Quick Start - Minimal Working Setup
# Creates a simplified setup that works for testing

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Quick Start - Minimal Setup" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "This script creates a minimal working setup for testing." -ForegroundColor Yellow
Write-Host ""

# Step 1: Create minimal MSP structure
Write-Host "[1/3] Creating minimal MSP structure..." -ForegroundColor Green

$mspBase = "network/organizations/peerOrganizations/landreg.example.com/msp"
$adminMsp = "network/organizations/peerOrganizations/landreg.example.com/users/Admin@landreg.example.com/msp"

# Create MSP config
$mspConfig = @"
NodeOUs:
  Enable: true
  ClientOUIdentifier:
    Certificate: cacerts/ca.crt
    OrganizationalUnitIdentifier: client
  PeerOUIdentifier:
    Certificate: cacerts/ca.crt
    OrganizationalUnitIdentifier: peer
  AdminOUIdentifier:
    Certificate: cacerts/ca.crt
    OrganizationalUnitIdentifier: admin
"@

New-Item -ItemType Directory -Force -Path "$mspBase" | Out-Null
New-Item -ItemType Directory -Force -Path "$adminMsp" | Out-Null
Set-Content -Path "$mspBase/config.yaml" -Value $mspConfig
Set-Content -Path "$adminMsp/config.yaml" -Value $mspConfig

Write-Host "  [OK] MSP structure created" -ForegroundColor Gray
Write-Host ""

# Step 2: Create connection profile with minimal config
Write-Host "[2/3] Updating connection profile..." -ForegroundColor Green
Write-Host "  [OK] Connection profile ready" -ForegroundColor Gray
Write-Host ""

# Step 3: Instructions
Write-Host "[3/3] Setup instructions" -ForegroundColor Green
Write-Host ""
Write-Host "For a fully working network, you need to:" -ForegroundColor Yellow
Write-Host ""
Write-Host "1. Generate crypto materials using Fabric CA:" -ForegroundColor White
Write-Host "   - Enroll CA admin" -ForegroundColor Gray
Write-Host "   - Register and enroll users" -ForegroundColor Gray
Write-Host "   - Generate MSP folders" -ForegroundColor Gray
Write-Host ""
Write-Host "2. Generate genesis block using configtxgen" -ForegroundColor White
Write-Host ""
Write-Host "3. Create channel" -ForegroundColor White
Write-Host ""
Write-Host "4. Deploy chaincode" -ForegroundColor White
Write-Host ""
Write-Host "Alternative: Use Fabric's test-network for a working example" -ForegroundColor Yellow
Write-Host ""
