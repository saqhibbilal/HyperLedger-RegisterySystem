# Network Start Script for Land Registry System
# Starts the Hyperledger Fabric network

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Starting Land Registry Network" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check if Docker is running
Write-Host "[1/4] Checking Docker..." -ForegroundColor Green
try {
    docker info | Out-Null
    if ($LASTEXITCODE -ne 0) {
        Write-Host "  [FAIL] Docker is not running. Please start Docker Desktop." -ForegroundColor Red
        exit 1
    }
    Write-Host "  [OK] Docker is running" -ForegroundColor Green
} catch {
    Write-Host "  [FAIL] Docker is not running. Please start Docker Desktop." -ForegroundColor Red
    exit 1
}

Write-Host ""

# Check if network directory exists
Write-Host "[2/4] Checking network configuration..." -ForegroundColor Green
if (-not (Test-Path "network/docker-compose.yml")) {
    Write-Host "  [FAIL] Network configuration not found. Please run from project root." -ForegroundColor Red
    exit 1
}
Write-Host "  [OK] Network configuration found" -ForegroundColor Green

Write-Host ""

# Stop any existing network
Write-Host "[3/4] Stopping any existing network..." -ForegroundColor Green
Push-Location network
try {
    docker-compose down -v 2>&1 | Out-Null
    Write-Host "  [OK] Cleaned up existing containers" -ForegroundColor Gray
} catch {
    Write-Host "  [INFO] No existing containers to clean up" -ForegroundColor Gray
}
Pop-Location

Write-Host ""

# Start the network
Write-Host "[4/4] Starting Fabric network..." -ForegroundColor Green
Write-Host "  This may take a few minutes..." -ForegroundColor Yellow
Write-Host ""

Push-Location network
try {
    docker-compose up -d
    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-Host "  [OK] Network started successfully!" -ForegroundColor Green
        Write-Host ""
        Write-Host "Waiting for services to be ready..." -ForegroundColor Yellow
        Start-Sleep -Seconds 10
        
        Write-Host ""
        Write-Host "Network Status:" -ForegroundColor Cyan
        docker-compose ps
        
        Write-Host ""
        Write-Host "Next steps:" -ForegroundColor Yellow
        Write-Host "1. Generate crypto materials: .\scripts\generate-crypto.ps1" -ForegroundColor White
        Write-Host "2. Create channel: .\scripts\create-channel.ps1" -ForegroundColor White
    } else {
        Write-Host "  [FAIL] Failed to start network" -ForegroundColor Red
        Pop-Location
        exit 1
    }
} catch {
    Write-Host "  [FAIL] Error starting network: $_" -ForegroundColor Red
    Pop-Location
    exit 1
}
Pop-Location

Write-Host ""
