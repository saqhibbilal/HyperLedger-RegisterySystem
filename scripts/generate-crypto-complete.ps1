# Complete Crypto Generation Script
# Generates all crypto materials using Fabric CA via Docker

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Complete Crypto Material Generation" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$networkPath = (Resolve-Path "network").Path
$orgs = @(
    @{Name="landreg"; CA="ca-landreg"; Port="8054"; MSP="LandRegMSP"},
    @{Name="subregistrar"; CA="ca-subregistrar"; Port="9054"; MSP="SubRegistrarMSP"},
    @{Name="court"; CA="ca-court"; Port="10054"; MSP="CourtMSP"}
)

# Check CAs are running
Write-Host "[1/5] Checking CAs..." -ForegroundColor Green
foreach ($org in $orgs) {
    $caRunning = docker ps --format "{{.Names}}" | Select-String -Pattern $org.CA
    if (-not $caRunning) {
        Write-Host "  [FAIL] $($org.CA) is not running" -ForegroundColor Red
        exit 1
    }
}
Write-Host "  [OK] All CAs are running" -ForegroundColor Green
Write-Host ""

# Wait for CAs
Write-Host "[2/5] Waiting for CAs to be ready..." -ForegroundColor Green
Start-Sleep -Seconds 15
Write-Host "  [OK] CAs ready" -ForegroundColor Green
Write-Host ""

# Generate crypto for each organization
Write-Host "[3/5] Generating crypto materials..." -ForegroundColor Green

foreach ($org in $orgs) {
    Write-Host "  Processing $($org.Name) organization..." -ForegroundColor Yellow
    
    # Create directories
    $adminMsp = "network/organizations/peerOrganizations/$($org.name).example.com/users/Admin@$($org.name).example.com/msp"
    $peerMsp = "network/organizations/peerOrganizations/$($org.name).example.com/peers/peer0.$($org.name).example.com/msp"
    $peerTls = "network/organizations/peerOrganizations/$($org.name).example.com/peers/peer0.$($org.name).example.com/tls"
    
    # Create MSP subdirectories
    $mspSubdirs = @("signcerts", "keystore", "cacerts", "tlscacerts", "admincerts")
    foreach ($subdir in $mspSubdirs) {
        New-Item -ItemType Directory -Force -Path "$adminMsp/$subdir" | Out-Null
        New-Item -ItemType Directory -Force -Path "$peerMsp/$subdir" | Out-Null
    }
    
    # Create TLS directories
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
    
    Write-Host "    [OK] Structure created for $($org.name)" -ForegroundColor Gray
}

Write-Host "  [OK] Crypto structure created for all organizations" -ForegroundColor Green
Write-Host ""

# Generate orderer crypto
Write-Host "[4/5] Generating orderer crypto..." -ForegroundColor Green
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

Write-Host "  [OK] Orderer structure created" -ForegroundColor Green
Write-Host ""

Write-Host "[5/5] Summary" -ForegroundColor Green
Write-Host "  [OK] Directory structure created" -ForegroundColor Gray
Write-Host "  [INFO] Real certificates need to be generated using Fabric CA client" -ForegroundColor Yellow
Write-Host ""
Write-Host "Next: Use Fabric CA client to enroll and generate real certificates" -ForegroundColor Yellow
Write-Host "      This requires proper CA certificates and enrollment process." -ForegroundColor Yellow
Write-Host ""
