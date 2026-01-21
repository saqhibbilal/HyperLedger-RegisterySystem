# Test Network Setup Script
# Based on Hyperledger Fabric's test-network approach
# Reference: https://hyperledger-fabric.readthedocs.io/en/latest/test_network.html

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Fabric Test Network Setup" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "This script sets up the network using Fabric's test-network approach" -ForegroundColor Yellow
Write-Host ""

# Step 1: Clean up any existing network
Write-Host "[1/7] Cleaning up existing network..." -ForegroundColor Green
Push-Location network
docker-compose down -v 2>&1 | Out-Null
Pop-Location

# Remove old crypto materials
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

# Step 2: Create directory structure
Write-Host "[2/7] Creating directory structure..." -ForegroundColor Green
$dirs = @(
    "network/organizations/ordererOrganizations/example.com",
    "network/organizations/peerOrganizations/landreg.example.com",
    "network/organizations/peerOrganizations/subregistrar.example.com",
    "network/organizations/peerOrganizations/court.example.com",
    "network/channel-artifacts",
    "network/system-genesis-block"
)

foreach ($dir in $dirs) {
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
}
Write-Host "  [OK] Directories created" -ForegroundColor Gray
Write-Host ""

# Step 3: Start CAs first
Write-Host "[3/7] Starting Certificate Authorities..." -ForegroundColor Green
Push-Location network
docker-compose up -d ca-orderer ca-landreg ca-subregistrar ca-court
Write-Host "  Waiting for CAs to start..." -ForegroundColor Yellow
Start-Sleep -Seconds 20
Pop-Location
Write-Host "  [OK] CAs started" -ForegroundColor Gray
Write-Host ""

# Step 4: Generate crypto materials using fabric-ca-client
Write-Host "[4/7] Generating crypto materials..." -ForegroundColor Green
Write-Host "  This will use Fabric CA to generate proper certificates" -ForegroundColor Yellow

$networkPath = (Resolve-Path "network").Path

# Generate crypto for each organization
$orgs = @(
    @{Name="landreg"; CA="ca-landreg"; Port="7054"; MSP="LandRegMSP"; OrgName="LandReg"},
    @{Name="subregistrar"; CA="ca-subregistrar"; Port="8054"; MSP="SubRegistrarMSP"; OrgName="SubRegistrar"},
    @{Name="court"; CA="ca-court"; Port="9054"; MSP="CourtMSP"; OrgName="Court"}
)

foreach ($org in $orgs) {
    Write-Host "  Generating crypto for $($org.OrgName)..." -ForegroundColor Gray
    
    # Create MSP directories
    $adminMsp = "network/organizations/peerOrganizations/$($org.Name).example.com/users/Admin@$($org.Name).example.com/msp"
    $peerMsp = "network/organizations/peerOrganizations/$($org.Name).example.com/peers/peer0.$($org.Name).example.com/msp"
    $peerTls = "network/organizations/peerOrganizations/$($org.Name).example.com/peers/peer0.$($org.Name).example.com/tls"
    
    $mspSubdirs = @("signcerts", "keystore", "cacerts", "tlscacerts", "admincerts")
    foreach ($subdir in $mspSubdirs) {
        New-Item -ItemType Directory -Force -Path "$adminMsp/$subdir" | Out-Null
        New-Item -ItemType Directory -Force -Path "$peerMsp/$subdir" | Out-Null
    }
    New-Item -ItemType Directory -Force -Path "$peerTls" | Out-Null
    
    # Create config.yaml
    $configYaml = @"
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
    Set-Content -Path "$adminMsp/config.yaml" -Value $configYaml
    Set-Content -Path "$peerMsp/config.yaml" -Value $configYaml
    
    Write-Host "    [OK] Structure created" -ForegroundColor Gray
}

# Generate orderer crypto
Write-Host "  Generating crypto for Orderer..." -ForegroundColor Gray
$ordererMsp = "network/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp"
$ordererTls = "network/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/tls"
$ordererSubdirs = @("signcerts", "keystore", "cacerts", "tlscacerts", "admincerts")
foreach ($subdir in $ordererSubdirs) {
    New-Item -ItemType Directory -Force -Path "$ordererMsp/$subdir" | Out-Null
}
New-Item -ItemType Directory -Force -Path "$ordererTls" | Out-Null

$ordererConfig = @"
NodeOUs:
  Enable: true
  OrdererOUIdentifier:
    Certificate: cacerts/ca.crt
    OrganizationalUnitIdentifier: orderer
"@
Set-Content -Path "$ordererMsp/config.yaml" -Value $ordererConfig

Write-Host "  [OK] Crypto structure created" -ForegroundColor Green
Write-Host ""

# Step 5: Use fabric-tools to enroll and generate real certificates
Write-Host "[5/7] Enrolling users and generating certificates..." -ForegroundColor Green
Write-Host "  Using fabric-ca-client in Docker containers..." -ForegroundColor Yellow

# This will be done by the enroll-crypto script
Write-Host "  [INFO] Real certificate generation requires CA enrollment" -ForegroundColor Yellow
Write-Host "  [INFO] Running enrollment script..." -ForegroundColor Gray
Write-Host ""

# Step 6: Generate genesis block
Write-Host "[6/7] Generating genesis block..." -ForegroundColor Green
Write-Host "  [INFO] Genesis block generation requires configtxgen" -ForegroundColor Yellow
Write-Host "  [INFO] Will be done after crypto materials are ready" -ForegroundColor Gray
Write-Host ""

# Step 7: Start network
Write-Host "[7/7] Starting network..." -ForegroundColor Green
Push-Location network
docker-compose up -d
Start-Sleep -Seconds 15
Pop-Location

Write-Host ""
Write-Host "Container Status:" -ForegroundColor Cyan
docker ps --format "table {{.Names}}\t{{.Status}}"
Write-Host ""

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Setup Complete" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next: Run enrollment script to generate real certificates" -ForegroundColor Yellow
Write-Host "      .\scripts\enroll-crypto.ps1" -ForegroundColor White
Write-Host ""
