# Create Channel Script - Complete Implementation
# Creates the land registry channel and joins all peers

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Creating Land Registry Channel" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$CHANNEL_NAME = "landregistrychannel"

# Check if network is running
Write-Host "[1/5] Checking if network is running..." -ForegroundColor Green
$orderer = docker ps --format "{{.Names}}" | Select-String -Pattern "orderer"
if (-not $orderer) {
    Write-Host "  [FAIL] Network is not running. Please start the network first:" -ForegroundColor Red
    Write-Host "    .\scripts\network-start.ps1" -ForegroundColor Yellow
    exit 1
}
Write-Host "  [OK] Network is running" -ForegroundColor Green
Write-Host ""

# Check if genesis block exists
Write-Host "[2/5] Checking genesis block..." -ForegroundColor Green
if (-not (Test-Path "network/system-genesis-block/genesis.block")) {
    Write-Host "  [FAIL] Genesis block not found. Please generate it first:" -ForegroundColor Red
    Write-Host "    .\scripts\generate-genesis-block.ps1" -ForegroundColor Yellow
    exit 1
}
Write-Host "  [OK] Genesis block found" -ForegroundColor Green
Write-Host ""

# Create channel creation transaction
Write-Host "[3/5] Creating channel creation transaction..." -ForegroundColor Green
$networkPath = (Resolve-Path "network").Path
$configtxPath = "$networkPath/configtx"
$channelArtifactsPath = "$networkPath/channel-artifacts"
$organizationsPath = "$networkPath/organizations"

if (-not (Test-Path $channelArtifactsPath)) {
    New-Item -ItemType Directory -Path $channelArtifactsPath -Force | Out-Null
}

try {
    Write-Host "  Generating channel transaction..." -ForegroundColor Gray
    $result = docker run --rm `
        -v "${configtxPath}:/etc/hyperledger/configtx" `
        -v "${organizationsPath}:/etc/hyperledger/organizations" `
        -v "${channelArtifactsPath}:/etc/hyperledger/channel-artifacts" `
        -e FABRIC_CFG_PATH=/etc/hyperledger/configtx `
        hyperledger/fabric-tools:2.5.3 `
        configtxgen `
        -profile LandRegistryChannel `
        -channelID $CHANNEL_NAME `
        -outputCreateChannelTx /etc/hyperledger/channel-artifacts/$CHANNEL_NAME.tx `
        -configPath /etc/hyperledger/configtx 2>&1
    
    if ($LASTEXITCODE -eq 0 -and (Test-Path "network/channel-artifacts/$CHANNEL_NAME.tx")) {
        Write-Host "  [OK] Channel creation transaction generated" -ForegroundColor Green
    } else {
        Write-Host "  [FAIL] Failed to generate channel transaction" -ForegroundColor Red
        if ($result) { Write-Host "  Error: $result" -ForegroundColor Red }
        exit 1
    }
} catch {
    Write-Host "  [FAIL] Error: $_" -ForegroundColor Red
    exit 1
}

Write-Host ""

# Create channel on orderer (peer channel create)
Write-Host "[4/5] Creating channel on orderer..." -ForegroundColor Green
$blockPath = "$channelArtifactsPath/$CHANNEL_NAME.block"
$ordererTlsCa = "$organizationsPath/ordererOrganizations/example.com/orderers/orderer.example.com/tls/ca.crt"
$landregAdminMsp = "$organizationsPath/peerOrganizations/landreg.example.com/users/Admin@landreg.example.com/msp"

if (Test-Path $blockPath) {
    Write-Host "  Channel block exists; skipping create. To recreate, delete $blockPath" -ForegroundColor Gray
} elseif (-not (Test-Path $landregAdminMsp)) {
    Write-Host "  [FAIL] LandReg Admin MSP not found. Run .\scripts\enroll-crypto.ps1" -ForegroundColor Red
    exit 1
} else {
    $dockerNet = (docker inspect ca-orderer --format '{{range $k, $v := .NetworkSettings.Networks}}{{$k}}{{end}}' 2>$null)
    if (-not $dockerNet) { $dockerNet = "network_landregistry" }
    $createOut = docker run --rm --network $dockerNet `
      -v "${organizationsPath}:/etc/hyperledger/organizations" `
      -v "${channelArtifactsPath}:/etc/hyperledger/channel-artifacts" `
      -e CORE_PEER_LOCALMSPID=LandRegMSP `
      -e CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/organizations/peerOrganizations/landreg.example.com/users/Admin@landreg.example.com/msp `
      -e CORE_PEER_TLS_ENABLED=true `
      hyperledger/fabric-tools:2.5.3 `
      peer channel create -o orderer.example.com:7050 -c $CHANNEL_NAME `
      -f /etc/hyperledger/channel-artifacts/$CHANNEL_NAME.tx `
      --outputBlock /etc/hyperledger/channel-artifacts/$CHANNEL_NAME.block `
      --tls --cafile /etc/hyperledger/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/tls/ca.crt 2>&1
    if ($LASTEXITCODE -ne 0 -and -not (Test-Path $blockPath)) {
        Write-Host "  [FAIL] Channel create failed: $createOut" -ForegroundColor Red
        exit 1
    }
    if (Test-Path $blockPath) { Write-Host "  [OK] Channel created" -ForegroundColor Green }
}

Write-Host ""

# Join running peers to channel
Write-Host "[5/5] Joining peers to channel..." -ForegroundColor Green
if (-not (Test-Path $blockPath)) {
    Write-Host "  [FAIL] Channel block not found" -ForegroundColor Red
    exit 1
}
$peerNames = @(docker ps --format "{{.Names}}" | Select-String -Pattern "peer0")
$joined = 0
foreach ($p in $peerNames) {
    $name = if ($p.Line) { $p.Line.Trim() } else { $p.ToString().Trim() }
    if (-not $name) { continue }
    docker cp "$blockPath" "${name}:/tmp/$CHANNEL_NAME.block" 2>$null | Out-Null
    $j = docker exec $name peer channel join -b /tmp/$CHANNEL_NAME.block 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  [OK] $name joined" -ForegroundColor Green
        $joined++
    } else {
        if ($j -match "already joined") { Write-Host "  [OK] $name already joined" -ForegroundColor Gray; $joined++ }
        else { Write-Host "  [WARN] $name join: $j" -ForegroundColor Yellow }
    }
}
if ($joined -eq 0) { Write-Host "  [WARN] No peers joined. Run .\scripts\start-peers.ps1" -ForegroundColor Yellow }
Write-Host ""
Write-Host "Channel ready. Next: .\scripts\deploy-chaincode.ps1" -ForegroundColor Yellow
Write-Host ""
