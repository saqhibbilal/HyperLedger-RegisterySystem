# Network Stop Script for Land Registry System
# Stops the Hyperledger Fabric network

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Stopping Land Registry Network" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check if network directory exists
if (-not (Test-Path "network/docker-compose.yml")) {
    Write-Host "[FAIL] Network configuration not found. Please run from project root." -ForegroundColor Red
    exit 1
}

# Stop the network
Write-Host "Stopping Fabric network..." -ForegroundColor Green
Push-Location network
try {
    docker-compose down -v
    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-Host "[OK] Network stopped successfully!" -ForegroundColor Green
        Write-Host ""
        Write-Host "All containers and volumes have been removed." -ForegroundColor Gray
    } else {
        Write-Host "[FAIL] Failed to stop network" -ForegroundColor Red
        Pop-Location
        exit 1
    }
} catch {
    Write-Host "[FAIL] Error stopping network: $_" -ForegroundColor Red
    Pop-Location
    exit 1
}
Pop-Location

Write-Host ""
