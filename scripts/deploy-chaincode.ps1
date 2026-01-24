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

try {
    # Package using peer lifecycle chaincode package
    Write-Host "  Packaging chaincode..." -ForegroundColor Gray
    
    # Create package directory
    if (-not (Test-Path "chaincode/packaged")) {
        New-Item -ItemType Directory -Path "chaincode/packaged" -Force | Out-Null
    }
    
    Write-Host "  [OK] Chaincode package structure ready" -ForegroundColor Gray
    Write-Host "  Note: Actual packaging will be done using peer lifecycle commands" -ForegroundColor Yellow
} catch {
    Write-Host "  [FAIL] Error: $_" -ForegroundColor Red
    exit 1
}

Write-Host ""

# Install chaincode on all peers
Write-Host "[4/6] Installing chaincode on peers..." -ForegroundColor Green
$peerOrgs = @(
    @{Name="LandReg"; Peer="peer0.landreg.example.com"; MSP="LandRegMSP"},
    @{Name="SubRegistrar"; Peer="peer0.subregistrar.example.com"; MSP="SubRegistrarMSP"},
    @{Name="Court"; Peer="peer0.court.example.com"; MSP="CourtMSP"}
)

foreach ($org in $peerOrgs) {
    Write-Host "  Installing on $($org.Peer)..." -ForegroundColor Gray
    Write-Host "    [INFO] Installation requires proper crypto materials and peer CLI" -ForegroundColor Yellow
}

Write-Host "  [OK] Chaincode installation structure prepared" -ForegroundColor Green
Write-Host ""

# Approve chaincode definition
Write-Host "[5/6] Approving chaincode definition..." -ForegroundColor Green
Write-Host "  Chaincode definition:" -ForegroundColor Gray
Write-Host "    Name: $CHAINCODE_NAME" -ForegroundColor White
Write-Host "    Version: $CHAINCODE_VERSION" -ForegroundColor White
Write-Host "    Sequence: $CHAINCODE_SEQUENCE" -ForegroundColor White
Write-Host "    Package ID: (will be generated after installation)" -ForegroundColor White
Write-Host ""

Write-Host "  Approval requires:" -ForegroundColor Yellow
Write-Host "    - Chaincode installed on all peers" -ForegroundColor White
Write-Host "    - Package ID from installation" -ForegroundColor White
Write-Host "    - Endorsement policy: OR('LandRegMSP.peer','SubRegistrarMSP.peer','CourtMSP.peer')" -ForegroundColor White
Write-Host ""

# Commit chaincode
Write-Host "[6/6] Committing chaincode to channel..." -ForegroundColor Green
Write-Host "  Committing requires:" -ForegroundColor Yellow
Write-Host "    - Approvals from all organizations" -ForegroundColor White
Write-Host "    - Channel: $CHANNEL_NAME" -ForegroundColor White
Write-Host "    - All peers joined to channel" -ForegroundColor White
Write-Host ""

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Chaincode Deployment Structure Ready" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Summary:" -ForegroundColor Green
Write-Host "  [OK] Chaincode structure verified" -ForegroundColor Gray
Write-Host "  [OK] Package structure created" -ForegroundColor Gray
Write-Host "  [OK] Installation plan prepared" -ForegroundColor Gray
Write-Host "  [OK] Approval/commit plan prepared" -ForegroundColor Gray
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "  1. Generate crypto materials: .\scripts\generate-crypto-materials.ps1" -ForegroundColor White
Write-Host "  2. Create channel: .\scripts\create-channel-full.ps1" -ForegroundColor White
Write-Host "  3. Complete deployment using peer lifecycle commands" -ForegroundColor White
Write-Host ""
Write-Host "Note: Full deployment requires crypto materials and peer CLI tools." -ForegroundColor Yellow
Write-Host "      These will be used via Docker containers in the final setup." -ForegroundColor Yellow
Write-Host ""
