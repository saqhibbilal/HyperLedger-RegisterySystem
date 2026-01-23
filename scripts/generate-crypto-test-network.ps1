# Generate crypto materials using Fabric CA (adapted from test-network approach)
# This script follows the proven test-network methodology

param(
    [int]$MaxRetry = 30,
    [int]$RetryDelay = 2
)

$ErrorActionPreference = "Stop"
$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = Split-Path -Parent $scriptRoot
$networkDir = Join-Path $projectRoot "network"
$orgsDir = Join-Path $networkDir "organizations"
$fabricCaDir = Join-Path $orgsDir "fabric-ca"

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

function Write-Warning {
    param([string]$Message)
    Write-Host "WARNING: $Message" -ForegroundColor Yellow
}

# Check if fabric-ca-client is available
function Test-FabricCAClient {
    try {
        $null = fabric-ca-client version
        return $true
    } catch {
        Write-Error "fabric-ca-client not found. Please install Fabric binaries."
        return $false
    }
}

# Wait for CA to create tls-cert.pem
function Wait-ForCATLSCert {
    param(
        [string]$CaOrg,
        [int]$MaxRetries = 30,
        [int]$DelaySeconds = 2
    )
    
    $tlsCertPath = Join-Path $fabricCaDir $CaOrg "tls-cert.pem"
    $retries = 0
    
    Write-Info "Waiting for CA $CaOrg to create tls-cert.pem..."
    
    while ($retries -lt $MaxRetries) {
        if (Test-Path $tlsCertPath) {
            Write-Success "Found tls-cert.pem for $CaOrg"
            return $true
        }
        Start-Sleep -Seconds $DelaySeconds
        $retries++
    }
    
    Write-Error "Timeout waiting for tls-cert.pem for $CaOrg"
    return $false
}

# Get CA certificate using getcainfo
function Get-CACertificate {
    param(
        [string]$CaOrg,
        [string]$CaName,
        [int]$CaPort,
        [int]$MaxRetries = 30
    )
    
    $fabricCaOrgDir = Join-Path $fabricCaDir $CaOrg
    $tlsCertPath = Join-Path $fabricCaOrgDir "tls-cert.pem"
    $caCertPath = Join-Path $fabricCaOrgDir "ca-cert.pem"
    
    # Check if already exists
    if (Test-Path $caCertPath) {
        Write-Info "CA certificate already exists for $CaOrg, skipping getcainfo"
        return $true
    }
    
    Write-Info "Getting CA certificate for $CaOrg using getcainfo..."
    
    $retries = 0
    $success = $false
    
    while ($retries -lt $MaxRetries -and -not $success) {
        try {
            $env:FABRIC_CA_CLIENT_HOME = $fabricCaOrgDir
            fabric-ca-client getcainfo `
                -u "https://admin:adminpw@localhost:$CaPort" `
                --caname $CaName `
                --tls.certfiles $tlsCertPath
            
            if (Test-Path $caCertPath) {
                Write-Success "Retrieved CA certificate for $CaOrg"
                $success = $true
            } else {
                throw "ca-cert.pem not created"
            }
        } catch {
            $retries++
            if ($retries -lt $MaxRetries) {
                Write-Warning "Failed to get CA cert for $CaOrg (attempt $retries/$MaxRetries), retrying..."
                Start-Sleep -Seconds 2
            } else {
                Write-Error "Failed to get CA certificate for $CaOrg after $MaxRetries attempts"
                return $false
            }
        }
    }
    
    return $success
}

# Main execution
Write-Info "Starting crypto material generation using test-network approach..."

# Check prerequisites
if (-not (Test-FabricCAClient)) {
    exit 1
}

# Create fabric-ca directory structure
Write-Info "Creating fabric-ca directory structure..."
$caOrgs = @("ordererOrg", "landreg", "subregistrar", "court")
foreach ($org in $caOrgs) {
    $orgDir = Join-Path $fabricCaDir $org
    if (-not (Test-Path $orgDir)) {
        New-Item -ItemType Directory -Path $orgDir -Force | Out-Null
    }
}

# Start CA containers
Write-Info "Starting CA containers..."
Push-Location $networkDir
try {
    docker-compose up -d ca-orderer ca-landreg ca-subregistrar ca-court
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to start CA containers"
        exit 1
    }
    Write-Success "CA containers started"
} finally {
    Pop-Location
}

# Wait for all CAs to create tls-cert.pem
Write-Info "Waiting for CAs to initialize..."
$caConfigs = @(
    @{ Org = "ordererOrg"; Name = "ca-orderer"; Port = 7054 },
    @{ Org = "landreg"; Name = "ca-landreg"; Port = 8054 },
    @{ Org = "subregistrar"; Name = "ca-subregistrar"; Port = 9054 },
    @{ Org = "court"; Name = "ca-court"; Port = 10054 }
)

$allReady = $true
foreach ($config in $caConfigs) {
    if (-not (Wait-ForCATLSCert -CaOrg $config.Org -MaxRetries $MaxRetry -DelaySeconds $RetryDelay)) {
        $allReady = $false
    }
}

if (-not $allReady) {
    Write-Error "Not all CAs are ready. Please check CA container logs."
    exit 1
}

# Get CA certificates
Write-Info "Retrieving CA certificates..."
foreach ($config in $caConfigs) {
    if (-not (Get-CACertificate -CaOrg $config.Org -CaName $config.Name -CaPort $config.Port -MaxRetries $MaxRetry)) {
        Write-Error "Failed to get CA certificate for $($config.Org)"
        exit 1
    }
}

Write-Success "CA certificates retrieved successfully"

# Now enroll organizations (this will be done by separate script)
Write-Info "CA setup complete. Next step: Enroll organizations using enroll-orgs.ps1"
Write-Info "Run: .\scripts\enroll-orgs.ps1"
