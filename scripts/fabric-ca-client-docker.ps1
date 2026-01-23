# Helper script to run fabric-ca-client via Docker
# This allows Windows users to use fabric-ca-client without installing binaries locally

param(
    [Parameter(Mandatory=$true, Position=0)]
    [string[]]$Arguments,
    
    [string]$ClientHome = "",
    [string]$NetworkName = "landregistry_landregistry"
)

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = Split-Path -Parent $scriptRoot
$networkPath = Join-Path $projectRoot "network"
$orgsPath = Join-Path $networkPath "organizations"

# Convert Windows paths to Docker paths
$volumeMount = "${networkPath}:/etc/hyperledger/fabric-ca-client-config"

# Build Docker command
$dockerArgs = @(
    "run", "--rm",
    "--network", $NetworkName,
    "-v", "${volumeMount}"
)

if ($ClientHome) {
    $dockerClientHome = $ClientHome.Replace($networkPath, "/etc/hyperledger/fabric-ca-client-config").Replace("\", "/")
    $dockerArgs += "-e", "FABRIC_CA_CLIENT_HOME=$dockerClientHome"
}

$dockerArgs += "hyperledger/fabric-tools:2.5.3"
$dockerArgs += "fabric-ca-client"
$dockerArgs += $Arguments

# Run the command
& docker $dockerArgs

exit $LASTEXITCODE
