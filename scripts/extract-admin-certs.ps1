# Extract Admin Certificates from Wallet
# Copies admin certs to MSP folders for network setup

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Extracting Admin Certificates" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check if admin exists in wallet
Write-Host "[1/3] Checking wallet..." -ForegroundColor Green
$walletPath = "backend/wallet"

if (-not (Test-Path $walletPath)) {
    Write-Host "  [FAIL] Wallet directory not found" -ForegroundColor Red
    Write-Host "  Please enroll admin first: cd backend; npm run enroll-admin" -ForegroundColor Yellow
    exit 1
}

$adminFiles = Get-ChildItem $walletPath -Recurse -File | Where-Object { $_.Name -like "*admin*" }
if (-not $adminFiles) {
    Write-Host "  [FAIL] Admin identity not found in wallet" -ForegroundColor Red
    Write-Host "  Please enroll admin first: cd backend; npm run enroll-admin" -ForegroundColor Yellow
    exit 1
}

Write-Host "  [OK] Admin identity found" -ForegroundColor Green
Write-Host ""

# The wallet stores identities in a specific format
# We need to read the identity and extract the certificate
Write-Host "[2/3] Reading admin identity..." -ForegroundColor Green
Write-Host "  [INFO] Wallet format: FileSystemWallet stores identities as JSON" -ForegroundColor Gray
Write-Host "  [INFO] Need to extract certificate from identity file" -ForegroundColor Gray
Write-Host ""

# For now, create a script that uses Node.js to extract the cert
Write-Host "[3/3] Creating extraction script..." -ForegroundColor Green

$extractScript = @"
const fs = require('fs');
const path = require('path');

// Read admin identity from wallet
const walletPath = path.join(__dirname, '../backend/wallet');
const adminFile = path.join(walletPath, 'admin');

if (!fs.existsSync(adminFile)) {
    console.error('Admin identity not found');
    process.exit(1);
}

const identity = JSON.parse(fs.readFileSync(adminFile, 'utf8'));
const cert = identity.credentials.certificate;
const key = identity.credentials.privateKey;

// Create MSP directories
const adminMsp = path.join(__dirname, '../network/organizations/peerOrganizations/landreg.example.com/users/Admin@landreg.example.com/msp');
const peerMsp = path.join(__dirname, '../network/organizations/peerOrganizations/landreg.example.com/peers/peer0.landreg.example.com/msp');

// Ensure directories exist
['signcerts', 'keystore', 'cacerts', 'admincerts'].forEach(dir => {
    fs.mkdirSync(path.join(adminMsp, dir), { recursive: true });
    fs.mkdirSync(path.join(peerMsp, dir), { recursive: true });
});

// Write certificate to signcerts
fs.writeFileSync(path.join(adminMsp, 'signcerts/cert.pem'), cert);
fs.writeFileSync(path.join(peerMsp, 'signcerts/cert.pem'), cert);

// Write private key to keystore
const keyFileName = path.join(adminMsp, 'keystore/key.pem');
fs.writeFileSync(keyFileName, key);
fs.copyFileSync(keyFileName, path.join(peerMsp, 'keystore/key.pem'));

// Copy cert to admincerts
fs.copyFileSync(path.join(adminMsp, 'signcerts/cert.pem'), path.join(adminMsp, 'admincerts/cert.pem'));
fs.copyFileSync(path.join(adminMsp, 'signcerts/cert.pem'), path.join(peerMsp, 'admincerts/cert.pem'));

console.log('Admin certificates extracted successfully');
"@

Set-Content -Path "scripts/extract-admin-certs.js" -Value $extractScript

Write-Host "  [OK] Extraction script created" -ForegroundColor Gray
Write-Host ""
Write-Host "Run: node scripts/extract-admin-certs.js" -ForegroundColor Yellow
Write-Host ""
