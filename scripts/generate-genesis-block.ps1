# Generate Genesis Block Script
# Generates the genesis block for the network using configtxgen

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Generating Genesis Block" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check if configtx.yaml exists
Write-Host "[1/3] Checking configuration..." -ForegroundColor Green
if (-not (Test-Path "network/configtx/configtx.yaml")) {
    Write-Host "  [FAIL] configtx.yaml not found" -ForegroundColor Red
    exit 1
}
Write-Host "  [OK] Configuration file found" -ForegroundColor Green
Write-Host ""

# Create channel artifacts directory
Write-Host "[2/3] Preparing directories..." -ForegroundColor Green
if (-not (Test-Path "network/channel-artifacts")) {
    New-Item -ItemType Directory -Path "network/channel-artifacts" -Force | Out-Null
}
if (-not (Test-Path "network/system-genesis-block")) {
    New-Item -ItemType Directory -Path "network/system-genesis-block" -Force | Out-Null
}
Write-Host "  [OK] Directories ready" -ForegroundColor Green
Write-Host ""

# Generate genesis block using Docker fabric-tools container
Write-Host "[3/3] Generating genesis block using configtxgen..." -ForegroundColor Green
Write-Host "  Using Docker container: hyperledger/fabric-tools:2.5.3" -ForegroundColor Gray
Write-Host ""

$networkPath = (Resolve-Path "network").Path
$configtxPath = "$networkPath/configtx"
$channelArtifactsPath = "$networkPath/channel-artifacts"
$genesisBlockPath = "$networkPath/system-genesis-block"

try {
    # Set environment variables for configtxgen
    $env:FABRIC_CFG_PATH = "/etc/hyperledger/configtx"
    
    # Generate genesis block
    $dockerCommand = @(
        "run --rm",
        "-v ${networkPath}:/etc/hyperledger/configtx",
        "-v ${channelArtifactsPath}:/etc/hyperledger/channel-artifacts",
        "-v ${genesisBlockPath}:/etc/hyperledger/system-genesis-block",
        "hyperledger/fabric-tools:2.5.3",
        "configtxgen",
        "-profile LandRegistryGenesis",
        "-channelID system-channel",
        "-outputBlock /etc/hyperledger/system-genesis-block/genesis.block",
        "-configPath /etc/hyperledger/configtx"
    )
    
    Write-Host "  Running: docker $dockerCommand" -ForegroundColor Gray
    $result = docker $dockerCommand 2>&1
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-Host "  [OK] Genesis block generated successfully!" -ForegroundColor Green
        Write-Host "  Location: network/system-genesis-block/genesis.block" -ForegroundColor Gray
    } else {
        Write-Host "  [FAIL] Failed to generate genesis block" -ForegroundColor Red
        Write-Host "  Error: $result" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "  [FAIL] Error generating genesis block: $_" -ForegroundColor Red
    Write-Host ""
    Write-Host "  Note: This requires crypto materials to be generated first." -ForegroundColor Yellow
    Write-Host "  Please ensure crypto materials exist in:" -ForegroundColor Yellow
    Write-Host "    network/organizations/" -ForegroundColor White
    exit 1
}

Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "  1. Restart network to use genesis block: .\scripts\network-restart.ps1" -ForegroundColor White
Write-Host "  2. Create channel: .\scripts\create-channel.ps1" -ForegroundColor White
Write-Host ""
