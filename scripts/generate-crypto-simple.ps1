# Simple Crypto Generation - For Learning
# Waits for CAs to create certificates automatically

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Simple Crypto Generation" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$networkPath = (Resolve-Path "network").Path

# Step 1: Start CAs
Write-Host "[1/3] Starting CAs..." -ForegroundColor Green
Push-Location network
docker-compose up -d ca-orderer ca-landreg ca-subregistrar ca-court
Pop-Location
Write-Host "  [OK] CAs started" -ForegroundColor Gray
Write-Host ""

# Step 2: Wait for CA certificates (they're created automatically in mounted volumes)
Write-Host "[2/3] Waiting for CA certificates to be created..." -ForegroundColor Green
Write-Host "  (CAs create certificates automatically in mounted volumes)" -ForegroundColor Yellow

$maxWait = 60
$waited = 0
$allReady = $false

$caPaths = @(
    @{Path="network/organizations/peerOrganizations/landreg.example.com/ca/ca-cert.pem"; Name="landreg"},
    @{Path="network/organizations/peerOrganizations/subregistrar.example.com/ca/ca-cert.pem"; Name="subregistrar"},
    @{Path="network/organizations/peerOrganizations/court.example.com/ca/ca-cert.pem"; Name="court"},
    @{Path="network/organizations/ordererOrganizations/example.com/ca/ca-cert.pem"; Name="orderer"}
)

while ($waited -lt $maxWait -and -not $allReady) {
    $allReady = $true
    foreach ($ca in $caPaths) {
        if (-not (Test-Path $ca.Path)) {
            $allReady = $false
            break
        }
    }
    
    if (-not $allReady) {
        Start-Sleep -Seconds 3
        $waited += 3
        Write-Host "  Waiting... ($waited/$maxWait seconds)" -ForegroundColor Gray
    }
}

if ($allReady) {
    Write-Host "  [OK] All CA certificates ready!" -ForegroundColor Green
} else {
    Write-Host "  [WARN] Some CA certificates not ready after $maxWait seconds" -ForegroundColor Yellow
    Write-Host "  Checking what exists..." -ForegroundColor Gray
    foreach ($ca in $caPaths) {
        if (Test-Path $ca.Path) {
            Write-Host "    [OK] $($ca.Name)" -ForegroundColor Green
        } else {
            Write-Host "    [MISSING] $($ca.Name)" -ForegroundColor Yellow
        }
    }
}
Write-Host ""

# Step 3: Create basic MSP structure (certificates will be added when we enroll)
Write-Host "[3/3] Creating MSP directory structure..." -ForegroundColor Green

$orgs = @("landreg", "subregistrar", "court")
foreach ($org in $orgs) {
    $mspDirs = @(
        "network/organizations/peerOrganizations/$org.example.com/msp",
        "network/organizations/peerOrganizations/$org.example.com/users/Admin@$org.example.com/msp",
        "network/organizations/peerOrganizations/$org.example.com/peers/peer0.$org.example.com/msp",
        "network/organizations/peerOrganizations/$org.example.com/peers/peer0.$org.example.com/tls"
    )
    
    foreach ($dir in $mspDirs) {
        New-Item -ItemType Directory -Force -Path $dir | Out-Null
        
        # Create subdirectories
        $subdirs = @("signcerts", "keystore", "cacerts", "tlscacerts", "admincerts")
        foreach ($subdir in $subdirs) {
            New-Item -ItemType Directory -Force -Path "$dir/$subdir" | Out-Null
        }
    }
    
    # Copy CA cert to MSP if it exists
    $caCertPath = "network/organizations/peerOrganizations/$org.example.com/ca/ca-cert.pem"
    if (Test-Path $caCertPath) {
        $mspPath = "network/organizations/peerOrganizations/$org.example.com/msp"
        Copy-Item $caCertPath "$mspPath/cacerts/ca.crt" -Force -ErrorAction SilentlyContinue
        Copy-Item $caCertPath "$mspPath/tlscacerts/ca.crt" -Force -ErrorAction SilentlyContinue
    }
}

# Orderer structure
$ordererDirs = @(
    "network/organizations/ordererOrganizations/example.com/msp",
    "network/organizations/ordererOrganizations/example.com/users/Admin@example.com/msp",
    "network/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp",
    "network/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/tls"
)

foreach ($dir in $ordererDirs) {
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
    $subdirs = @("signcerts", "keystore", "cacerts", "tlscacerts", "admincerts")
    foreach ($subdir in $subdirs) {
        New-Item -ItemType Directory -Force -Path "$dir/$subdir" | Out-Null
    }
}

# Copy orderer CA cert if exists
$ordererCaPath = "network/organizations/ordererOrganizations/example.com/ca/ca-cert.pem"
if (Test-Path $ordererCaPath) {
    $ordererMsp = "network/organizations/ordererOrganizations/example.com/msp"
    Copy-Item $ordererCaPath "$ordererMsp/cacerts/ca.crt" -Force -ErrorAction SilentlyContinue
    Copy-Item $ordererCaPath "$ordererMsp/tlscacerts/ca.crt" -Force -ErrorAction SilentlyContinue
}

Write-Host "  [OK] MSP structure created" -ForegroundColor Green
Write-Host ""

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Setup Complete" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Note: For a learning project, basic structure is ready." -ForegroundColor Yellow
Write-Host "      Full enrollment requires proper CA setup." -ForegroundColor Yellow
Write-Host ""
Write-Host "Next: Try generating genesis block" -ForegroundColor Cyan
Write-Host "      .\scripts\generate-genesis-block.ps1" -ForegroundColor White
Write-Host ""
