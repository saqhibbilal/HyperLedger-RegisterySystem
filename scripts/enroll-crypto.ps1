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

# Detect Docker network (project may be 'network' or 'consortium' depending on how compose was started)
$dockerNet = (docker inspect ca-orderer --format '{{range $k, $v := .NetworkSettings.Networks}}{{$k}}{{end}}' 2>$null)
if (-not $dockerNet) { $dockerNet = "network_landregistry" }

# Organizations to process (Port 7054 = container internal port for all CAs when using Docker network)
$orgs = @(
    @{Name="landreg"; CA="ca-landreg"; Port="7054"; MSP="LandRegMSP"},
    @{Name="subregistrar"; CA="ca-subregistrar"; Port="7054"; MSP="SubRegistrarMSP"},
    @{Name="court"; CA="ca-court"; Port="7054"; MSP="CourtMSP"}
)

Write-Host "[3/4] Enrolling admin users..." -ForegroundColor Green

foreach ($org in $orgs) {
    Write-Host "  Processing $($org.Name) organization..." -ForegroundColor Yellow
    
    $orgMsp = "$networkPath/organizations/peerOrganizations/$($org.Name).example.com/msp"
    $adminMsp = "$networkPath/organizations/peerOrganizations/$($org.Name).example.com/users/Admin@$($org.Name).example.com/msp"
    $peerMsp = "$networkPath/organizations/peerOrganizations/$($org.Name).example.com/peers/peer0.$($org.Name).example.com/msp"
    $caCertDir = "$networkPath/organizations/peerOrganizations/$($org.Name).example.com/ca"
    $tlsCertPath = "$caCertDir/tls-cert.pem"
    $caCertPath = "$caCertDir/ca-cert.pem"
    $tlsCertInContainer = "/etc/hyperledger/fabric-ca-client-config/peerOrganizations/$($org.Name).example.com/ca/tls-cert.pem"

    New-Item -ItemType Directory -Force -Path $caCertDir | Out-Null
    New-Item -ItemType Directory -Force -Path "$orgMsp/cacerts" | Out-Null
    New-Item -ItemType Directory -Force -Path "$orgMsp/tlscacerts" | Out-Null
    New-Item -ItemType Directory -Force -Path "$adminMsp/cacerts" | Out-Null
    New-Item -ItemType Directory -Force -Path "$adminMsp/tlscacerts" | Out-Null
    New-Item -ItemType Directory -Force -Path "$adminMsp/admincerts" | Out-Null
    New-Item -ItemType Directory -Force -Path "$peerMsp/cacerts" | Out-Null
    New-Item -ItemType Directory -Force -Path "$peerMsp/tlscacerts" | Out-Null
    New-Item -ItemType Directory -Force -Path "$peerMsp/admincerts" | Out-Null
    New-Item -ItemType Directory -Force -Path "$peerMsp/signcerts" | Out-Null
    New-Item -ItemType Directory -Force -Path "$peerMsp/keystore" | Out-Null

    # Get CA TLS cert: prefer host fabric-ca/org/ (same as container mount); fallback to docker cp
    Write-Host "    Copying CA TLS certificate..." -ForegroundColor Gray
    $fabricCaOrg = Join-Path $networkPath "organizations/fabric-ca/$($org.Name)"
    if (Test-Path "$fabricCaOrg/tls-cert.pem") {
        Copy-Item "$fabricCaOrg/tls-cert.pem" $tlsCertPath -Force
    }
    if (Test-Path "$fabricCaOrg/ca-cert.pem") {
        Copy-Item "$fabricCaOrg/ca-cert.pem" $caCertPath -Force
    }
    if (-not (Test-Path $tlsCertPath)) {
        $cn = $org.CA
        if ($cn) {
            docker cp "${cn}:/etc/hyperledger/fabric-ca-server-config/tls-cert.pem" $tlsCertPath 2>$null
        }
        if (-not (Test-Path $tlsCertPath) -and (Test-Path "$fabricCaOrg/tls-cert.pem")) {
            Copy-Item "$fabricCaOrg/tls-cert.pem" $tlsCertPath -Force
        }
    }
    if (-not (Test-Path $caCertPath)) {
        $cn = $org.CA
        if ($cn) {
            docker cp "${cn}:/etc/hyperledger/fabric-ca-server-config/ca-cert.pem" $caCertPath 2>$null
        }
        if (-not (Test-Path $caCertPath) -and (Test-Path "$fabricCaOrg/ca-cert.pem")) {
            Copy-Item "$fabricCaOrg/ca-cert.pem" $caCertPath -Force
        }
    }

    $certToUse = if (Test-Path $caCertPath) { $caCertPath } elseif (Test-Path $tlsCertPath) { $tlsCertPath } else { $null }
    if ($certToUse) {
        Copy-Item $certToUse "$orgMsp/cacerts/ca.crt" -Force
        Copy-Item $certToUse "$orgMsp/tlscacerts/ca.crt" -Force
        Copy-Item $certToUse "$adminMsp/cacerts/ca.crt" -Force
        Copy-Item $certToUse "$peerMsp/cacerts/ca.crt" -Force
        Copy-Item $certToUse "$adminMsp/tlscacerts/ca.crt" -Force
        Copy-Item $certToUse "$peerMsp/tlscacerts/ca.crt" -Force
        Write-Host "    [OK] CA certificate ready" -ForegroundColor Gray
    }

    # Enroll: --tls.certfiles must point to a path inside the mounted volume (fabric-tools has no fabric-ca-server-config)
    $tlsForEnroll = if (Test-Path $tlsCertPath) { $tlsCertInContainer } else { $null }
    if (-not $tlsForEnroll) {
        Write-Host "    [WARN] tls-cert.pem not found, skipping enroll for $($org.Name)" -ForegroundColor Yellow
        Write-Host ""
        continue
    }

    Write-Host "    Enrolling admin user..." -ForegroundColor Gray
    # Build URL with concatenation and pass via env to avoid PowerShell/Docker dropping CA hostname (https://:7054)
    $caHost = $org.CA
    $enrollUrl = 'https://admin:adminpw@' + $caHost + ':' + $org.Port
    $shCmd = 'fabric-ca-client enroll -u "$ENROLL_URL" --caname ca-' + $org.Name + ' --tls.certfiles ' + $tlsForEnroll + ' -M /etc/hyperledger/fabric-ca-client-config/peerOrganizations/' + $org.Name + '.example.com/users/Admin@' + $org.Name + '.example.com/msp'
    $enrollResult = docker run --rm `
      --network $dockerNet `
      -v "${networkPath}/organizations:/etc/hyperledger/fabric-ca-client-config" `
      -e FABRIC_CA_CLIENT_HOME=/etc/hyperledger/fabric-ca-client-config `
      -e "ENROLL_URL=$enrollUrl" `
      hyperledger/fabric-ca:1.5.3 `
      sh -c $shCmd 2>&1
    
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

        # Register and enroll peer0, create peer TLS (server.crt, server.key, ca.crt) so the peer container can start
        $peerTlsDir = "$networkPath/organizations/peerOrganizations/$($org.Name).example.com/peers/peer0.$($org.Name).example.com/tls"
        $peerTlsInContainer = "/etc/hyperledger/fabric-ca-client-config/peerOrganizations/$($org.Name).example.com/peers/peer0.$($org.Name).example.com/tls"

        Write-Host "    Registering peer0..." -ForegroundColor Gray
        $regPeer = docker run --rm --network $dockerNet `
          -v "${networkPath}/organizations:/etc/hyperledger/fabric-ca-client-config" `
          -e FABRIC_CA_CLIENT_HOME=/etc/hyperledger/fabric-ca-client-config `
          hyperledger/fabric-ca:1.5.3 `
          fabric-ca-client register -u "https://admin:adminpw@$($org.CA):$($org.Port)" --caname ca-$($org.Name) --id.name peer0 --id.secret peer0pw --id.type peer `
          --tls.certfiles $tlsForEnroll 2>&1
        if ($LASTEXITCODE -ne 0 -and $regPeer -notmatch "already registered") {
            Write-Host "    [WARN] peer0 register: $regPeer" -ForegroundColor Yellow
        }

        Write-Host "    Enrolling peer0 TLS..." -ForegroundColor Gray
        docker run --rm --network $dockerNet `
          -v "${networkPath}/organizations:/etc/hyperledger/fabric-ca-client-config" `
          -e FABRIC_CA_CLIENT_HOME=/etc/hyperledger/fabric-ca-client-config `
          hyperledger/fabric-ca:1.5.3 `
          fabric-ca-client enroll -u "https://peer0:peer0pw@$($org.CA):$($org.Port)" --caname ca-$($org.Name) `
          -M $peerTlsInContainer --enrollment.profile tls --csr.hosts "peer0.$($org.Name).example.com" `
          --tls.certfiles $tlsForEnroll 2>&1 | Out-Null
        if ($LASTEXITCODE -ne 0) { Write-Host "    [WARN] peer0 TLS enroll failed (peer may not start)" -ForegroundColor Yellow }

        # Copy TLS enroll output to server.crt, server.key, ca.crt (peer expects these in tls/)
        $sc = Get-ChildItem "$peerTlsDir/signcerts" -ErrorAction SilentlyContinue | Select-Object -First 1
        $ks = Get-ChildItem "$peerTlsDir/keystore" -ErrorAction SilentlyContinue | Select-Object -First 1
        $tc = Get-ChildItem "$peerTlsDir/tlscacerts" -ErrorAction SilentlyContinue | Select-Object -First 1
        if (-not $tc) { $tc = Get-ChildItem "$peerTlsDir" -Filter "*.pem" -ErrorAction SilentlyContinue | Select-Object -First 1 }
        if ($sc) { Copy-Item $sc.FullName "$peerTlsDir/server.crt" -Force }
        if ($ks) { Copy-Item $ks.FullName "$peerTlsDir/server.key" -Force }
        if ($tc) { Copy-Item $tc.FullName "$peerTlsDir/ca.crt" -Force }
        if (-not (Test-Path "$peerTlsDir/ca.crt") -and (Test-Path $tlsCertPath)) { Copy-Item $tlsCertPath "$peerTlsDir/ca.crt" -Force }

        if ((Test-Path "$peerTlsDir/server.crt") -and (Test-Path "$peerTlsDir/server.key") -and (Test-Path "$peerTlsDir/ca.crt")) {
            Write-Host "    [OK] Peer TLS (server.crt, server.key, ca.crt) ready" -ForegroundColor Green
        } else {
            Write-Host "    [WARN] Peer TLS incomplete; peer may exit on start" -ForegroundColor Yellow
        }
    } else {
        Write-Host "    [WARN] Enrollment failed, using structure only" -ForegroundColor Yellow
        if ($enrollResult) { Write-Host "    $enrollResult" -ForegroundColor Gray }
    }
    
    Write-Host ""
}

# Orderer org: CA cert, then register+enroll orderer with TLS (configtx needs orderers/.../tls/server.crt)
Write-Host "  Processing Orderer organization..." -ForegroundColor Yellow
$ordererMsp = "$networkPath/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp"
$ordererAdminMsp = "$networkPath/organizations/ordererOrganizations/example.com/users/Admin@example.com/msp"
$ordererCaDir = "$networkPath/organizations/ordererOrganizations/example.com/ca"
$ordererTlsDir = "$networkPath/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/tls"
$ordererTlsCertPath = "$ordererCaDir/tls-cert.pem"
$ordererCaCertPath = "$ordererCaDir/ca-cert.pem"
# test-network uses ca-cert.pem for --tls.certfiles; fall back to tls-cert.pem
$ordererTlsInContainer = "/etc/hyperledger/fabric-ca-client-config/ordererOrganizations/example.com/ca/tls-cert.pem"
$ordererCaCertInContainer = "/etc/hyperledger/fabric-ca-client-config/ordererOrganizations/example.com/ca/ca-cert.pem"

$ordererOrgMsp = "$networkPath/organizations/ordererOrganizations/example.com/msp"
New-Item -ItemType Directory -Force -Path "$ordererAdminMsp/signcerts" | Out-Null
New-Item -ItemType Directory -Force -Path "$ordererAdminMsp/keystore" | Out-Null
New-Item -ItemType Directory -Force -Path "$ordererAdminMsp/cacerts" | Out-Null
New-Item -ItemType Directory -Force -Path $ordererCaDir | Out-Null
New-Item -ItemType Directory -Force -Path "$ordererMsp/cacerts" | Out-Null
New-Item -ItemType Directory -Force -Path "$ordererOrgMsp/cacerts" | Out-Null
New-Item -ItemType Directory -Force -Path "$ordererOrgMsp/tlscacerts" | Out-Null
New-Item -ItemType Directory -Force -Path $ordererTlsDir | Out-Null

$ordererFabricCa = Join-Path $networkPath "organizations/fabric-ca/ordererOrg"
if (Test-Path "$ordererFabricCa/tls-cert.pem") { Copy-Item "$ordererFabricCa/tls-cert.pem" $ordererTlsCertPath -Force }
if (Test-Path "$ordererFabricCa/ca-cert.pem") { Copy-Item "$ordererFabricCa/ca-cert.pem" $ordererCaCertPath -Force }
if (-not (Test-Path $ordererTlsCertPath)) { docker cp "ca-orderer:/etc/hyperledger/fabric-ca-server-config/tls-cert.pem" $ordererTlsCertPath 2>$null }
if (-not (Test-Path $ordererCaCertPath)) { docker cp "ca-orderer:/etc/hyperledger/fabric-ca-server-config/ca-cert.pem" $ordererCaCertPath 2>$null }
if (-not (Test-Path $ordererTlsCertPath) -and (Test-Path "$ordererFabricCa/tls-cert.pem")) { Copy-Item "$ordererFabricCa/tls-cert.pem" $ordererTlsCertPath -Force }
if (-not (Test-Path $ordererCaCertPath) -and (Test-Path "$ordererFabricCa/ca-cert.pem")) { Copy-Item "$ordererFabricCa/ca-cert.pem" $ordererCaCertPath -Force }

$ordererCert = if (Test-Path $ordererCaCertPath) { $ordererCaCertPath } elseif (Test-Path $ordererTlsCertPath) { $ordererTlsCertPath } else { $null }
if ($ordererCert) {
    Copy-Item $ordererCert "$ordererMsp/cacerts/ca.crt" -Force
    Copy-Item $ordererCert "$ordererAdminMsp/cacerts/ca.crt" -Force
    Copy-Item $ordererCert "$ordererOrgMsp/cacerts/ca.crt" -Force
    Copy-Item $ordererCert "$ordererOrgMsp/tlscacerts/ca.crt" -Force
    Write-Host "    [OK] Orderer CA certificate ready" -ForegroundColor Green
}

# Orderer flow aligned with test-network organizations/fabric-ca/registerEnroll.sh createOrderer():
# 1) Enroll "CA admin" to org msp (so register can use it with no -u); 2) Register orderer (no -u);
# 3) Enroll orderer MSP + TLS; 4) Copy tls to server.crt/key/ca.crt; 5) Register+enroll Admin@example.com
# test-network uses ca-cert.pem for --tls.certfiles (not tls-cert.pem)
$ordererTlsCertfiles = if (Test-Path $ordererCaCertPath) { $ordererCaCertInContainer } else { $ordererTlsInContainer }
if (Test-Path $ordererCaCertPath) {
    Write-Host "    Using ca-cert.pem for orderer CA client (test-network convention)" -ForegroundColor Gray
} elseif (-not (Test-Path $ordererTlsCertPath)) {
    Write-Host "    [WARN] Orderer CA ca-cert.pem and tls-cert.pem not found; orderer TLS not generated" -ForegroundColor Yellow
}

if ((Test-Path $ordererCaCertPath) -or (Test-Path $ordererTlsCertPath)) {
    # 1) Enroll "CA admin" to .../example.com/msp (like test-network: identity used by register with no -u)
    Write-Host "    Enrolling orderer CA admin to org msp..." -ForegroundColor Gray
    $adminEnrollOut = docker run --rm --network $dockerNet `
      -v "${networkPath}/organizations:/etc/hyperledger/fabric-ca-client-config" `
      -e FABRIC_CA_CLIENT_HOME=/etc/hyperledger/fabric-ca-client-config/ordererOrganizations/example.com `
      hyperledger/fabric-ca:1.5.3 `
      fabric-ca-client enroll -u "https://admin:adminpw@ca-orderer:7054" --caname ca-orderer `
      -M /etc/hyperledger/fabric-ca-client-config/ordererOrganizations/example.com/msp `
      --tls.certfiles $ordererTlsCertfiles 2>&1
    if ($LASTEXITCODE -ne 0) { Write-Host "    [WARN] Orderer CA admin enroll: $adminEnrollOut" -ForegroundColor Yellow }
    # Re-apply org CA cert to msp (enroll may have overwritten)
    if ($ordererCert) {
        Copy-Item $ordererCert "$ordererOrgMsp/cacerts/ca.crt" -Force
        Copy-Item $ordererCert "$ordererOrgMsp/tlscacerts/ca.crt" -Force
    }

    # 2) Register orderer (no -u: use enrolled CA admin from FABRIC_CA_CLIENT_HOME, like test-network)
    Write-Host "    Registering orderer..." -ForegroundColor Gray
    $regOut = docker run --rm --network $dockerNet `
      -v "${networkPath}/organizations:/etc/hyperledger/fabric-ca-client-config" `
      -e FABRIC_CA_CLIENT_HOME=/etc/hyperledger/fabric-ca-client-config/ordererOrganizations/example.com `
      hyperledger/fabric-ca:1.5.3 `
      fabric-ca-client register --caname ca-orderer --id.name orderer --id.secret ordererpw --id.type orderer `
      --tls.certfiles $ordererTlsCertfiles 2>&1
    if ($LASTEXITCODE -ne 0 -and $regOut -notmatch "already registered") {
        Write-Host "    [WARN] Orderer register: $regOut" -ForegroundColor Yellow
        Write-Host "    [INFO] For a clean slate: Remove-Item -Recurse -Force network\organizations\fabric-ca\ordererOrg; restart ca-orderer; re-run." -ForegroundColor Yellow
    }

    $ordererMspInContainer = "/etc/hyperledger/fabric-ca-client-config/ordererOrganizations/example.com/orderers/orderer.example.com/msp"
    $ordererTlsMspInContainer = "/etc/hyperledger/fabric-ca-client-config/ordererOrganizations/example.com/orderers/orderer.example.com/tls"

    Get-ChildItem $ordererTlsDir -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue

    # 3) Enroll orderer MSP and TLS (like test-network)
    Write-Host "    Enrolling orderer MSP and TLS..." -ForegroundColor Gray
    $mspOut = docker run --rm --network $dockerNet `
      -v "${networkPath}/organizations:/etc/hyperledger/fabric-ca-client-config" `
      -e FABRIC_CA_CLIENT_HOME=/etc/hyperledger/fabric-ca-client-config `
      hyperledger/fabric-ca:1.5.3 `
      fabric-ca-client enroll -u "https://orderer:ordererpw@ca-orderer:7054" --caname ca-orderer `
      -M $ordererMspInContainer --tls.certfiles $ordererTlsCertfiles 2>&1
    if ($LASTEXITCODE -ne 0) { Write-Host "    [WARN] Orderer MSP enroll: $mspOut" -ForegroundColor Yellow }

    $tlsOut = docker run --rm --network $dockerNet `
      -v "${networkPath}/organizations:/etc/hyperledger/fabric-ca-client-config" `
      -e FABRIC_CA_CLIENT_HOME=/etc/hyperledger/fabric-ca-client-config `
      hyperledger/fabric-ca:1.5.3 `
      fabric-ca-client enroll -u "https://orderer:ordererpw@ca-orderer:7054" --caname ca-orderer `
      -M $ordererTlsMspInContainer `
      --enrollment.profile tls --csr.hosts orderer.example.com --csr.hosts localhost `
      --tls.certfiles $ordererTlsCertfiles 2>&1
    if ($LASTEXITCODE -ne 0) { Write-Host "    [WARN] Orderer TLS enroll: $tlsOut" -ForegroundColor Yellow }

    # 4) Copy to server.crt, server.key, ca.crt (like test-network registerEnroll.sh)
    $ot = "$ordererTlsDir"
    $sc = Get-ChildItem "$ot/signcerts" -ErrorAction SilentlyContinue | Select-Object -First 1
    $ks = Get-ChildItem "$ot/keystore" -ErrorAction SilentlyContinue | Select-Object -First 1
    $tc = Get-ChildItem "$ot/tlscacerts" -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $sc) { $sc = Get-ChildItem "$ot" -Filter "*.pem" -ErrorAction SilentlyContinue | Select-Object -First 1 }
    if ($sc) { Copy-Item $sc.FullName "$ot/server.crt" -Force }
    if ($ks) { Copy-Item $ks.FullName "$ot/server.key" -Force }
    if ($tc) { Copy-Item $tc.FullName "$ot/ca.crt" -Force }
    if (-not (Test-Path "$ot/ca.crt") -and (Test-Path $ordererTlsCertPath)) { Copy-Item $ordererTlsCertPath "$ot/ca.crt" -Force }
    if ((Test-Path "$ot/server.crt") -and (Test-Path "$ot/server.key") -and (Test-Path "$ot/ca.crt")) {
        Write-Host "    [OK] Orderer TLS (server.crt, server.key, ca.crt) ready" -ForegroundColor Green
    } else {
        Write-Host "    [WARN] Orderer TLS incomplete; genesis may fail" -ForegroundColor Yellow
        if (-not (Test-Path "$ot/server.crt")) { Write-Host "      Missing: $ot/server.crt" -ForegroundColor Gray }
    }

    # 5) Register and enroll Admin@example.com (like test-network, done after orderer)
    Write-Host "    Registering and enrolling orderer Admin@example.com..." -ForegroundColor Gray
    docker run --rm --network $dockerNet `
      -v "${networkPath}/organizations:/etc/hyperledger/fabric-ca-client-config" `
      -e FABRIC_CA_CLIENT_HOME=/etc/hyperledger/fabric-ca-client-config/ordererOrganizations/example.com `
      hyperledger/fabric-ca:1.5.3 `
      fabric-ca-client register --caname ca-orderer --id.name ordererAdmin --id.secret ordererAdminpw --id.type admin `
      --tls.certfiles $ordererTlsCertfiles 2>&1 | Out-Null
    $adminOut = docker run --rm --network $dockerNet `
      -v "${networkPath}/organizations:/etc/hyperledger/fabric-ca-client-config" `
      -e FABRIC_CA_CLIENT_HOME=/etc/hyperledger/fabric-ca-client-config `
      hyperledger/fabric-ca:1.5.3 `
      fabric-ca-client enroll -u "https://ordererAdmin:ordererAdminpw@ca-orderer:7054" --caname ca-orderer `
      -M /etc/hyperledger/fabric-ca-client-config/ordererOrganizations/example.com/users/Admin@example.com/msp `
      --tls.certfiles $ordererTlsCertfiles 2>&1
    if ($LASTEXITCODE -ne 0) { Write-Host "    [WARN] Orderer Admin@example.com enroll: $adminOut" -ForegroundColor Yellow }
}

Write-Host ""

Write-Host "[4/4] Summary" -ForegroundColor Green
Write-Host "  [OK] Crypto enrollment attempted" -ForegroundColor Gray
Write-Host "  [INFO] If orderer enroll fails with 'Authentication failure', delete network\organizations\fabric-ca\ordererOrg, restart ca-orderer, then re-run." -ForegroundColor Yellow
Write-Host ""
Write-Host "Next: Generate genesis block and start network" -ForegroundColor Yellow
Write-Host "      .\scripts\generate-genesis-block.ps1" -ForegroundColor White
Write-Host ""
