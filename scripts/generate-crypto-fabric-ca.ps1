# Generate Crypto Materials Using Fabric CA
# Based on Fabric's test-network approach
# Reference: network.sh createOrgs() function with CRYPTO="Certificate Authorities"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Generating Crypto Materials (Fabric CA)" -ForegroundColor Cyan
Write-Host "Based on Fabric's test-network approach" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$networkPath = (Resolve-Path "network").Path

# Function to enroll admin user
function EnrollAdmin {
    param([string]$Org, [string]$MSP, [string]$CAHost, [string]$CAPort, [string]$CAName)
    
    Write-Host "    Enrolling admin..." -ForegroundColor Gray
    
    $orgPath = "$networkPath/organizations/peerOrganizations/$Org.example.com"
    $adminMsp = "$orgPath/users/Admin@$Org.example.com/msp"
    $caCertPath = "$networkPath/organizations/peerOrganizations/$Org.example.com/ca/ca-cert.pem"
    
    # Create directories
    $mspSubdirs = @("signcerts", "keystore", "cacerts", "tlscacerts", "admincerts")
    foreach ($subdir in $mspSubdirs) {
        New-Item -ItemType Directory -Force -Path "$adminMsp/$subdir" | Out-Null
    }
    
    # Copy CA cert
    if (Test-Path $caCertPath) {
        Copy-Item $caCertPath "$adminMsp/cacerts/ca.crt" -Force
        Copy-Item $caCertPath "$adminMsp/tlscacerts/ca.crt" -Force
    }
    
    # Enroll admin
    $enrollResult = docker run --rm `
        --network network_landregistry `
        -v "${networkPath}/organizations:/etc/hyperledger/fabric-ca-client-config" `
        -e FABRIC_CA_CLIENT_HOME=/etc/hyperledger/fabric-ca-client-config/$Org.example.com `
        hyperledger/fabric-tools:2.5.3 `
        sh -c "fabric-ca-client enroll -u https://admin:adminpw@${CAHost}:${CAPort} --caname ${CAName} --tls.certfiles /etc/hyperledger/fabric-ca-client-config/peerOrganizations/$Org.example.com/ca/ca-cert.pem -M /etc/hyperledger/fabric-ca-client-config/peerOrganizations/$Org.example.com/users/Admin@$Org.example.com/msp" 2>&1
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "      [OK] Admin enrolled" -ForegroundColor Green
        return $true
    } else {
        Write-Host "      [WARN] Enrollment failed" -ForegroundColor Yellow
        return $false
    }
}

# Function to register and enroll peer
function RegisterEnrollPeer {
    param([string]$Org, [string]$MSP, [string]$CAHost, [string]$CAPort, [string]$CAName, [string]$PeerName)
    
    Write-Host "    Registering and enrolling peer..." -ForegroundColor Gray
    
    $orgPath = "$networkPath/organizations/peerOrganizations/$Org.example.com"
    $peerMsp = "$orgPath/peers/$PeerName/msp"
    $peerTls = "$orgPath/peers/$PeerName/tls"
    $caCertPath = "$networkPath/organizations/peerOrganizations/$Org.example.com/ca/ca-cert.pem"
    
    # Create directories
    $mspSubdirs = @("signcerts", "keystore", "cacerts", "tlscacerts", "admincerts")
    foreach ($subdir in $mspSubdirs) {
        New-Item -ItemType Directory -Force -Path "$peerMsp/$subdir" | Out-Null
    }
    New-Item -ItemType Directory -Force -Path "$peerTls" | Out-Null
    
    # Copy CA cert
    if (Test-Path $caCertPath) {
        Copy-Item $caCertPath "$peerMsp/cacerts/ca.crt" -Force
        Copy-Item $caCertPath "$peerMsp/tlscacerts/ca.crt" -Force
    }
    
    # Register peer
    $registerResult = docker run --rm `
        --network network_landregistry `
        -v "${networkPath}/organizations:/etc/hyperledger/fabric-ca-client-config" `
        -e FABRIC_CA_CLIENT_HOME=/etc/hyperledger/fabric-ca-client-config/$Org.example.com `
        hyperledger/fabric-tools:2.5.3 `
        sh -c "fabric-ca-client register --caname ${CAName} --id.name ${PeerName} --id.secret ${PeerName}pw --id.type peer --tls.certfiles /etc/hyperledger/fabric-ca-client-config/peerOrganizations/$Org.example.com/ca/ca-cert.pem -u https://admin:adminpw@${CAHost}:${CAPort}" 2>&1
    
    # Enroll peer
    $enrollResult = docker run --rm `
        --network network_landregistry `
        -v "${networkPath}/organizations:/etc/hyperledger/fabric-ca-client-config" `
        -e FABRIC_CA_CLIENT_HOME=/etc/hyperledger/fabric-ca-client-config/$Org.example.com `
        hyperledger/fabric-tools:2.5.3 `
        sh -c "fabric-ca-client enroll -u https://${PeerName}:${PeerName}pw@${CAHost}:${CAPort} --caname ${CAName} --tls.certfiles /etc/hyperledger/fabric-ca-client-config/peerOrganizations/$Org.example.com/ca/ca-cert.pem -M /etc/hyperledger/fabric-ca-client-config/peerOrganizations/$Org.example.com/peers/$PeerName/msp --csr.hosts ${PeerName}" 2>&1
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "      [OK] Peer enrolled" -ForegroundColor Green
        
        # Copy admin certs to peer MSP
        $adminMsp = "$orgPath/users/Admin@$Org.example.com/msp"
        $adminSigncerts = Get-ChildItem "$adminMsp/signcerts" -ErrorAction SilentlyContinue
        if ($adminSigncerts) {
            Copy-Item $adminSigncerts[0].FullName "$peerMsp/admincerts/Admin@$Org.example.com-cert.pem" -Force -ErrorAction SilentlyContinue
        }
        return $true
    } else {
        Write-Host "      [WARN] Peer enrollment failed" -ForegroundColor Yellow
        return $false
    }
}

# Step 1: Clean up existing crypto materials
Write-Host "[1/6] Cleaning up existing crypto materials..." -ForegroundColor Green
if (Test-Path "$networkPath/organizations/peerOrganizations") {
    Remove-Item -Recurse -Force "$networkPath/organizations/peerOrganizations" -ErrorAction SilentlyContinue
}
if (Test-Path "$networkPath/organizations/ordererOrganizations") {
    Remove-Item -Recurse -Force "$networkPath/organizations/ordererOrganizations" -ErrorAction SilentlyContinue
}
Write-Host "  [OK] Cleanup complete" -ForegroundColor Gray
Write-Host ""

# Step 2: Start CAs
Write-Host "[2/6] Starting Certificate Authorities..." -ForegroundColor Green
Push-Location network
docker-compose -f docker-compose.yml up -d ca-orderer ca-landreg ca-subregistrar ca-court
Write-Host "  Waiting for CAs to start..." -ForegroundColor Yellow
Start-Sleep -Seconds 10
Pop-Location
Write-Host "  [OK] CAs started" -ForegroundColor Gray
Write-Host ""

# Step 3: Wait for CA files to be created (like test-network does)
Write-Host "[3/6] Waiting for CA certificates..." -ForegroundColor Green
$maxWait = 30
$waited = 0

$orgs = @(
    @{Name="landreg"; CA="ca-landreg"; Port="7054"; CAName="ca-landreg"},
    @{Name="subregistrar"; CA="ca-subregistrar"; Port="8054"; CAName="ca-subregistrar"},
    @{Name="court"; CA="ca-court"; Port="9054"; CAName="ca-court"},
    @{Name="orderer"; CA="ca-orderer"; Port="7054"; CAName="ca-orderer"}
)

foreach ($org in $orgs) {
    if ($org.Name -eq "orderer") {
        $caCertPath = "$networkPath/organizations/ordererOrganizations/example.com/ca/ca-cert.pem"
    } else {
        $caCertPath = "$networkPath/organizations/peerOrganizations/$($org.Name).example.com/ca/ca-cert.pem"
    }
    
    $fileDir = Split-Path $caCertPath -Parent
    New-Item -ItemType Directory -Force -Path $fileDir | Out-Null
    
    # Copy CA cert from container
    docker cp "${org.CA}:/etc/hyperledger/fabric-ca-server-config/ca-cert.pem" $caCertPath 2>&1 | Out-Null
    
    # Also create a copy in fabric-ca directory for easier access
    $fabricCaPath = "$networkPath/organizations/fabric-ca/$($org.Name)/ca-cert.pem"
    $fabricCaDir = Split-Path $fabricCaPath -Parent
    New-Item -ItemType Directory -Force -Path $fabricCaDir | Out-Null
    if (Test-Path $caCertPath) {
        Copy-Item $caCertPath $fabricCaPath -Force
        Write-Host "  [OK] $($org.Name) CA cert ready" -ForegroundColor Green
    } else {
        Write-Host "  [WARN] $($org.Name) CA cert not ready" -ForegroundColor Yellow
    }
}
Write-Host ""

# Step 4: Wait for CA service to be ready (using getcainfo like test-network)
Write-Host "[4/6] Verifying CA services are ready..." -ForegroundColor Green
foreach ($org in $orgs) {
    Write-Host "  Checking $($org.Name) CA..." -ForegroundColor Gray
    $caCertPath = "$networkPath/organizations/fabric-ca/$($org.Name)/ca-cert.pem"
    
    if (Test-Path $caCertPath) {
        $getcainfoResult = docker run --rm `
            --network network_landregistry `
            -v "${networkPath}/organizations:/etc/hyperledger/fabric-ca-client-config" `
            hyperledger/fabric-tools:2.5.3 `
            if ($org.Name -eq "orderer") {
            $caCertPathForCheck = "$networkPath/organizations/ordererOrganizations/example.com/ca/ca-cert.pem"
        } else {
            $caCertPathForCheck = "$networkPath/organizations/peerOrganizations/$($org.Name).example.com/ca/ca-cert.pem"
        }
        sh -c "fabric-ca-client getcainfo -u https://admin:adminpw@$($org.CA):$($org.Port) --caname $($org.CAName) --tls.certfiles /etc/hyperledger/fabric-ca-client-config/peerOrganizations/$($org.Name).example.com/ca/ca-cert.pem" 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "    [OK] $($org.Name) CA is ready" -ForegroundColor Green
        } else {
            Write-Host "    [WARN] $($org.Name) CA not fully ready" -ForegroundColor Yellow
        }
    }
}
Write-Host ""

# Step 5: Create identities for each organization
Write-Host "[5/6] Creating identities for organizations..." -ForegroundColor Green

# Create LandReg identities
Write-Host "  Creating LandReg identities..." -ForegroundColor Yellow
$landregAdmin = EnrollAdmin -Org "landreg" -MSP "LandRegMSP" -CAHost "ca-landreg" -CAPort "7054" -CAName "ca-landreg"
$landregPeer = RegisterEnrollPeer -Org "landreg" -MSP "LandRegMSP" -CAHost "ca-landreg" -CAPort "7054" -CAName "ca-landreg" -PeerName "peer0.landreg.example.com"

# Create SubRegistrar identities
Write-Host "  Creating SubRegistrar identities..." -ForegroundColor Yellow
$subregistrarAdmin = EnrollAdmin -Org "subregistrar" -MSP "SubRegistrarMSP" -CAHost "ca-subregistrar" -CAPort "8054" -CAName "ca-subregistrar"
$subregistrarPeer = RegisterEnrollPeer -Org "subregistrar" -MSP "SubRegistrarMSP" -CAHost "ca-subregistrar" -CAPort "8054" -CAName "ca-subregistrar" -PeerName "peer0.subregistrar.example.com"

# Create Court identities
Write-Host "  Creating Court identities..." -ForegroundColor Yellow
$courtAdmin = EnrollAdmin -Org "court" -MSP "CourtMSP" -CAHost "ca-court" -CAPort "9054" -CAName "ca-court"
$courtPeer = RegisterEnrollPeer -Org "court" -MSP "CourtMSP" -CAHost "ca-court" -CAPort "9054" -CAName "ca-court" -PeerName "peer0.court.example.com"

# Create Orderer identities
Write-Host "  Creating Orderer identities..." -ForegroundColor Yellow
$ordererPath = "$networkPath/organizations/ordererOrganizations/example.com"
$ordererMsp = "$ordererPath/orderers/orderer.example.com/msp"
$ordererTls = "$ordererPath/orderers/orderer.example.com/tls"
$ordererAdminMsp = "$ordererPath/users/Admin@example.com/msp"
    $ordererCaCertPath = "$networkPath/organizations/ordererOrganizations/example.com/ca/ca-cert.pem"

# Create directories
$mspSubdirs = @("signcerts", "keystore", "cacerts", "tlscacerts", "admincerts")
foreach ($subdir in $mspSubdirs) {
    New-Item -ItemType Directory -Force -Path "$ordererMsp/$subdir" | Out-Null
    New-Item -ItemType Directory -Force -Path "$ordererAdminMsp/$subdir" | Out-Null
}
New-Item -ItemType Directory -Force -Path "$ordererTls" | Out-Null

# Copy CA cert
if (Test-Path $ordererCaCertPath) {
    Copy-Item $ordererCaCertPath "$ordererMsp/cacerts/ca.crt" -Force
    Copy-Item $ordererCaCertPath "$ordererAdminMsp/cacerts/ca.crt" -Force
}

# Enroll orderer admin
Write-Host "    Enrolling orderer admin..." -ForegroundColor Gray
$ordererAdminResult = docker run --rm `
    --network network_landregistry `
    -v "${networkPath}/organizations:/etc/hyperledger/fabric-ca-client-config" `
    -e FABRIC_CA_CLIENT_HOME=/etc/hyperledger/fabric-ca-client-config/ordererOrganizations/example.com `
    hyperledger/fabric-tools:2.5.3 `
    sh -c "fabric-ca-client enroll -u https://admin:adminpw@ca-orderer:7054 --caname ca-orderer --tls.certfiles /etc/hyperledger/fabric-ca-client-config/ordererOrganizations/example.com/ca/ca-cert.pem -M /etc/hyperledger/fabric-ca-client-config/ordererOrganizations/example.com/users/Admin@example.com/msp" 2>&1

if ($LASTEXITCODE -eq 0) {
    Write-Host "      [OK] Orderer admin enrolled" -ForegroundColor Green
} else {
    Write-Host "      [WARN] Orderer admin enrollment had issues" -ForegroundColor Yellow
}

# Register and enroll orderer
Write-Host "    Registering orderer..." -ForegroundColor Gray
$ordererRegisterResult = docker run --rm `
    --network network_landregistry `
    -v "${networkPath}/organizations:/etc/hyperledger/fabric-ca-client-config" `
    -e FABRIC_CA_CLIENT_HOME=/etc/hyperledger/fabric-ca-client-config/ordererOrganizations/example.com `
    hyperledger/fabric-tools:2.5.3 `
    sh -c "fabric-ca-client register --caname ca-orderer --id.name orderer --id.secret ordererpw --id.type orderer --tls.certfiles /etc/hyperledger/fabric-ca-client-config/ordererOrganizations/example.com/ca/ca-cert.pem -u https://admin:adminpw@ca-orderer:7054" 2>&1

Write-Host "    Enrolling orderer..." -ForegroundColor Gray
$ordererEnrollResult = docker run --rm `
    --network network_landregistry `
    -v "${networkPath}/organizations:/etc/hyperledger/fabric-ca-client-config" `
    -e FABRIC_CA_CLIENT_HOME=/etc/hyperledger/fabric-ca-client-config/ordererOrganizations/example.com `
    hyperledger/fabric-tools:2.5.3 `
    sh -c "fabric-ca-client enroll -u https://orderer:ordererpw@ca-orderer:7054 --caname ca-orderer --tls.certfiles /etc/hyperledger/fabric-ca-client-config/ordererOrganizations/example.com/ca/ca-cert.pem -M /etc/hyperledger/fabric-ca-client-config/ordererOrganizations/example.com/orderers/orderer.example.com/msp --csr.hosts orderer.example.com" 2>&1

if ($LASTEXITCODE -eq 0) {
    Write-Host "      [OK] Orderer enrolled" -ForegroundColor Green
} else {
    Write-Host "      [WARN] Orderer enrollment had issues" -ForegroundColor Yellow
}

Write-Host ""

# Step 6: Create MSP config files
Write-Host "[6/6] Creating MSP configuration files..." -ForegroundColor Green

# Create config.yaml for each MSP
$mspConfig = @"
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

$ordererMspConfig = @"
NodeOUs:
  Enable: true
  OrdererOUIdentifier:
    Certificate: cacerts/ca.crt
    OrganizationalUnitIdentifier: orderer
"@

# Apply to all peer orgs
foreach ($org in $orgs) {
    if ($org.Name -ne "orderer") {
        $orgMsp = "$networkPath/organizations/peerOrganizations/$($org.Name).example.com/msp"
        $adminMsp = "$networkPath/organizations/peerOrganizations/$($org.Name).example.com/users/Admin@$($org.Name).example.com/msp"
        $peerMsp = "$networkPath/organizations/peerOrganizations/$($org.Name).example.com/peers/peer0.$($org.Name).example.com/msp"
        
        # Create directories if they don't exist
        New-Item -ItemType Directory -Force -Path $orgMsp | Out-Null
        New-Item -ItemType Directory -Force -Path (Split-Path "$adminMsp/config.yaml" -Parent) | Out-Null
        New-Item -ItemType Directory -Force -Path (Split-Path "$peerMsp/config.yaml" -Parent) | Out-Null
        
        Set-Content -Path "$orgMsp/config.yaml" -Value $mspConfig -Force -ErrorAction SilentlyContinue
        Set-Content -Path "$adminMsp/config.yaml" -Value $mspConfig -Force -ErrorAction SilentlyContinue
        Set-Content -Path "$peerMsp/config.yaml" -Value $mspConfig -Force -ErrorAction SilentlyContinue
    }
}

# Apply to orderer
New-Item -ItemType Directory -Force -Path (Split-Path "$ordererMsp/config.yaml" -Parent) | Out-Null
New-Item -ItemType Directory -Force -Path (Split-Path "$ordererAdminMsp/config.yaml" -Parent) | Out-Null
Set-Content -Path "$ordererMsp/config.yaml" -Value $ordererMspConfig -Force -ErrorAction SilentlyContinue
Set-Content -Path "$ordererAdminMsp/config.yaml" -Value $ordererMspConfig -Force -ErrorAction SilentlyContinue

Write-Host "  [OK] MSP config files created" -ForegroundColor Green
Write-Host ""

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Crypto Generation Complete" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "  1. Generate genesis block: .\scripts\generate-genesis-block.ps1" -ForegroundColor White
Write-Host "  2. Start network: cd network; docker-compose up -d" -ForegroundColor White
Write-Host "  3. Create channel: .\scripts\create-channel-full.ps1" -ForegroundColor White
Write-Host "  4. Deploy chaincode: .\scripts\deploy-chaincode.ps1" -ForegroundColor White
Write-Host ""
