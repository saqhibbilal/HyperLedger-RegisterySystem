# Enroll organizations using Fabric CA (adapted from test-network registerEnroll.sh)
# This script enrolls all organizations: LandReg, SubRegistrar, Court, and Orderer

$ErrorActionPreference = "Stop"
$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = Split-Path -Parent $scriptRoot
$networkDir = Join-Path $projectRoot "network"
$orgsDir = Join-Path $networkDir "organizations"
$fabricCaDir = Join-Path $orgsDir "fabric-ca"
$peerOrgsDir = Join-Path $orgsDir "peerOrganizations"
$ordererOrgsDir = Join-Path $orgsDir "ordererOrganizations"
$networkName = "landregistry_landregistry"

# Helper function to run fabric-ca-client via Docker
function Invoke-FabricCAClient {
    param(
        [string]$Command,
        [string]$ClientHome,
        [string]$AdditionalArgs = ""
    )
    
    $networkPath = (Resolve-Path $projectRoot).Path
    $volumeMount = "${networkPath}/network/organizations:/etc/hyperledger/organizations"
    $dockerClientHome = $ClientHome.Replace($networkPath + "\network\organizations", "/etc/hyperledger/organizations").Replace("\", "/")
    
    $dockerCmd = "docker run --rm --network $networkName -v ${volumeMount} -e FABRIC_CA_CLIENT_HOME=$dockerClientHome hyperledger/fabric-tools:2.5.3 fabric-ca-client $Command $AdditionalArgs"
    
    $result = Invoke-Expression $dockerCmd 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "fabric-ca-client command failed: $result"
    }
    return $result
}

# Colors for output
function Write-Info {
    param([string]$Message)
    Write-Host "INFO: $Message" -ForegroundColor Blue
}

function Write-Success {
    param([string]$Message)
    Write-Host "SUCCESS: $Message" -ForegroundColor Green
}

function Write-Error {
    param([string]$Message)
    Write-Host "ERROR: $Message" -ForegroundColor Red
}

# Create MSP config.yaml with NodeOUs
function New-MSPConfig {
    param(
        [string]$OrgDir,
        [string]$CaCertPath,
        [int]$CaPort,
        [string]$CaName
    )
    
    $mspDir = Join-Path $OrgDir "msp"
    $configPath = Join-Path $mspDir "config.yaml"
    
    if (-not (Test-Path $mspDir)) {
        New-Item -ItemType Directory -Path $mspDir -Force | Out-Null
    }
    
    $configContent = @"
NodeOUs:
  Enable: true
  ClientOUIdentifier:
    Certificate: cacerts/localhost-$CaPort-$CaName.pem
    OrganizationalUnitIdentifier: client
  PeerOUIdentifier:
    Certificate: cacerts/localhost-$CaPort-$CaName.pem
    OrganizationalUnitIdentifier: peer
  AdminOUIdentifier:
    Certificate: cacerts/localhost-$CaPort-$CaName.pem
    OrganizationalUnitIdentifier: admin
  OrdererOUIdentifier:
    Certificate: cacerts/localhost-$CaPort-$CaName.pem
    OrganizationalUnitIdentifier: orderer
"@
    
    Set-Content -Path $configPath -Value $configContent
    Write-Info "Created MSP config.yaml for $OrgDir"
}

