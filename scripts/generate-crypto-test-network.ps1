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

# Check if Docker is available and fabric-tools image exists
function Test-FabricCAClient {
    try {
        docker ps | Out-Null
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Docker is not running. Please start Docker Desktop."
            return $false
        }
        
        # Check if fabric-tools image exists
        $imageExists = docker images hyperledger/fabric-tools:2.5.3 --format "{{.Repository}}:{{.Tag}}" 2>&1
        if ($imageExists -match "hyperledger/fabric-tools:2.5.3") {
            return $true
        } else {
            Write-Info "Pulling fabric-tools image..."
            docker pull hyperledger/fabric-tools:2.5.3
            return $LASTEXITCODE -eq 0
        }
    } catch {
        Write-Error "Docker is not available. Please install Docker Desktop."
        return $false
    }
}

# Run fabric-ca-client command using Docker
function Invoke-FabricCAClient {
    param(
        [string]$Command,
        [string]$WorkingDir,
        [string]$NetworkName = "landregistry_landregistry"
    )
    
    $networkPath = (Resolve-Path $projectRoot).Path
    $volumeMount = "${networkPath}/network/organizations:/etc/hyperledger/organizations"
    
    $dockerCmd = "docker run --rm --network $NetworkName -v ${volumeMount} -w /etc/hyperledger/organizations hyperledger/fabric-tools:2.5.3 $Command"
    
    Write-Info "Running: fabric-ca-client $Command"
    $result = Invoke-Expression $dockerCmd 2>&1
    return $result
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
            # Use Docker to run fabric-ca-client getcainfo
            $networkPath = (Resolve-Path $projectRoot).Path
            $volumeMount = "${networkPath}/network/organizations:/etc/hyperledger/organizations"
            $fabricCaClientHome = "/etc/hyperledger/organizations/fabric-ca/$CaOrg"
            $tlsCertPathDocker = "/etc/hyperledger/organizations/fabric-ca/$CaOrg/tls-cert.pem"
            
            # Map CA org name to container name
            $caContainerMap = @{
                "ordererOrg" = "ca-orderer"
                "landreg" = "ca-landreg"
                "subregistrar" = "ca-subregistrar"
                "court" = "ca-court"
            }
            $caContainer = $caContainerMap[$CaOrg]
            
            # Inside Docker network, all CAs listen on port 7054
            $dockerCmd = "docker run --rm --network landregistry_landregistry -v ${volumeMount} -e FABRIC_CA_CLIENT_HOME=$fabricCaClientHome hyperledger/fabric-tools:2.5.3 fabric-ca-client getcainfo -u https://admin:adminpw@${caContainer}:7054 --caname $CaName --tls.certfiles $tlsCertPathDocker"
            
            $result = Invoke-Expression $dockerCmd 2>&1
            
            if ($LASTEXITCODE -eq 0 -and (Test-Path $caCertPath)) {
                Write-Success "Retrieved CA certificate for $CaOrg"
                $success = $true
            } else {
                throw "ca-cert.pem not created or command failed"
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
