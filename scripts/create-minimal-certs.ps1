# Create Minimal Certificates for Learning Project
# Creates placeholder certificates to allow network to start

Write-Host "Creating minimal certificates for learning..." -ForegroundColor Cyan
Write-Host ""

# Create a simple self-signed certificate placeholder
$placeholderCert = @"
-----BEGIN CERTIFICATE-----
MIICATCCAWegAwIBAgIQCj8k8vqJ8qJ8qJ8qJ8qJ8qJAKBggqhkjOPQQDAjBZ
MQswCQYDVQQGEwJVUzETMBEGA1UECBMKQ2FsaWZvcm5pYTEWMBQGA1UEBxMN
U2FuIEZyYW5jaXNjbzETMBEGA1UEChMKTXlPcmcgSW5jLjEZMBcGA1UEAxMQ
TXlPcmcgSW5jLiBSb290IENBMCAXDTIwMDEwMTAwMDAwMFoYDzIwNTAwMTAx
MDAwMDAwWjBZMQswCQYDVQQGEwJVUzETMBEGA1UECBMKQ2FsaWZvcm5pYTEW
MBQGA1UEBxMNU2FuIEZyYW5jaXNjbzETMBEGA1UEChMKTXlPcmcgSW5jLjEZ
MBcGA1UEAxMQTXlPcmcgSW5jLiBSb290IENBMFkwEwYHKoZIzj0CAQYIKoZI
zj0DAQcDQgAE8k8vqJ8qJ8qJ8qJ8qJ8qJ8qJ8qJ8qJ8qJ8qJ8qJ8qJ8qJ8q
J8qJ8qJ8qJ8qJ8qJ8qJ8qJ8qJ8qJ8qJ8qJ8qJ8qJ8qJ8qJ8qJ8qJ8qJ8qJ8
-----END CERTIFICATE-----
"@

$orgs = @("landreg", "subregistrar", "court")
foreach ($org in $orgs) {
    $caPath = "network/organizations/peerOrganizations/$org.example.com/ca"
    New-Item -ItemType Directory -Force -Path $caPath | Out-Null
    Set-Content -Path "$caPath/ca-cert.pem" -Value $placeholderCert
    
    # Copy to MSP
    $mspPath = "network/organizations/peerOrganizations/$org.example.com/msp"
    New-Item -ItemType Directory -Force -Path "$mspPath/cacerts" | Out-Null
    Copy-Item "$caPath/ca-cert.pem" "$mspPath/cacerts/ca.crt" -Force
}

# Orderer
$ordererCaPath = "network/organizations/ordererOrganizations/example.com/ca"
New-Item -ItemType Directory -Force -Path $ordererCaPath | Out-Null
Set-Content -Path "$ordererCaPath/ca-cert.pem" -Value $placeholderCert

$ordererMsp = "network/organizations/ordererOrganizations/example.com/msp"
New-Item -ItemType Directory -Force -Path "$ordererMsp/cacerts" | Out-Null
Copy-Item "$ordererCaPath/ca-cert.pem" "$ordererMsp/cacerts/ca.crt" -Force

Write-Host "[OK] Minimal certificates created" -ForegroundColor Green
Write-Host ""
Write-Host "Note: These are placeholder certificates for learning." -ForegroundColor Yellow
Write-Host "      For production, use proper CA-generated certificates." -ForegroundColor Yellow
Write-Host ""
Write-Host "Next: .\scripts\generate-genesis-block.ps1" -ForegroundColor Cyan
Write-Host ""