# Enroll LandReg organization
function Enroll-LandReg {
    Write-Info "Creating LandReg Identities"
    
    $orgDir = Join-Path $peerOrgsDir "landreg.example.com"
    $fabricCaOrgDir = Join-Path $fabricCaDir "landreg"
    $caCertPath = Join-Path $fabricCaOrgDir "ca-cert.pem"
    
    # Create directory
    if (-not (Test-Path $orgDir)) {
        New-Item -ItemType Directory -Path $orgDir -Force | Out-Null
    }
    
    # Set FABRIC_CA_CLIENT_HOME
    $env:FABRIC_CA_CLIENT_HOME = $orgDir
    
    # Enroll CA admin
    Write-Info "Enrolling the CA admin for LandReg"
    fabric-ca-client enroll `
        -u "https://admin:adminpw@localhost:8054" `
        --caname "ca-landreg" `
        --tls.certfiles $caCertPath
    
    # Create MSP config.yaml
    New-MSPConfig -OrgDir $orgDir -CaCertPath $caCertPath -CaPort 8054 -CaName "ca-landreg"
    
    # Copy CA certs to required locations
    $mspTlsDir = Join-Path $orgDir "msp" "tlscacerts"
    $tlscaDir = Join-Path $orgDir "tlsca"
    $caDir = Join-Path $orgDir "ca"
    
    New-Item -ItemType Directory -Path $mspTlsDir -Force | Out-Null
    New-Item -ItemType Directory -Path $tlscaDir -Force | Out-Null
    New-Item -ItemType Directory -Path $caDir -Force | Out-Null
    
    Copy-Item $caCertPath (Join-Path $mspTlsDir "ca.crt")
    Copy-Item $caCertPath (Join-Path $tlscaDir "tlsca.landreg.example.com-cert.pem")
    Copy-Item $caCertPath (Join-Path $caDir "ca.landreg.example.com-cert.pem")
    
    # Register identities
    Write-Info "Registering peer0 for LandReg"
    fabric-ca-client register `
        --caname "ca-landreg" `
        --id.name "peer0" `
        --id.secret "peer0pw" `
        --id.type peer `
        --tls.certfiles $caCertPath
    
    Write-Info "Registering user1 for LandReg"
    fabric-ca-client register `
        --caname "ca-landreg" `
        --id.name "user1" `
        --id.secret "user1pw" `
        --id.type client `
        --tls.certfiles $caCertPath
    
    Write-Info "Registering org admin for LandReg"
    fabric-ca-client register `
        --caname "ca-landreg" `
        --id.name "landregadmin" `
        --id.secret "landregadminpw" `
        --id.type admin `
        --tls.certfiles $caCertPath
    
    # Enroll peer0 MSP
    Write-Info "Generating the peer0 msp for LandReg"
    $peerMspDir = Join-Path $orgDir "peers" "peer0.landreg.example.com" "msp"
    New-Item -ItemType Directory -Path $peerMspDir -Force | Out-Null
    
    fabric-ca-client enroll `
        -u "https://peer0:peer0pw@localhost:8054" `
        --caname "ca-landreg" `
        -M $peerMspDir `
        --tls.certfiles $caCertPath
    
    Copy-Item (Join-Path $orgDir "msp" "config.yaml") (Join-Path $peerMspDir "config.yaml")
    
    # Enroll peer0 TLS
    Write-Info "Generating the peer0-tls certificates for LandReg"
    $peerTlsDir = Join-Path $orgDir "peers" "peer0.landreg.example.com" "tls"
    New-Item -ItemType Directory -Path $peerTlsDir -Force | Out-Null
    
    fabric-ca-client enroll `
        -u "https://peer0:peer0pw@localhost:8054" `
        --caname "ca-landreg" `
        -M $peerTlsDir `
        --enrollment.profile tls `
        --csr.hosts "peer0.landreg.example.com" `
        --csr.hosts "localhost" `
        --tls.certfiles $caCertPath
    
    # Copy TLS certs to well-known names
    $tlsCaCerts = Get-ChildItem (Join-Path $peerTlsDir "tlscacerts") | Select-Object -First 1
    $tlsSignCerts = Get-ChildItem (Join-Path $peerTlsDir "signcerts") | Select-Object -First 1
    $tlsKeystore = Get-ChildItem (Join-Path $peerTlsDir "keystore") | Select-Object -First 1
    
    Copy-Item $tlsCaCerts.FullName (Join-Path $peerTlsDir "ca.crt")
    Copy-Item $tlsSignCerts.FullName (Join-Path $peerTlsDir "server.crt")
    Copy-Item $tlsKeystore.FullName (Join-Path $peerTlsDir "server.key")
    
    # Enroll user1
    Write-Info "Generating the user msp for LandReg"
    $userMspDir = Join-Path $orgDir "users" "User1@landreg.example.com" "msp"
    New-Item -ItemType Directory -Path $userMspDir -Force | Out-Null
    
    fabric-ca-client enroll `
        -u "https://user1:user1pw@localhost:8054" `
        --caname "ca-landreg" `
        -M $userMspDir `
        --tls.certfiles $caCertPath
    
    Copy-Item (Join-Path $orgDir "msp" "config.yaml") (Join-Path $userMspDir "config.yaml")
    
    # Enroll admin
    Write-Info "Generating the org admin msp for LandReg"
    $adminMspDir = Join-Path $orgDir "users" "Admin@landreg.example.com" "msp"
    New-Item -ItemType Directory -Path $adminMspDir -Force | Out-Null
    
    fabric-ca-client enroll `
        -u "https://landregadmin:landregadminpw@localhost:8054" `
        --caname "ca-landreg" `
        -M $adminMspDir `
        --tls.certfiles $caCertPath
    
    Copy-Item (Join-Path $orgDir "msp" "config.yaml") (Join-Path $adminMspDir "config.yaml")
    
    Write-Success "LandReg organization enrolled successfully"
}

# Enroll SubRegistrar organization (similar pattern)
function Enroll-SubRegistrar {
    Write-Info "Creating SubRegistrar Identities"
    
    $orgDir = Join-Path $peerOrgsDir "subregistrar.example.com"
    $fabricCaOrgDir = Join-Path $fabricCaDir "subregistrar"
    $caCertPath = Join-Path $fabricCaOrgDir "ca-cert.pem"
    
    if (-not (Test-Path $orgDir)) {
        New-Item -ItemType Directory -Path $orgDir -Force | Out-Null
    }
    
    $env:FABRIC_CA_CLIENT_HOME = $orgDir
    
    Write-Info "Enrolling the CA admin for SubRegistrar"
    fabric-ca-client enroll `
        -u "https://admin:adminpw@localhost:9054" `
        --caname "ca-subregistrar" `
        --tls.certfiles $caCertPath
    
    New-MSPConfig -OrgDir $orgDir -CaCertPath $caCertPath -CaPort 9054 -CaName "ca-subregistrar"
    
    $mspTlsDir = Join-Path $orgDir "msp" "tlscacerts"
    $tlscaDir = Join-Path $orgDir "tlsca"
    $caDir = Join-Path $orgDir "ca"
    
    New-Item -ItemType Directory -Path $mspTlsDir -Force | Out-Null
    New-Item -ItemType Directory -Path $tlscaDir -Force | Out-Null
    New-Item -ItemType Directory -Path $caDir -Force | Out-Null
    
    Copy-Item $caCertPath (Join-Path $mspTlsDir "ca.crt")
    Copy-Item $caCertPath (Join-Path $tlscaDir "tlsca.subregistrar.example.com-cert.pem")
    Copy-Item $caCertPath (Join-Path $caDir "ca.subregistrar.example.com-cert.pem")
    
    Write-Info "Registering identities for SubRegistrar"
    fabric-ca-client register --caname "ca-subregistrar" --id.name "peer0" --id.secret "peer0pw" --id.type peer --tls.certfiles $caCertPath
    fabric-ca-client register --caname "ca-subregistrar" --id.name "user1" --id.secret "user1pw" --id.type client --tls.certfiles $caCertPath
    fabric-ca-client register --caname "ca-subregistrar" --id.name "subregistraradmin" --id.secret "subregistraradminpw" --id.type admin --tls.certfiles $caCertPath
    
    $peerMspDir = Join-Path $orgDir "peers" "peer0.subregistrar.example.com" "msp"
    New-Item -ItemType Directory -Path $peerMspDir -Force | Out-Null
    
    fabric-ca-client enroll -u "https://peer0:peer0pw@localhost:9054" --caname "ca-subregistrar" -M $peerMspDir --tls.certfiles $caCertPath
    Copy-Item (Join-Path $orgDir "msp" "config.yaml") (Join-Path $peerMspDir "config.yaml")
    
    $peerTlsDir = Join-Path $orgDir "peers" "peer0.subregistrar.example.com" "tls"
    New-Item -ItemType Directory -Path $peerTlsDir -Force | Out-Null
    
    fabric-ca-client enroll -u "https://peer0:peer0pw@localhost:9054" --caname "ca-subregistrar" -M $peerTlsDir --enrollment.profile tls --csr.hosts "peer0.subregistrar.example.com" --csr.hosts "localhost" --tls.certfiles $caCertPath
    
    $tlsCaCerts = Get-ChildItem (Join-Path $peerTlsDir "tlscacerts") | Select-Object -First 1
    $tlsSignCerts = Get-ChildItem (Join-Path $peerTlsDir "signcerts") | Select-Object -First 1
    $tlsKeystore = Get-ChildItem (Join-Path $peerTlsDir "keystore") | Select-Object -First 1
    
    Copy-Item $tlsCaCerts.FullName (Join-Path $peerTlsDir "ca.crt")
    Copy-Item $tlsSignCerts.FullName (Join-Path $peerTlsDir "server.crt")
    Copy-Item $tlsKeystore.FullName (Join-Path $peerTlsDir "server.key")
    
    $userMspDir = Join-Path $orgDir "users" "User1@subregistrar.example.com" "msp"
    New-Item -ItemType Directory -Path $userMspDir -Force | Out-Null
    fabric-ca-client enroll -u "https://user1:user1pw@localhost:9054" --caname "ca-subregistrar" -M $userMspDir --tls.certfiles $caCertPath
    Copy-Item (Join-Path $orgDir "msp" "config.yaml") (Join-Path $userMspDir "config.yaml")
    
    $adminMspDir = Join-Path $orgDir "users" "Admin@subregistrar.example.com" "msp"
    New-Item -ItemType Directory -Path $adminMspDir -Force | Out-Null
    fabric-ca-client enroll -u "https://subregistraradmin:subregistraradminpw@localhost:9054" --caname "ca-subregistrar" -M $adminMspDir --tls.certfiles $caCertPath
    Copy-Item (Join-Path $orgDir "msp" "config.yaml") (Join-Path $adminMspDir "config.yaml")
    
    Write-Success "SubRegistrar organization enrolled successfully"
}

