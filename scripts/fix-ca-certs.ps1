# Fix CA Certificates - Copy from containers
# For learning project - simple workaround

Write-Host "Copying CA certificates from containers..." -ForegroundColor Cyan

$orgs = @(
    @{Container="ca-landreg"; Path="network/organizations/peerOrganizations/landreg.example.com/ca"},
    @{Container="ca-subregistrar"; Path="network/organizations/peerOrganizations/subregistrar.example.com/ca"},
    @{Container="ca-court"; Path="network/organizations/peerOrganizations/court.example.com/ca"},
    @{Container="ca-orderer"; Path="network/organizations/ordererOrganizations/example.com/ca"}
)

foreach ($org in $orgs) {
    Write-Host "  Copying from $($org.Container)..." -ForegroundColor Gray
    
    # Create directory
    New-Item -ItemType Directory -Force -Path $org.Path | Out-Null
    
    # Try to copy ca-cert.pem
    docker cp "$($org.Container):/etc/hyperledger/fabric-ca-server-config/ca-cert.pem" "$($org.Path)/ca-cert.pem" 2>&1 | Out-Null
    
    if (Test-Path "$($org.Path)/ca-cert.pem") {
        Write-Host "    [OK] Certificate copied" -ForegroundColor Green
    } else {
        Write-Host "    [WARN] Certificate not found in container" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "Done! Now try: .\scripts\generate-genesis-block.ps1" -ForegroundColor Cyan
Write-Host ""
