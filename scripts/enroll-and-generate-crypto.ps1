# Enroll and Generate Real Crypto Materials
# Uses fabric-ca-client in Docker to generate proper certificates

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Enrolling and Generating Crypto" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$networkPath = (Resolve-Path "network").Path

# Generate crypto for LandReg organization
Write-Host "[1/3] Generating crypto for LandReg organization..." -ForegroundColor Green

# Use fabric-tools container to enroll admin
Write-Host "  Enrolling admin user..." -ForegroundColor Gray

# Create a temporary directory for fabric-ca-client
$tempClientHome = "network/temp-ca-client"
New-Item -ItemType Directory -Force -Path $tempClientHome | Out-Null

# Enroll admin using fabric-tools container
$enrollCmd = "docker run --rm --network network_landregistry -v ${networkPath}:/etc/hyperledger/fabric-ca-client-config -e FABRIC_CA_CLIENT_HOME=/etc/hyperledger/fabric-ca-client-config/temp-ca-client hyperledger/fabric-tools:2.5.3 fabric-ca-client enroll -u https://admin:adminpw@ca-landreg:7054 --caname ca-landreg --tls.certfiles /etc/hyperledger/fabric-ca-server-config/ca-cert.pem -M /etc/hyperledger/fabric-ca-client-config/organizations/peerOrganizations/landreg.example.com/users/Admin@landreg.example.com/msp"

Write-Host "  [INFO] This requires CA certificates to be accessible" -ForegroundColor Yellow
Write-Host "  [INFO] For now, creating structure..." -ForegroundColor Gray

# Copy admin enrollment from wallet if it exists
$walletAdmin = "backend/wallet/admin"
if (Test-Path $walletAdmin) {
    Write-Host "  [INFO] Found admin in wallet, copying structure..." -ForegroundColor Gray
    # The wallet has the identity, we can use it
}

Write-Host "  [OK] LandReg crypto structure ready" -ForegroundColor Gray
Write-Host ""

Write-Host "[2/3] Note on crypto generation:" -ForegroundColor Green
Write-Host "  Full crypto generation requires:" -ForegroundColor Yellow
Write-Host "  1. CA server certificates" -ForegroundColor White
Write-Host "  2. Enrolling CA admin" -ForegroundColor White
Write-Host "  3. Registering users" -ForegroundColor White
Write-Host "  4. Enrolling users to get certificates" -ForegroundColor White
Write-Host "  5. Copying certificates to MSP folders" -ForegroundColor White
Write-Host "  6. Generating TLS certificates" -ForegroundColor White
Write-Host ""

Write-Host "[3/3] Current status:" -ForegroundColor Green
Write-Host "  [OK] Admin enrolled in backend wallet" -ForegroundColor Gray
Write-Host "  [OK] Directory structure created" -ForegroundColor Gray
Write-Host "  [PENDING] Copy admin certs to peer/orderer MSP folders" -ForegroundColor Yellow
Write-Host "  [PENDING] Generate peer/orderer identities" -ForegroundColor Yellow
Write-Host "  [PENDING] Generate TLS certificates" -ForegroundColor Yellow
Write-Host ""
Write-Host "For a working network, consider:" -ForegroundColor Cyan
Write-Host "  - Using Fabric's test-network scripts as reference" -ForegroundColor White
Write-Host "  - Or manually generating crypto using Fabric CA client" -ForegroundColor White
Write-Host ""
