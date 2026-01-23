# Generate connection profiles for backend (adapted from test-network ccp-generate.sh)

$ErrorActionPreference = "Stop"
$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = Split-Path -Parent $scriptRoot
$networkDir = Join-Path $projectRoot "network"
$orgsDir = Join-Path $networkDir "organizations"
$templatePath = Join-Path $orgsDir "ccp-template.json"

function Write-Info {
    param([string]$Message)
    Write-Host "INFO: $Message" -ForegroundColor Blue
}

function Write-Success {
    param([string]$Message)
    Write-Host "SUCCESS: $Message" -ForegroundColor Green
}

# Convert PEM to one-line format
function Convert-PemToOneLine {
    param([string]$PemPath)
    
    if (-not (Test-Path $PemPath)) {
        throw "PEM file not found: $PemPath"
    }
    
    $content = Get-Content $PemPath -Raw
    # Remove newlines and add escaped newlines
    $oneLine = $content -replace "`r`n", "\n" -replace "`n", "\n" -replace "`r", "\n"
    return $oneLine
}

# Generate connection profile for an organization
function New-ConnectionProfile {
    param(
        [string]$OrgName,
        [string]$OrgDomain,
        [string]$MspId,
        [int]$PeerPort,
        [int]$CaPort,
        [string]$CaName,
        [string]$PeerTlsCertPath,
        [string]$CaCertPath,
        [string]$OrdererTlsCertPath
    )
    
    Write-Info "Generating connection profile for $OrgName"
    
    $orgDir = Join-Path $orgsDir "peerOrganizations" $OrgDomain
    $outputPath = Join-Path $orgDir "connection-$($OrgName.ToLower()).json"
    
    if (-not (Test-Path $templatePath)) {
        throw "Template not found: $templatePath"
    }
    
    # Read template
    $template = Get-Content $templatePath -Raw
    
    # Convert PEMs to one-line format
    $peerPem = Convert-PemToOneLine -PemPath $PeerTlsCertPath
    $caPem = Convert-PemToOneLine -PemPath $CaCertPath
    $ordererPem = Convert-PemToOneLine -PemPath $OrdererTlsCertPath
    
    # Replace template variables
    $profile = $template `
        -replace '\$\{ORG\}', $OrgName `
        -replace '\$\{ORG_DOMAIN\}', $OrgDomain `
        -replace '\$\{ORG\}MSP', $MspId `
        -replace '\$\{P0PORT\}', $PeerPort `
        -replace '\$\{CAPORT\}', $CaPort `
        -replace '\$\{CA_NAME\}', $CaName `
        -replace '\$\{PEERPEM\}', $peerPem `
        -replace '\$\{CAPEM\}', $caPem `
        -replace '\$\{ORDERERPEM\}', $ordererPem
    
    # Ensure output directory exists
    if (-not (Test-Path $orgDir)) {
        New-Item -ItemType Directory -Path $orgDir -Force | Out-Null
    }
    
    # Write connection profile
    Set-Content -Path $outputPath -Value $profile
    
    Write-Success "Created connection profile: $outputPath"
    return $outputPath
}

# Main execution
Write-Info "Generating connection profiles..."

# Get orderer TLS cert
$ordererOrgDir = Join-Path $orgsDir "ordererOrganizations" "example.com"
$ordererTlsCertPath = Join-Path $ordererOrgDir "orderers" "orderer.example.com" "tls" "ca.crt"

if (-not (Test-Path $ordererTlsCertPath)) {
    throw "Orderer TLS cert not found: $ordererTlsCertPath. Please enroll orderer first."
}

# Generate connection profiles for each peer organization
$orgs = @(
    @{
        OrgName = "LandReg"
        OrgDomain = "landreg.example.com"
        MspId = "LandRegMSP"
        PeerPort = 7051
        CaPort = 8054
        CaName = "ca-landreg"
        PeerTlsCertPath = Join-Path $orgsDir "peerOrganizations" "landreg.example.com" "tlsca" "tlsca.landreg.example.com-cert.pem"
        CaCertPath = Join-Path $orgsDir "fabric-ca" "landreg" "ca-cert.pem"
    },
    @{
        OrgName = "SubRegistrar"
        OrgDomain = "subregistrar.example.com"
        MspId = "SubRegistrarMSP"
        PeerPort = 8051
        CaPort = 9054
        CaName = "ca-subregistrar"
        PeerTlsCertPath = Join-Path $orgsDir "peerOrganizations" "subregistrar.example.com" "tlsca" "tlsca.subregistrar.example.com-cert.pem"
        CaCertPath = Join-Path $orgsDir "fabric-ca" "subregistrar" "ca-cert.pem"
    },
    @{
        OrgName = "Court"
        OrgDomain = "court.example.com"
        MspId = "CourtMSP"
        PeerPort = 9051
        CaPort = 10054
        CaName = "ca-court"
        PeerTlsCertPath = Join-Path $orgsDir "peerOrganizations" "court.example.com" "tlsca" "tlsca.court.example.com-cert.pem"
        CaCertPath = Join-Path $orgsDir "fabric-ca" "court" "ca-cert.pem"
    }
)

foreach ($org in $orgs) {
    try {
        New-ConnectionProfile `
            -OrgName $org.OrgName `
            -OrgDomain $org.OrgDomain `
            -MspId $org.MspId `
            -PeerPort $org.PeerPort `
            -CaPort $org.CaPort `
            -CaName $org.CaName `
            -PeerTlsCertPath $org.PeerTlsCertPath `
            -CaCertPath $org.CaCertPath `
            -OrdererTlsCertPath $ordererTlsCertPath
    } catch {
        Write-Error "Failed to generate connection profile for $($org.OrgName): $_"
        exit 1
    }
}

Write-Success "All connection profiles generated successfully!"
