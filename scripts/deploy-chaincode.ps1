# Deploy Chaincode Script
# Installs and deploys chaincode to all peer organizations

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Deploying Chaincode" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$CHAINCODE_NAME = "landregistry"
$CHAINCODE_VERSION = "1.0"
$CHAINCODE_SEQUENCE = "1"
$CHANNEL_NAME = "landregistrychannel"
$CHAINCODE_PATH = "github.com/landregistry/chaincode"

# Check if network is running (need at least one peer for chaincode)
Write-Host "[1/6] Checking if network is running..." -ForegroundColor Green
$all = docker ps --format "{{.Names}}"
$peers = $all | Select-String -Pattern "peer0"
$orderer = $all | Select-String -Pattern "orderer"
if (-not $peers) {
    Write-Host "  [FAIL] No peer containers are running. Chaincode deployment requires peers." -ForegroundColor Red
    if ($orderer) {
        Write-Host "  Orderer is running; peers may have exited or were not started." -ForegroundColor Yellow
    }
    Write-Host "  Start orderer and peers:" -ForegroundColor Yellow
    Write-Host "    .\scripts\start-peers.ps1" -ForegroundColor White
    Write-Host "  Or, from network folder:" -ForegroundColor Yellow
    Write-Host "    cd network; docker-compose up -d orderer.example.com peer0.landreg.example.com peer0.court.example.com" -ForegroundColor White
    Write-Host "  Full network: .\scripts\network-start.ps1  |  All containers: docker ps -a" -ForegroundColor Gray
    exit 1
}
Write-Host "  [OK] Network is running (peers found)" -ForegroundColor Green
Write-Host ""

# Check if chaincode exists
Write-Host "[2/6] Checking chaincode..." -ForegroundColor Green
if (-not (Test-Path "chaincode/landregistry/landregistry.go")) {
    Write-Host "  [FAIL] Chaincode not found" -ForegroundColor Red
    exit 1
}
Write-Host "  [OK] Chaincode found" -ForegroundColor Green
Write-Host ""

# Package chaincode
Write-Host "[3/6] Packaging chaincode..." -ForegroundColor Green
$chaincodePath = (Resolve-Path "chaincode/landregistry").Path
if (-not (Test-Path "chaincode/packaged")) { New-Item -ItemType Directory -Path "chaincode/packaged" -Force | Out-Null }
$packagedPath = (Resolve-Path "chaincode/packaged").Path
$pkgFile = "landregistry.tar.gz"

$networkPath = (Resolve-Path "network").Path
$organizationsPath = Join-Path $networkPath "organizations"
$ordererTlsCa = "$organizationsPath/ordererOrganizations/example.com/orderers/orderer.example.com/tls/ca.crt"
$dockerNet = (docker inspect ca-orderer --format '{{range $k, $v := .NetworkSettings.Networks}}{{$k}}{{end}}' 2>$null)
if (-not $dockerNet) { $dockerNet = "network_landregistry" }

$pkgOut = docker run --rm --network $dockerNet `
  -v "${chaincodePath}:/chaincode/landregistry" `
  -v "${packagedPath}:/packaged" `
  hyperledger/fabric-tools:2.5.3 `
  peer lifecycle chaincode package /packaged/$pkgFile --path /chaincode/landregistry --lang golang --label landregistry_1.0 2>&1
if ($LASTEXITCODE -ne 0 -or -not (Test-Path "$packagedPath/$pkgFile")) {
    Write-Host "  [FAIL] Package failed: $pkgOut" -ForegroundColor Red
    exit 1
}
Write-Host "  [OK] Packaged: chaincode/packaged/$pkgFile" -ForegroundColor Green
Write-Host ""

# Install chaincode on peer0.landreg (the running peer we have TLS for)
Write-Host "[4/6] Installing chaincode on peers..." -ForegroundColor Green
$landregPeer = "peer0.landreg.example.com"
$landregPeerTls = "$organizationsPath/peerOrganizations/landreg.example.com/peers/peer0.landreg.example.com/tls/ca.crt"
$landregAdminMsp = "$organizationsPath/peerOrganizations/landreg.example.com/users/Admin@landreg.example.com/msp"

if (-not (Test-Path $landregPeerTls) -or -not (Test-Path $landregAdminMsp)) {
    Write-Host "  [FAIL] LandReg peer TLS or Admin MSP missing. Run .\scripts\enroll-crypto.ps1" -ForegroundColor Red
    exit 1
}