# Enroll Court organization (similar pattern)
function Enroll-Court {
    Write-Info "Creating Court Identities"
    
    $orgDir = Join-Path $peerOrgsDir "court.example.com"
    $fabricCaOrgDir = Join-Path $fabricCaDir "court"
    $caCertPath = Join-Path $fabricCaOrgDir "ca-cert.pem"
    
    if (-not (Test-Path $orgDir)) {
        New-Item -ItemType Directory -Path $orgDir -Force | Out-Null
    }
    
    $env:FABRIC_CA_CLIENT_HOME = $orgDir
    
    Write-Info "Enrolling the CA admin for Court"
    fabric-ca-client enroll `
        -u "https://admin:adminpw@localhost:10054" `
        --caname "ca-court" `
        --tls.certfiles $caCertPath
    
    New-MSPConfig -OrgDir $orgDir -CaCertPath $caCertPath -CaPort 10054 -CaName "ca-court"
    
    $mspTlsDir = Join-Path $orgDir "msp" "tlscacerts"
    $tlscaDir = Join-Path $orgDir "tlsca"
    $caDir = Join-Path $orgDir "ca"
    
    New-Item -ItemType Directory -Path $mspTlsDir -Force | Out-Null
    New-Item -ItemType Directory -Path $tlscaDir -Force | Out-Null
    New-Item -ItemType Directory -Path $caDir -Force | Out-Null
    
    Copy-Item $caCertPath (Join-Path $mspTlsDir "ca.crt")
    Copy-Item $caCertPath (Join-Path $tlscaDir "tlsca.court.example.com-cert.pem")
    Copy-Item $caCertPath (Join-Path $caDir "ca.court.example.com-cert.pem")
    
    Write-Info "Registering identities for Court"
    fabric-ca-client register --caname "ca-court" --id.name "peer0" --id.secret "peer0pw" --id.type peer --tls.certfiles $caCertPath
    fabric-ca-client register --caname "ca-court" --id.name "user1" --id.secret "user1pw" --id.type client --tls.certfiles $caCertPath
    fabric-ca-client register --caname "ca-court" --id.name "courtadmin" --id.secret "courtadminpw" --id.type admin --tls.certfiles $caCertPath
    
    $peerMspDir = Join-Path $orgDir "peers" "peer0.court.example.com" "msp"
    New-Item -ItemType Directory -Path $peerMspDir -Force | Out-Null
    fabric-ca-client enroll -u "https://peer0:peer0pw@localhost:10054" --caname "ca-court" -M $peerMspDir --tls.certfiles $caCertPath
    Copy-Item (Join-Path $orgDir "msp" "config.yaml") (Join-Path $peerMspDir "config.yaml")
    
    $peerTlsDir = Join-Path $orgDir "peers" "peer0.court.example.com" "tls"
    New-Item -ItemType Directory -Path $peerTlsDir -Force | Out-Null
    fabric-ca-client enroll -u "https://peer0:peer0pw@localhost:10054" --caname "ca-court" -M $peerTlsDir --enrollment.profile tls --csr.hosts "peer0.court.example.com" --csr.hosts "localhost" --tls.certfiles $caCertPath
    
    $tlsCaCerts = Get-ChildItem (Join-Path $peerTlsDir "tlscacerts") | Select-Object -First 1
    $tlsSignCerts = Get-ChildItem (Join-Path $peerTlsDir "signcerts") | Select-Object -First 1
    $tlsKeystore = Get-ChildItem (Join-Path $peerTlsDir "keystore") | Select-Object -First 1
    
    Copy-Item $tlsCaCerts.FullName (Join-Path $peerTlsDir "ca.crt")
    Copy-Item $tlsSignCerts.FullName (Join-Path $peerTlsDir "server.crt")
    Copy-Item $tlsKeystore.FullName (Join-Path $peerTlsDir "server.key")
    
    $userMspDir = Join-Path $orgDir "users" "User1@court.example.com" "msp"
    New-Item -ItemType Directory -Path $userMspDir -Force | Out-Null
    fabric-ca-client enroll -u "https://user1:user1pw@localhost:10054" --caname "ca-court" -M $userMspDir --tls.certfiles $caCertPath
    Copy-Item (Join-Path $orgDir "msp" "config.yaml") (Join-Path $userMspDir "config.yaml")
    
    $adminMspDir = Join-Path $orgDir "users" "Admin@court.example.com" "msp"
    New-Item -ItemType Directory -Path $adminMspDir -Force | Out-Null
    fabric-ca-client enroll -u "https://courtadmin:courtadminpw@localhost:10054" --caname "ca-court" -M $adminMspDir --tls.certfiles $caCertPath
    Copy-Item (Join-Path $orgDir "msp" "config.yaml") (Join-Path $adminMspDir "config.yaml")
    
    Write-Success "Court organization enrolled successfully"
}

# Enroll Orderer organization
function Enroll-Orderer {
    Write-Info "Creating Orderer Org Identities"
    
    $orgDir = Join-Path $ordererOrgsDir "example.com"
    $fabricCaOrgDir = Join-Path $fabricCaDir "ordererOrg"
    $caCertPath = Join-Path $fabricCaOrgDir "ca-cert.pem"
    
    if (-not (Test-Path $orgDir)) {
        New-Item -ItemType Directory -Path $orgDir -Force | Out-Null
    }
    
    $env:FABRIC_CA_CLIENT_HOME = $orgDir
    
    Write-Info "Enrolling the CA admin for Orderer"
    fabric-ca-client enroll `
        -u "https://admin:adminpw@localhost:7054" `
        --caname "ca-orderer" `
        --tls.certfiles $caCertPath
    
    New-MSPConfig -OrgDir $orgDir -CaCertPath $caCertPath -CaPort 7054 -CaName "ca-orderer"
    
    $mspTlsDir = Join-Path $orgDir "msp" "tlscacerts"
    $tlscaDir = Join-Path $orgDir "tlsca"
    
    New-Item -ItemType Directory -Path $mspTlsDir -Force | Out-Null
    New-Item -ItemType Directory -Path $tlscaDir -Force | Out-Null
    
    Copy-Item $caCertPath (Join-Path $mspTlsDir "tlsca.example.com-cert.pem")
    Copy-Item $caCertPath (Join-Path $tlscaDir "tlsca.example.com-cert.pem")
    
    # Register and enroll orderer
    Write-Info "Registering orderer"
    fabric-ca-client register --caname "ca-orderer" --id.name "orderer" --id.secret "ordererpw" --id.type orderer --tls.certfiles $caCertPath
    
    Write-Info "Generating the orderer MSP"
    $ordererMspDir = Join-Path $orgDir "orderers" "orderer.example.com" "msp"
    New-Item -ItemType Directory -Path $ordererMspDir -Force | Out-Null
    
    fabric-ca-client enroll -u "https://orderer:ordererpw@localhost:7054" --caname "ca-orderer" -M $ordererMspDir --tls.certfiles $caCertPath
    Copy-Item (Join-Path $orgDir "msp" "config.yaml") (Join-Path $ordererMspDir "config.yaml")
    
    # Rename signcert to match expected name
    $signCertDir = Join-Path $ordererMspDir "signcerts"
    $oldCert = Join-Path $signCertDir "cert.pem"
    $newCert = Join-Path $signCertDir "orderer.example.com-cert.pem"
    if (Test-Path $oldCert) {
        Move-Item $oldCert $newCert -Force
    }
    
    Write-Info "Generating the orderer TLS certificates"
    $ordererTlsDir = Join-Path $orgDir "orderers" "orderer.example.com" "tls"
    New-Item -ItemType Directory -Path $ordererTlsDir -Force | Out-Null
    
    fabric-ca-client enroll -u "https://orderer:ordererpw@localhost:7054" --caname "ca-orderer" -M $ordererTlsDir --enrollment.profile tls --csr.hosts "orderer.example.com" --csr.hosts "localhost" --tls.certfiles $caCertPath
    
    $tlsCaCerts = Get-ChildItem (Join-Path $ordererTlsDir "tlscacerts") | Select-Object -First 1
    $tlsSignCerts = Get-ChildItem (Join-Path $ordererTlsDir "signcerts") | Select-Object -First 1
    $tlsKeystore = Get-ChildItem (Join-Path $ordererTlsDir "keystore") | Select-Object -First 1
    
    Copy-Item $tlsCaCerts.FullName (Join-Path $ordererTlsDir "ca.crt")
    Copy-Item $tlsSignCerts.FullName (Join-Path $ordererTlsDir "server.crt")
    Copy-Item $tlsKeystore.FullName (Join-Path $ordererTlsDir "server.key")
    
    # Copy TLS CA cert to orderer MSP tlscacerts
    $ordererMspTlsDir = Join-Path $ordererMspDir "tlscacerts"
    New-Item -ItemType Directory -Path $ordererMspTlsDir -Force | Out-Null
    Copy-Item $tlsCaCerts.FullName (Join-Path $ordererMspTlsDir "tlsca.example.com-cert.pem")
    
    # Register and enroll orderer admin
    Write-Info "Registering the orderer admin"
    fabric-ca-client register --caname "ca-orderer" --id.name "ordererAdmin" --id.secret "ordererAdminpw" --id.type admin --tls.certfiles $caCertPath
    
    Write-Info "Generating the admin msp"
    $adminMspDir = Join-Path $orgDir "users" "Admin@example.com" "msp"
    New-Item -ItemType Directory -Path $adminMspDir -Force | Out-Null
    fabric-ca-client enroll -u "https://ordererAdmin:ordererAdminpw@localhost:7054" --caname "ca-orderer" -M $adminMspDir --tls.certfiles $caCertPath
    Copy-Item (Join-Path $orgDir "msp" "config.yaml") (Join-Path $adminMspDir "config.yaml")
    
    Write-Success "Orderer organization enrolled successfully"
}

# Main execution
Write-Info "Starting organization enrollment..."

# Enroll all organizations
Enroll-LandReg
Enroll-SubRegistrar
Enroll-Court
Enroll-Orderer

Write-Success "All organizations enrolled successfully!"
Write-Info "Next step: Generate connection profiles using create-connection-profiles.ps1"
