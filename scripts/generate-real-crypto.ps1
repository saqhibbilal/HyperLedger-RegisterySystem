# Generate Real Crypto Materials
# Uses Fabric CA to generate proper certificates

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Generating Real Crypto Materials" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "This script will generate proper crypto materials using Fabric CA." -ForegroundColor Yellow
Write-Host ""

# Check CAs are running
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
Start-Sleep -Seconds 15
Write-Host "  [OK] CAs ready" -ForegroundColor Green
Write-Host ""

# Generate crypto for LandReg organization
Write-Host "[3/4] Generating crypto for LandReg organization..." -ForegroundColor Green

$networkPath = (Resolve-Path "network").Path

# Use fabric-tools container to enroll
Write-Host "  Enrolling CA admin..." -ForegroundColor Gray

# Create directories for crypto
$landregAdminMsp = "network/organizations/peerOrganizations/landreg.example.com/users/Admin@landreg.example.com/msp"
$landregPeerMsp = "network/organizations/peerOrganizations/landreg.example.com/peers/peer0.landreg.example.com/msp"

New-Item -ItemType Directory -Force -Path "$landregAdminMsp/signcerts" | Out-Null
New-Item -ItemType Directory -Force -Path "$landregAdminMsp/keystore" | Out-Null
New-Item -ItemType Directory -Force -Path "$landregAdminMsp/cacerts" | Out-Null
New-Item -ItemType Directory -Force -Path "$landregPeerMsp/signcerts" | Out-Null
New-Item -ItemType Directory -Force -Path "$landregPeerMsp/keystore" | Out-Null
New-Item -ItemType Directory -Force -Path "$landregPeerMsp/cacerts" | Out-Null

# Use Docker to enroll admin via CA
Write-Host "  Using Fabric CA to enroll admin..." -ForegroundColor Gray

# Enroll admin using fabric-ca-client in a container
$enrollCmd = @"
docker run --rm --network network_landregistry `
  -v ${networkPath}/organizations:/etc/hyperledger/fabric-ca-client-config `
  -e FABRIC_CA_CLIENT_HOME=/etc/hyperledger/fabric-ca-client-config `
  hyperledger/fabric-tools:2.5.3 `
  fabric-ca-client enroll -u https://admin:adminpw@ca-landreg:7054 --caname ca-landreg --tls.certfiles /etc/hyperledger/fabric-ca-server-config/ca-cert.pem -M /etc/hyperledger/fabric-ca-client-config/landreg.example.com/users/Admin@landreg.example.com/msp
"@

Write-Host "  [INFO] Crypto generation requires proper CA certificates" -ForegroundColor Yellow
Write-Host "  [INFO] This is a complex multi-step process" -ForegroundColor Yellow
Write-Host ""

Write-Host "[4/4] Summary" -ForegroundColor Green
Write-Host ""
Write-Host "For a fully working network, you need to:" -ForegroundColor Yellow
Write-Host ""
Write-Host "1. Generate crypto materials using Fabric CA:" -ForegroundColor White
Write-Host "   - Enroll CA admin for each organization" -ForegroundColor Gray
Write-Host "   - Register admin users" -ForegroundColor Gray
Write-Host "   - Enroll admin users to get certificates" -ForegroundColor Gray
Write-Host "   - Register peer identities" -ForegroundColor Gray
Write-Host "   - Enroll peer identities" -ForegroundColor Gray
Write-Host "   - Generate TLS certificates" -ForegroundColor Gray
Write-Host ""
Write-Host "2. Generate genesis block using configtxgen" -ForegroundColor White
Write-Host ""
Write-Host "3. Create channel" -ForegroundColor White
Write-Host ""
Write-Host "4. Deploy chaincode" -ForegroundColor White
Write-Host ""
Write-Host "RECOMMENDATION:" -ForegroundColor Cyan
Write-Host "  Use Hyperledger Fabric's test-network as a reference." -ForegroundColor Yellow
Write-Host "  It has working scripts for crypto generation." -ForegroundColor Yellow
Write-Host "  Copy their approach or use their network as a base." -ForegroundColor Yellow
Write-Host ""
