# Hyperledger Fabric Environment Setup Script for Windows
# This script sets up the development environment for the Land Registry System

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Land Registry System - Environment Setup" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check if running as Administrator (recommended but not required)
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "Warning: Not running as Administrator. Some operations may require elevated privileges." -ForegroundColor Yellow
    Write-Host ""
}

# Step 1: Verify Prerequisites
Write-Host "[1/5] Verifying prerequisites..." -ForegroundColor Green

$prerequisites = @{
    "Docker" = "docker"
    "Docker Compose" = "docker-compose"
    "Node.js" = "node"
    "npm" = "npm"
    "Go" = "go"
    "Git" = "git"
}

$missing = @()
foreach ($tool in $prerequisites.Keys) {
    $command = $prerequisites[$tool]
    try {
        $version = & $command --version 2>&1
        if ($LASTEXITCODE -eq 0 -or $version) {
            Write-Host "  [OK] $tool is installed" -ForegroundColor Green
        } else {
            $missing += $tool
        }
    } catch {
        $missing += $tool
    }
}

if ($missing.Count -gt 0) {
    Write-Host ""
    Write-Host "Missing prerequisites: $($missing -join ', ')" -ForegroundColor Red
    Write-Host "Please install the missing tools and run this script again." -ForegroundColor Red
    Write-Host "Refer to README.md for installation instructions." -ForegroundColor Yellow
    exit 1
}

Write-Host "All prerequisites are installed!" -ForegroundColor Green
Write-Host ""

# Step 2: Check Docker is running
Write-Host "[2/5] Checking Docker status..." -ForegroundColor Green
try {
    docker info | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  [OK] Docker is running" -ForegroundColor Green
    } else {
        Write-Host "  [FAIL] Docker is not running. Please start Docker Desktop and try again." -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "  [FAIL] Docker is not running. Please start Docker Desktop and try again." -ForegroundColor Red
    exit 1
}
Write-Host ""

# Step 3: Set Fabric version
$FABRIC_VERSION = "2.5.3"
$CA_VERSION = "1.5.3"
Write-Host "[3/5] Setting up Hyperledger Fabric $FABRIC_VERSION..." -ForegroundColor Green

# Create directories
$directories = @(
    "network",
    "network/organizations",
    "network/organizations/ordererOrganizations",
    "network/organizations/peerOrganizations",
    "network/configtx",
    "chaincode",
    "chaincode/landregistry",
    "backend",
    "frontend",
    "scripts",
    "docs",
    "tests",
    "tests/e2e"
)

foreach ($dir in $directories) {
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
        Write-Host "  [OK] Created directory: $dir" -ForegroundColor Gray
    }
}

Write-Host ""

# Step 4: Download Fabric binaries (if not already present)
Write-Host "[4/5] Downloading Hyperledger Fabric binaries..." -ForegroundColor Green

$fabricBinPath = "bin"
if (-not (Test-Path $fabricBinPath)) {
    Write-Host "  Downloading Fabric binaries (this may take a few minutes)..." -ForegroundColor Yellow
    
    # Create temporary directory for download
    $tempDir = "temp_fabric_download"
    if (-not (Test-Path $tempDir)) {
        New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
    }
    
    # Download Fabric install script
    $installScriptUrl = "https://raw.githubusercontent.com/hyperledger/fabric/main/scripts/install-fabric.sh"
    $installScriptPath = Join-Path $tempDir "install-fabric.sh"
    
    try {
        Write-Host "  Fetching install script..." -ForegroundColor Gray
        Invoke-WebRequest -Uri $installScriptUrl -OutFile $installScriptPath -UseBasicParsing
        
        # Note: The install script is for Linux/Mac, so we'll use an alternative approach
        # Download binaries directly or use Docker approach
        
        Write-Host "  Note: Fabric binaries are typically used on Linux/Mac." -ForegroundColor Yellow
        Write-Host "  For Windows, we will use Docker containers which include the binaries." -ForegroundColor Yellow
        Write-Host "  Binaries will be available inside Docker containers." -ForegroundColor Yellow
        
        # Clean up temp directory
        Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue
        
    } catch {
        Write-Host "  Warning: Could not download install script. Using Docker-only approach." -ForegroundColor Yellow
        Write-Host "  This is fine - Fabric binaries will be available in Docker containers." -ForegroundColor Yellow
    }
} else {
    Write-Host "  [OK] Fabric binaries directory already exists" -ForegroundColor Green
}

Write-Host ""

# Step 5: Pull Docker images
Write-Host "[5/5] Pulling Hyperledger Fabric Docker images..." -ForegroundColor Green
Write-Host "  This may take 10-15 minutes depending on your internet connection..." -ForegroundColor Yellow
Write-Host ""

$images = @(
    "hyperledger/fabric-peer:$FABRIC_VERSION",
    "hyperledger/fabric-orderer:$FABRIC_VERSION",
    "hyperledger/fabric-ca:$CA_VERSION",
    "hyperledger/fabric-tools:$FABRIC_VERSION",
    "hyperledger/fabric-ccenv:$FABRIC_VERSION",
    "hyperledger/fabric-baseos:2.5"
)

$pulled = 0
$failed = 0

foreach ($image in $images) {
    Write-Host "  Pulling $image..." -ForegroundColor Gray
    try {
        docker pull $image 2>&1 | Out-Null
        if ($LASTEXITCODE -eq 0) {
            Write-Host "    [OK] Successfully pulled $image" -ForegroundColor Green
            $pulled++
        } else {
            Write-Host "    [FAIL] Failed to pull $image" -ForegroundColor Red
            $failed++
        }
    } catch {
        Write-Host "    [FAIL] Error pulling $image : $_" -ForegroundColor Red
        $failed++
    }
}

Write-Host ""
if ($failed -eq 0) {
    Write-Host "All Docker images pulled successfully!" -ForegroundColor Green
} else {
    Write-Host "Warning: Some images failed to pull. You may need to retry." -ForegroundColor Yellow
    Write-Host "You can manually pull images using: docker pull [image-name]" -ForegroundColor Yellow
}

Write-Host ""

# Summary
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Setup Complete!" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Verify installation: .\scripts\verify-prerequisites.ps1" -ForegroundColor White
Write-Host "2. Proceed to Phase 2: Fabric Network Configuration" -ForegroundColor White
Write-Host ""
Write-Host 'For more information, see README.md' -ForegroundColor Gray
