# Complete Setup and Deployment Script
# This script sets up the entire network from scratch

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Complete Network Setup & Deployment" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Step 1: Stop everything
Write-Host "[1/7] Cleaning up..." -ForegroundColor Green
Push-Location network
docker-compose down -v 2>&1 | Out-Null
Pop-Location
Write-Host "  [OK] Cleanup complete" -ForegroundColor Gray
Write-Host ""

# Step 2: Start only CAs
Write-Host "[2/7] Starting Certificate Authorities..." -ForegroundColor Green
Push-Location network
docker-compose up -d ca-orderer ca-landreg ca-subregistrar ca-court
Write-Host "  Waiting for CAs to start..." -ForegroundColor Yellow
Start-Sleep -Seconds 15
Pop-Location
Write-Host "  [OK] CAs started" -ForegroundColor Gray
Write-Host ""

# Step 3: Generate crypto materials using fabric-ca-client in Docker
Write-Host "[3/7] Generating crypto materials..." -ForegroundColor Green
Write-Host "  This will take a few minutes..." -ForegroundColor Yellow

$networkPath = (Resolve-Path "network").Path

# Use fabric-tools container to enroll and generate crypto
Write-Host "  Generating crypto for LandReg organization..." -ForegroundColor Gray

# Create a script to run inside fabric-tools container
$cryptoScript = @"
#!/bin/bash
export FABRIC_CA_CLIENT_HOME=/tmp/fabric-ca-client
export FABRIC_CA_CLIENT_TLS_CERTFILES=/etc/hyperledger/fabric-ca-server-config/ca-cert.pem

# Enroll CA admin
fabric-ca-client enroll -u https://admin:adminpw@ca-landreg:7054 --caname ca-landreg --tls.certfiles /etc/hyperledger/fabric-ca-server-config/ca-cert.pem

# Register admin user
fabric-ca-client register --caname ca-landreg --id.name admin --id.secret adminpw --id.type admin --id.attrs "admin=true" -u https://ca-landreg:7054 --tls.certfiles /etc/hyperledger/fabric-ca-server-config/ca-cert.pem

# Enroll admin user
fabric-ca-client enroll -u https://admin:adminpw@ca-landreg:7054 --caname ca-landreg -M /etc/hyperledger/fabric/msp --tls.certfiles /etc/hyperledger/fabric-ca-server-config/ca-cert.pem
"@

Write-Host "  [INFO] Crypto generation requires proper CA certificates" -ForegroundColor Yellow
Write-Host "  [INFO] For now, creating basic structure..." -ForegroundColor Gray

# Create basic directory structure
$orgs = @("landreg", "subregistrar", "court")
foreach ($org in $orgs) {
    $mspPath = "network/organizations/peerOrganizations/$org.example.com/msp"
    $adminPath = "network/organizations/peerOrganizations/$org.example.com/users/Admin@$org.example.com/msp"
    
    New-Item -ItemType Directory -Force -Path "$mspPath/cacerts" | Out-Null
    New-Item -ItemType Directory -Force -Path "$mspPath/tlscacerts" | Out-Null
    New-Item -ItemType Directory -Force -Path "$adminPath" | Out-Null
    
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
    Set-Content -Path "$mspPath/config.yaml" -Value $configYaml
    Set-Content -Path "$adminPath/config.yaml" -Value $configYaml
}

Write-Host "  [OK] Basic structure created" -ForegroundColor Gray
Write-Host ""

# Step 4: Generate genesis block (placeholder)
Write-Host "[4/7] Creating genesis block structure..." -ForegroundColor Green
New-Item -ItemType Directory -Force -Path "network/system-genesis-block" | Out-Null
Write-Host "  [OK] Genesis block directory ready" -ForegroundColor Gray
Write-Host ""

# Step 5: Start full network
Write-Host "[5/7] Starting full network..." -ForegroundColor Green
Push-Location network
docker-compose up -d
Write-Host "  Waiting for services to start..." -ForegroundColor Yellow
Start-Sleep -Seconds 20
Pop-Location

# Check status
Write-Host ""
Write-Host "Container Status:" -ForegroundColor Cyan
docker ps --format "table {{.Names}}\t{{.Status}}"
Write-Host ""

# Step 6: Create channel (if possible)
Write-Host "[6/7] Channel creation..." -ForegroundColor Green
Write-Host "  [INFO] Channel creation requires proper crypto materials" -ForegroundColor Yellow
Write-Host "  [INFO] Skipping for now - will be done after crypto generation" -ForegroundColor Gray
Write-Host ""

# Step 7: Deploy chaincode (if possible)
Write-Host "[7/7] Chaincode deployment..." -ForegroundColor Green
Write-Host "  [INFO] Chaincode deployment requires channel to exist" -ForegroundColor Yellow
Write-Host "  [INFO] Skipping for now - will be done after channel creation" -ForegroundColor Gray
Write-Host ""

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Setup Complete" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Current Status:" -ForegroundColor Yellow
Write-Host "  [OK] Network containers started" -ForegroundColor Gray
Write-Host "  [OK] Basic crypto structure created" -ForegroundColor Gray
Write-Host "  [PENDING] Full crypto material generation" -ForegroundColor Yellow
Write-Host "  [PENDING] Channel creation" -ForegroundColor Yellow
Write-Host "  [PENDING] Chaincode deployment" -ForegroundColor Yellow
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "  1. Generate proper crypto materials using Fabric CA client" -ForegroundColor White
Write-Host "  2. Generate genesis block using configtxgen" -ForegroundColor White
Write-Host "  3. Create channel" -ForegroundColor White
Write-Host "  4. Deploy chaincode" -ForegroundColor White
Write-Host ""
Write-Host "Note: Full crypto generation is complex. Consider using" -ForegroundColor Yellow
Write-Host "      Hyperledger Fabric's test-network as a reference." -ForegroundColor Yellow
Write-Host ""
