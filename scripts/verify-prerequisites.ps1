# Prerequisites Verification Script
# Checks if all required tools are installed and properly configured

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Verifying Prerequisites" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$allPassed = $true
$results = New-Object System.Collections.ArrayList

# Function to check a tool
function Test-Tool {
    param(
        [string]$ToolName,
        [string]$Command,
        [string]$VersionFlag = "--version",
        [string]$RequiredVersion = "",
        [string]$InstallUrl = ""
    )
    
    Write-Host "Checking $ToolName..." -ForegroundColor Yellow
    
    $result = @{
        Name = $ToolName
        Installed = $false
        Version = "N/A"
        Status = "FAIL"
    }
    
    try {
        $output = & $Command $VersionFlag 2>&1
        $exitCode = $LASTEXITCODE
        
        if ($exitCode -eq 0 -or $output) {
            $version = ($output | Select-Object -First 1).ToString().Trim()
            Write-Host "  [OK] $ToolName is installed" -ForegroundColor Green
            Write-Host "    Version: $version" -ForegroundColor Gray
            
            if ($RequiredVersion -and $version -notmatch $RequiredVersion) {
                Write-Host "    Warning: Version may not meet requirements (recommended: $RequiredVersion)" -ForegroundColor Yellow
            }
            
            $result.Installed = $true
            $result.Version = $version
            $result.Status = "PASS"
        } else {
            Write-Host "  [FAIL] $ToolName is NOT installed" -ForegroundColor Red
            if ($InstallUrl) {
                Write-Host "    Install from: $InstallUrl" -ForegroundColor Yellow
            }
        }
    } catch {
        Write-Host "  [FAIL] $ToolName is NOT installed or not in PATH" -ForegroundColor Red
        if ($InstallUrl) {
            Write-Host "    Install from: $InstallUrl" -ForegroundColor Yellow
        }
    }
    
    return $result
}

# Check Docker
$result = Test-Tool -ToolName "Docker" -Command "docker" -InstallUrl "https://www.docker.com/products/docker-desktop/"
[void]$results.Add($result)
if (-not $result.Installed) { 
    $allPassed = $false 
}

# Check Docker Compose
$result = Test-Tool -ToolName "Docker Compose" -Command "docker-compose" -InstallUrl "https://www.docker.com/products/docker-desktop/"
[void]$results.Add($result)
if (-not $result.Installed) { 
    $allPassed = $false 
}

# Check if Docker is running
Write-Host ""
Write-Host "Checking Docker daemon..." -ForegroundColor Yellow
try {
    docker info | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  [OK] Docker daemon is running" -ForegroundColor Green
    } else {
        Write-Host "  [FAIL] Docker daemon is NOT running" -ForegroundColor Red
        Write-Host "    Please start Docker Desktop" -ForegroundColor Yellow
        $allPassed = $false
    }
} catch {
    Write-Host "  [FAIL] Docker daemon is NOT running" -ForegroundColor Red
    Write-Host "    Please start Docker Desktop" -ForegroundColor Yellow
    $allPassed = $false
}

Write-Host ""

# Check Node.js
$result = Test-Tool -ToolName "Node.js" -Command "node" -RequiredVersion "v18" -InstallUrl "https://nodejs.org/"
[void]$results.Add($result)
if (-not $result.Installed) { 
    $allPassed = $false 
}

# Check npm
$result = Test-Tool -ToolName "npm" -Command "npm" -InstallUrl "https://nodejs.org/ (comes with Node.js)"
[void]$results.Add($result)
if (-not $result.Installed) { 
    $allPassed = $false 
}

Write-Host ""

# Check Go
$result = Test-Tool -ToolName "Go" -Command "go" -VersionFlag "version" -RequiredVersion "go1.20" -InstallUrl "https://go.dev/dl/"
[void]$results.Add($result)
if (-not $result.Installed) { 
    $allPassed = $false 
}

# Check Go environment
if ($result.Installed) {
    Write-Host "Checking Go environment..." -ForegroundColor Yellow
    try {
        $goEnv = go env GOPATH
        $goRoot = go env GOROOT
        Write-Host "  [OK] GOPATH: $goEnv" -ForegroundColor Gray
        Write-Host "  [OK] GOROOT: $goRoot" -ForegroundColor Gray
    } catch {
        Write-Host "  Warning: Could not read Go environment" -ForegroundColor Yellow
    }
}

Write-Host ""

# Check Git
$result = Test-Tool -ToolName "Git" -Command "git" -InstallUrl "https://git-scm.com/download/win"
[void]$results.Add($result)
if (-not $result.Installed) { 
    $allPassed = $false 
}

Write-Host ""

# Check PowerShell version
Write-Host "Checking PowerShell..." -ForegroundColor Yellow
$psVersion = $PSVersionTable.PSVersion
Write-Host "  [OK] PowerShell version: $psVersion" -ForegroundColor Green
if ($psVersion.Major -lt 5) {
    Write-Host "  Warning: PowerShell 5.1+ recommended" -ForegroundColor Yellow
}

Write-Host ""

# Summary
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Verification Summary" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$passedCount = 0
$failedCount = 0

foreach ($r in $results) {
    if ($r.Status -eq "PASS") {
        $passedCount++
    } else {
        $failedCount++
    }
}

Write-Host "Passed: $passedCount" -ForegroundColor Green
if ($failedCount -eq 0) {
    Write-Host "Failed: $failedCount" -ForegroundColor Green
} else {
    Write-Host "Failed: $failedCount" -ForegroundColor Red
}
Write-Host ""

if ($allPassed) {
    Write-Host "[SUCCESS] All prerequisites are installed and ready!" -ForegroundColor Green
    Write-Host ""
    Write-Host "You can proceed with:" -ForegroundColor Yellow
    Write-Host "  .\scripts\setup-env.ps1" -ForegroundColor White
    exit 0
} else {
    Write-Host "[FAILURE] Some prerequisites are missing." -ForegroundColor Red
    Write-Host ""
    Write-Host "Please install the missing tools and run this script again." -ForegroundColor Yellow
    Write-Host "Refer to README.md for detailed installation instructions." -ForegroundColor Yellow
    exit 1
}
