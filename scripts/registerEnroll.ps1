# Register and Enroll Script
# Based on Fabric's test-network registerEnroll.sh approach
# This script registers and enrolls users for each organization

param(
    [string]$OrgName = "landreg",
    [string]$OrgMSP = "LandRegMSP",
    [string]$CAHost = "ca-landreg",
    [string]$CAPort = "7054",
    [string]$CAName = "ca-landreg"
)

$networkPath = (Resolve-Path "network").Path
$orgPath = "$networkPath/organizations/peerOrganizations/$OrgName.example.com"
$caPath = "$networkPath/organizations/fabric-ca/$OrgName"

# Set Fabric CA Client Home
$env:FABRIC_CA_CLIENT_HOME = $orgPath

# Function to enroll admin user
function EnrollAdmin {
    param([string]$Org, [string]$MSP, [string]$CAHost, [string]$CAPort, [string]$CAName)
    
    Write-Host "  Enrolling admin for $Org..." -ForegroundColor Gray
    
    $orgPath = "$networkPath/organizations/peerOrganizations/$Org.example.com"
    $adminMsp = "$orgPath/users/Admin@$Org.example.com/msp"
    $caCertPath = "$networkPath/organizations/fabric-ca/$Org/ca-cert.pem"
    
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
    
    # Enroll admin using fabric-tools container
    $enrollResult = docker run --rm `
        --network network_landregistry `
        -v "${networkPath}/organizations:/etc/hyperledger/fabric-ca-client-config" `
        -e FABRIC_CA_CLIENT_HOME=/etc/hyperledger/fabric-ca-client-config/$Org.example.com `
        hyperledger/fabric-tools:2.5.3 `
        sh -c "fabric-ca-client enroll -u https://admin:adminpw@${CAHost}:${CAPort} --caname ${CAName} --tls.certfiles /etc/hyperledger/fabric-ca-client-config/fabric-ca/$Org/ca-cert.pem -M /etc/hyperledger/fabric-ca-client-config/peerOrganizations/$Org.example.com/users/Admin@$Org.example.com/msp" 2>&1
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "    [OK] Admin enrolled" -ForegroundColor Green
        return $true
    } else {
        Write-Host "    [FAIL] Enrollment failed" -ForegroundColor Red
        Write-Host $enrollResult -ForegroundColor Red
        return $false
    }
}

# Function to register and enroll peer
function RegisterEnrollPeer {
    param([string]$Org, [string]$MSP, [string]$CAHost, [string]$CAPort, [string]$CAName, [string]$PeerName)
    
    Write-Host "  Registering and enrolling peer for $Org..." -ForegroundColor Gray
    
    $orgPath = "$networkPath/organizations/peerOrganizations/$Org.example.com"
    $peerMsp = "$orgPath/peers/$PeerName/msp"
    $peerTls = "$orgPath/peers/$PeerName/tls"
    $caCertPath = "$networkPath/organizations/fabric-ca/$Org/ca-cert.pem"
    
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
    
    # Register peer identity
    Write-Host "    Registering peer identity..." -ForegroundColor Gray
    $registerResult = docker run --rm `
        --network network_landregistry `
        -v "${networkPath}/organizations:/etc/hyperledger/fabric-ca-client-config" `
        -e FABRIC_CA_CLIENT_HOME=/etc/hyperledger/fabric-ca-client-config/$Org.example.com `
        hyperledger/fabric-tools:2.5.3 `
        sh -c "fabric-ca-client register --caname ${CAName} --id.name ${PeerName} --id.secret ${PeerName}pw --id.type peer --tls.certfiles /etc/hyperledger/fabric-ca-client-config/fabric-ca/$Org/ca-cert.pem -u https://admin:adminpw@${CAHost}:${CAPort}" 2>&1
    
    if ($LASTEXITCODE -ne 0 -and $registerResult -notmatch "already registered") {
        Write-Host "    [WARN] Registration failed or already exists" -ForegroundColor Yellow
    }
    
    # Enroll peer
    Write-Host "    Enrolling peer..." -ForegroundColor Gray
    $enrollResult = docker run --rm `
        --network network_landregistry `
        -v "${networkPath}/organizations:/etc/hyperledger/fabric-ca-client-config" `
        -e FABRIC_CA_CLIENT_HOME=/etc/hyperledger/fabric-ca-client-config/$Org.example.com `
        hyperledger/fabric-tools:2.5.3 `
        sh -c "fabric-ca-client enroll -u https://${PeerName}:${PeerName}pw@${CAHost}:${CAPort} --caname ${CAName} --tls.certfiles /etc/hyperledger/fabric-ca-client-config/fabric-ca/$Org/ca-cert.pem -M /etc/hyperledger/fabric-ca-client-config/peerOrganizations/$Org.example.com/peers/$PeerName/msp --csr.hosts ${PeerName}" 2>&1
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "    [OK] Peer enrolled" -ForegroundColor Green
        
        # Copy admin certs to peer MSP
        $adminMsp = "$orgPath/users/Admin@$Org.example.com/msp"
        $adminSigncerts = Get-ChildItem "$adminMsp/signcerts" -ErrorAction SilentlyContinue
        if ($adminSigncerts) {
            Copy-Item $adminSigncerts[0].FullName "$peerMsp/admincerts/Admin@$Org.example.com-cert.pem" -Force -ErrorAction SilentlyContinue
        }
        
        return $true
    } else {
        Write-Host "    [FAIL] Peer enrollment failed" -ForegroundColor Red
        Write-Host $enrollResult -ForegroundColor Red
        return $false
    }
}

# Export functions for use in other scripts
Export-ModuleMember -Function EnrollAdmin, RegisterEnrollPeer
