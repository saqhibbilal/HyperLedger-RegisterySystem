# Start Orderer and Peers
# Use when CAs are up but orderer/peers are not. Run from project root.

$root = Split-Path -Parent $PSScriptRoot
$networkDir = Join-Path $root "network"
Write-Host "Starting orderer and peers..." -ForegroundColor Cyan
Push-Location $networkDir
try {
    docker-compose up -d orderer.example.com peer0.landreg.example.com peer0.court.example.com
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Done. If peers exit, check: docker-compose logs peer0.landreg.example.com" -ForegroundColor Gray
    } else {
        Write-Host "Start failed. Run: docker ps -a" -ForegroundColor Yellow
        exit 1
    }
} finally {
    Pop-Location
}
