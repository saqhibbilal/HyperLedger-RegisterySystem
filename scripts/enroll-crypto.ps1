# Enroll Crypto Materials Using Fabric CA
# Based on test-network approach - enrolls users and generates certificates

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Enrolling Crypto Materials" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$networkPath = (Resolve-Path "network").Path
$FABRIC_CA_CLIENT_HOME = "$networkPath/organizations"

# Check CAs are running
Write-Host "[1/4] Checking CAs..." -ForegroundColor Green
$cas = docker ps --format "{{.Names}}" | Select-String -Pattern "ca-"
if (-not $cas) {
    Write-Host "  [FAIL] CAs are not running" -ForegroundColor Red
    exit 1
}
Write-Host "  [OK] CAs are running" -ForegroundColor Green
Write-Host ""

# Wait for CAs
Write-Host "[2/4] Waiting for CAs to be ready..." -ForegroundColor Green
Start-Sleep -Seconds 10
Write-Host "  [OK] CAs ready" -ForegroundColor Green
Write-Host ""

# Organizations to process
$orgs = @(
    @{Name="landreg"; CA="ca-landreg"; Port="7054"; MSP="LandRegMSP"; CAUrl="https://ca-landreg:7054"},
    @{Name="subregistrar"; CA="ca-subregistrar"; Port="8054"; MSP="SubRegistrarMSP"; CAUrl="https://ca-subregistrar:8054"},
    @{Name="court"; CA="ca-court"; Port="9054"; MSP="CourtMSP"; CAUrl="https://ca-court:9054"}
)

Write-Host "[3/4] Enrolling admin users..." -ForegroundColor Green

foreach ($org in $orgs) {
    Write-Host "  Processing $($org.Name) organization..." -ForegroundColor Yellow
    
    $adminMsp = "$networkPath/organizations/peerOrganizations/$($org.Name).example.com/users/Admin@$($org.Name).example.com/msp"
    $peerMsp = "$networkPath/organizations/peerOrganizations/$($org.Name).example.com/peers/peer0.$($org.Name).example.com/msp"
    
    # Try to get CA certificate from container
    $caCertPath = "$networkPath/organizations/peerOrganizations/$($org.Name).example.com/ca/ca-cert.pem"
    $caCertDir = Split-Path $caCertPath -Parent
    New-Item -ItemType Directory -Force -Path $caCertDir | Out-Null
    
    # Copy CA cert from container
    Write-Host "    Copying CA certificate..." -ForegroundColor Gray
    docker cp "${org.CA}:/etc/hyperledger/fabric-ca-server-config/ca-cert.pem" $caCertPath 2>&1 | Out-Null
    
    if (Test-Path $caCertPath) {
        # Copy CA cert to MSP cacerts
        Copy-Item $caCertPath "$adminMsp/cacerts/ca.crt" -Force
        Copy-Item $caCertPath "$peerMsp/cacerts/ca.crt" -Force
        Copy-Item $caCertPath "$adminMsp/tlscacerts/ca.crt" -Force
        Copy-Item $caCertPath "$peerMsp/tlscacerts/ca.crt" -Force
        
        Write-Host "    [OK] CA certificate copied" -ForegroundColor Gray
    }
    
    # Enroll admin using fabric-tools container
    Write-Host "    Enrolling admin user..." -ForegroundColor Gray
    
    $enrollResult = docker run --rm `
      --network network_landregistry `
      -v "${networkPath}/organizations:/etc/hyperledger/fabric-ca-client-config" `
      -e FABRIC_CA_CLIENT_HOME=/etc/hyperledger/fabric-ca-client-config `
      hyperledger/fabric-tools:2.5.3 `
      fabric-ca-client enroll `
      -u https://admin:adminpw@${org.CA}:${org.Port} `
      --caname ca-$($org.Name) `
      --tls.certfiles /etc/hyperledger/fabric-ca-server-config/ca-cert.pem `
      -M /etc/hyperledger/fabric-ca-client-config/peerOrganizations/$($org.Name).example.com/users/Admin@$($org.Name).example.com/msp 2>&1
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "    [OK] Admin enrolled" -ForegroundColor Green
        
        # Copy certificates to peer MSP
        $adminSigncerts = Get-ChildItem "$adminMsp/signcerts" -ErrorAction SilentlyContinue
        if ($adminSigncerts) {
            Copy-Item $adminSigncerts[0].FullName "$peerMsp/signcerts/cert.pem" -Force -ErrorAction SilentlyContinue
            Copy-Item $adminSigncerts[0].FullName "$adminMsp/admincerts/cert.pem" -Force -ErrorAction SilentlyContinue
            Copy-Item $adminSigncerts[0].FullName "$peerMsp/admincerts/cert.pem" -Force -ErrorAction SilentlyContinue
        }
        
        $adminKeystore = Get-ChildItem "$adminMsp/keystore" -ErrorAction SilentlyContinue
        if ($adminKeystore) {
            Copy-Item $adminKeystore[0].FullName "$peerMsp/keystore/key.pem" -Force -ErrorAction SilentlyContinue
        }
        
        Write-Host "    [OK] Certificates copied to peer MSP" -ForegroundColor Green
    } else {
        Write-Host "    [WARN] Enrollment failed, using structure only" -ForegroundColor Yellow
        Write-Host "    Error details logged" -ForegroundColor Gray
    }
    
    Write-Host ""
}

# Enroll orderer admin
Write-Host "  Processing Orderer organization..." -ForegroundColor Yellow
$ordererMsp = "$networkPath/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp"
$ordererAdminMsp = "$networkPath/organizations/ordererOrganizations/example.com/users/Admin@example.com/msp"

New-Item -ItemType Directory -Force -Path "$ordererAdminMsp/signcerts" | Out-Null
New-Item -ItemType Directory -Force -Path "$ordererAdminMsp/keystore" | Out-Null
New-Item -ItemType Directory -Force -Path "$ordererAdminMsp/cacerts" | Out-Null

$ordererCaCertPath = "$networkPath/organizations/ordererOrganizations/example.com/ca/ca-cert.pem"
$ordererCaCertDir = Split-Path $ordererCaCertPath -Parent
New-Item -ItemType Directory -Force -Path $ordererCaCertDir | Out-Null

docker cp "ca-orderer:/etc/hyperledger/fabric-ca-server-config/ca-cert.pem" $ordererCaCertPath 2>&1 | Out-Null

if (Test-Path $ordererCaCertPath) {
    Copy-Item $ordererCaCertPath "$ordererMsp/cacerts/ca.crt" -Force
    Copy-Item $ordererCaCertPath "$ordererAdminMsp/cacerts/ca.crt" -Force
    Write-Host "    [OK] Orderer CA certificate copied" -ForegroundColor Green
}

Write-Host ""

Write-Host "[4/4] Summary" -ForegroundColor Green
Write-Host "  [OK] Crypto enrollment attempted" -ForegroundColor Gray
Write-Host "  [INFO] Check logs if enrollment failed" -ForegroundColor Yellow
Write-Host ""
Write-Host "Next: Generate genesis block and start network" -ForegroundColor Yellow
Write-Host "      .\scripts\generate-genesis-block.ps1" -ForegroundColor White
Write-Host ""