$installOut = docker run --rm --network $dockerNet `
  -v "${packagedPath}:/packaged" `
  -v "${organizationsPath}:/etc/hyperledger/organizations" `
  -e CORE_PEER_ADDRESS=${landregPeer}:7051 `
  -e CORE_PEER_LOCALMSPID=LandRegMSP `
  -e CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/organizations/peerOrganizations/landreg.example.com/users/Admin@landreg.example.com/msp `
  -e CORE_PEER_TLS_ENABLED=true `
  -e CORE_PEER_TLS_ROOTCERT_FILE=/etc/hyperledger/organizations/peerOrganizations/landreg.example.com/peers/peer0.landreg.example.com/tls/ca.crt `
  hyperledger/fabric-tools:2.5.3 `
  peer lifecycle chaincode install /packaged/$pkgFile 2>&1

$pkgId = ($installOut | Select-String "Package ID: (\S+)" | ForEach-Object { $_.Matches.Groups[1].Value }) -join ""
if (-not $pkgId) {
    Write-Host "  [FAIL] Install failed or Package ID not found: $installOut" -ForegroundColor Red
    exit 1
}
Write-Host "  [OK] Installed on $landregPeer, Package ID: $pkgId" -ForegroundColor Green
Write-Host ""

# Approve (1-org channel: LandReg only; MAJORITY=1)
Write-Host "[5/6] Approving chaincode definition..." -ForegroundColor Green
$apr1 = docker run --rm --network $dockerNet `
  -v "${organizationsPath}:/etc/hyperledger/organizations" `
  -e CORE_PEER_LOCALMSPID=LandRegMSP `
  -e CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/organizations/peerOrganizations/landreg.example.com/users/Admin@landreg.example.com/msp `
  -e CORE_PEER_TLS_ENABLED=true `
  -e CORE_PEER_ADDRESS=${landregPeer}:7051 `
  -e CORE_PEER_TLS_ROOTCERT_FILE=/etc/hyperledger/organizations/peerOrganizations/landreg.example.com/peers/peer0.landreg.example.com/tls/ca.crt `
  hyperledger/fabric-tools:2.5.3 `
  peer lifecycle chaincode approveformyorg -o orderer.example.com:7050 --channelID $CHANNEL_NAME --name $CHAINCODE_NAME --version $CHAINCODE_VERSION --package-id $pkgId --sequence $CHAINCODE_SEQUENCE --tls --cafile /etc/hyperledger/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/tls/ca.crt 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "  [FAIL] LandReg approve: $apr1" -ForegroundColor Red
    exit 1
}
Write-Host "  [OK] LandRegMSP approved" -ForegroundColor Green
Write-Host ""

# Commit
Write-Host "[6/6] Committing chaincode to channel..." -ForegroundColor Green
$commitOut = docker run --rm --network $dockerNet `
  -v "${organizationsPath}:/etc/hyperledger/organizations" `
  -e CORE_PEER_LOCALMSPID=LandRegMSP `
  -e CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/organizations/peerOrganizations/landreg.example.com/users/Admin@landreg.example.com/msp `
  -e CORE_PEER_TLS_ENABLED=true `
  -e CORE_PEER_ADDRESS=${landregPeer}:7051 `
  -e CORE_PEER_TLS_ROOTCERT_FILE=/etc/hyperledger/organizations/peerOrganizations/landreg.example.com/peers/peer0.landreg.example.com/tls/ca.crt `
  hyperledger/fabric-tools:2.5.3 `
  peer lifecycle chaincode commit -o orderer.example.com:7050 --channelID $CHANNEL_NAME --name $CHAINCODE_NAME --version $CHAINCODE_VERSION --sequence $CHAINCODE_SEQUENCE `
  --tls --cafile /etc/hyperledger/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/tls/ca.crt `
  --peerAddresses ${landregPeer}:7051 --tlsRootCertFiles /etc/hyperledger/organizations/peerOrganizations/landreg.example.com/peers/peer0.landreg.example.com/tls/ca.crt `
  -P "OR('LandRegMSP.peer')" 2>&1

if ($LASTEXITCODE -ne 0) {
    Write-Host "  [FAIL] Commit failed: $commitOut" -ForegroundColor Red
    exit 1
}
Write-Host "  [OK] Chaincode committed to $CHANNEL_NAME" -ForegroundColor Green
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Chaincode Deployed" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Name: $CHAINCODE_NAME $CHAINCODE_VERSION on $CHANNEL_NAME" -ForegroundColor Gray
Write-Host "  Endorsement: OR('LandRegMSP.peer')" -ForegroundColor Gray
Write-Host ""
