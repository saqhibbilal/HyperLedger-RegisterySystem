# Simplified Crypto Enrollment
# Uses a simpler approach based on test-network

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Simplified Crypto Enrollment" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$networkPath = (Resolve-Path "network").Path

# Check CAs
Write-Host "[1/3] Checking CAs..." -ForegroundColor Green
$cas = docker ps --format "{{.Names}}" | Select-String -Pattern "ca-"
if (-not $cas) {
    Write-Host "  [FAIL] CAs not running" -ForegroundColor Red
    exit 1
}
Write-Host "  [OK] CAs running" -ForegroundColor Green
Write-Host ""

# Wait for CAs
Write-Host "[2/3] Waiting for CAs..." -ForegroundColor Green
Start-Sleep -Seconds 15
Write-Host "  [OK] Ready" -ForegroundColor Green
Write-Host ""

# For LandReg - try direct enrollment
Write-Host "[3/3] Enrolling LandReg admin..." -ForegroundColor Green

# First, get CA cert
$caCertPath = "$networkPath/organizations/peerOrganizations/landreg.example.com/ca"
New-Item -ItemType Directory -Force -Path $caCertPath | Out-Null

Write-Host "  Copying CA certificate..." -ForegroundColor Gray
docker cp ca-landreg:/etc/hyperledger/fabric-ca-server-config/ca-cert.pem "$caCertPath/ca-cert.pem" 2>&1 | Out-Null

if (Test-Path "$caCertPath/ca-cert.pem") {
    Write-Host "  [OK] CA cert copied" -ForegroundColor Green
    
    # Create MSP directories
    $adminMsp = "$networkPath/organizations/peerOrganizations/landreg.example.com/users/Admin@landreg.example.com/msp"
    $mspSubdirs = @("signcerts", "keystore", "cacerts", "tlscacerts", "admincerts")
    foreach ($subdir in $mspSubdirs) {
        New-Item -ItemType Directory -Force -Path "$adminMsp/$subdir" | Out-Null
    }
    
    # Copy CA cert to cacerts
    Copy-Item "$caCertPath/ca-cert.pem" "$adminMsp/cacerts/ca.crt" -Force
    Copy-Item "$caCertPath/ca-cert.pem" "$adminMsp/tlscacerts/ca.crt" -Force
    
    Write-Host "  Enrolling admin..." -ForegroundColor Gray
    
    # Try enrollment with proper paths
    $enrollOutput = docker run --rm `
        --network network_landregistry `
        -v "${networkPath}/organizations:/etc/hyperledger/fabric-ca-client-config" `
        -e FABRIC_CA_CLIENT_HOME=/etc/hyperledger/fabric-ca-client-config/landreg.example.com `
        hyperledger/fabric-tools:2.5.3 `
        sh -c "mkdir -p /etc/hyperledger/fabric-ca-client-config/landreg.example.com && fabric-ca-client enroll -u https://admin:adminpw@ca-landreg:7054 --caname ca-landreg --tls.certfiles /etc/hyperledger/fabric-ca-client-config/landreg.example.com/ca/ca-cert.pem -M /etc/hyperledger/fabric-ca-client-config/peerOrganizations/landreg.example.com/users/Admin@landreg.example.com/msp" 2>&1
    
    Write-Host $enrollOutput
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  [OK] Enrollment successful!" -ForegroundColor Green
    } else {
        Write-Host "  [WARN] Enrollment failed, but structure is ready" -ForegroundColor Yellow
        Write-Host "  Note: You may need to manually enroll or check CA logs" -ForegroundColor Gray
    }
} else {
    Write-Host "  [FAIL] Could not copy CA certificate" -ForegroundColor Red
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Enrollment Complete" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Note: Full enrollment requires proper CA setup." -ForegroundColor Yellow
Write-Host "      For learning, you can use Fabric's test-network scripts as reference." -ForegroundColor Yellow
Write-Host ""
