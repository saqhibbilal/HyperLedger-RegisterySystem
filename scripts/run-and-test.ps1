# Run full deploy and test
# Run from project root. Requires Docker.
# Optional: -CleanSlate   remove old channel block and genesis (use if you had 3-org before)

param([switch]$CleanSlate)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Run and Test - Full Deploy" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

if ($CleanSlate) {
    Write-Host "[0] Clean slate (removing old channel and genesis)..." -ForegroundColor Yellow
    Remove-Item -Force "network\channel-artifacts\landregistrychannel.block" -ErrorAction SilentlyContinue
    if (Test-Path "network\system-genesis-block\genesis.block") { Remove-Item -Recurse -Force "network\system-genesis-block\genesis.block" }
    Write-Host "  [OK]" -ForegroundColor Green
    Write-Host ""
}

# 1. CAs and network up
Write-Host "[1/6] Starting CAs and network..." -ForegroundColor Green
Push-Location network
docker-compose up -d
if ($LASTEXITCODE -ne 0) { Pop-Location; exit 1 }
Pop-Location
Write-Host "  [OK]" -ForegroundColor Green
Write-Host ""

# 2. Enroll crypto (idempotent; may warn for Court/SubRegistrar)
Write-Host "[2/6] Enrolling crypto..." -ForegroundColor Green
.\scripts\enroll-crypto.ps1
if ($LASTEXITCODE -ne 0) { exit 1 }
Write-Host ""

# 3. Generate genesis block
Write-Host "[3/6] Generating genesis block..." -ForegroundColor Green
.\scripts\generate-genesis-block.ps1
if ($LASTEXITCODE -ne 0) { exit 1 }
Write-Host ""

# 4. Restart so orderer uses new genesis
Write-Host "[4/6] Restarting network (orderer + peers)..." -ForegroundColor Green
Push-Location network
docker-compose down 2>$null
docker-compose up -d
if ($LASTEXITCODE -ne 0) { Pop-Location; exit 1 }
Pop-Location
# wait for orderer/peers to be ready
Start-Sleep -Seconds 5
Write-Host "  [OK]" -ForegroundColor Green
Write-Host ""

# 5. Create channel
Write-Host "[5/6] Creating channel..." -ForegroundColor Green
.\scripts\create-channel-full.ps1
if ($LASTEXITCODE -ne 0) { exit 1 }
Write-Host ""

# 6. Deploy chaincode
Write-Host "[6/6] Deploying chaincode..." -ForegroundColor Green
.\scripts\deploy-chaincode.ps1
if ($LASTEXITCODE -ne 0) { exit 1 }
Write-Host ""

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Deploy complete. Start app:" -ForegroundColor Cyan
Write-Host "  Backend:  cd backend; npm start" -ForegroundColor Gray
Write-Host "  Frontend: cd frontend; npm run dev" -ForegroundColor Gray
Write-Host "  Then open http://localhost:3001" -ForegroundColor Gray
Write-Host "========================================" -ForegroundColor Cyan
