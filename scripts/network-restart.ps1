# Network Restart Script
# Stops and restarts the network

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Restarting Land Registry Network" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Stop network
Write-Host "Stopping network..." -ForegroundColor Yellow
& .\scripts\network-stop.ps1

Write-Host ""
Start-Sleep -Seconds 3

# Start network
Write-Host "Starting network..." -ForegroundColor Yellow
& .\scripts\network-start.ps1

Write-Host ""
Write-Host "Network restarted successfully!" -ForegroundColor Green
Write-Host ""
