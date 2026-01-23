# Test-Network Adaptation - Implementation Summary

## Overview

We have successfully adapted Hyperledger Fabric's proven test-network crypto generation approach to our 3-org network. This implementation follows the exact methodology used by Fabric's official test-network, ensuring reliability and compatibility.

## What Was Changed

### 1. Docker Compose Volume Mounts ✅

**File:** `network/docker-compose.yml`

Updated all CA volume mounts to use the `fabric-ca/` directory structure:

- **Before:** `./organizations/peerOrganizations/landreg.example.com/ca/`
- **After:** `./organizations/fabric-ca/landreg/`

This matches test-network's structure where CAs write `tls-cert.pem` directly to their mounted volume.

### 2. New Scripts Created ✅

#### `scripts/generate-crypto-test-network.ps1`
- Starts CA containers
- Waits for `tls-cert.pem` to be created by each CA
- Uses `fabric-ca-client getcainfo` to retrieve CA certificates
- Creates `ca-cert.pem` for each organization

#### `scripts/enroll-orgs.ps1`
- Enrolls all 4 organizations (LandReg, SubRegistrar, Court, Orderer)
- Creates MSP config.yaml with NodeOUs
- Registers identities (peer0, admin, user1)
- Enrolls peers/orderer with MSP and TLS certificates
- Copies TLS certs to well-known names (`server.crt`, `server.key`, `ca.crt`)

#### `scripts/create-connection-profiles.ps1`
- Generates JSON connection profiles for backend
- Uses template-based approach (like test-network)
- Creates profiles for all 3 peer organizations

#### `network/organizations/ccp-template.json`
- Connection profile template
- Variables: `${ORG}`, `${ORG_DOMAIN}`, `${P0PORT}`, `${CAPORT}`, etc.

### 3. Updated Scripts ✅

#### `scripts/deploy-network.ps1`
- Updated to use new test-network approach
- Orchestrates: CA setup → Enrollment → Connection profiles → Genesis → Channel → Chaincode

### 4. Directory Structure

The new structure matches test-network:

```
network/organizations/
├── fabric-ca/              # NEW: CA data (certificates, databases)
│   ├── ordererOrg/
│   ├── landreg/
│   ├── subregistrar/
│   └── court/
├── peerOrganizations/      # Existing: Peer org certificates
│   ├── landreg.example.com/
│   ├── subregistrar.example.com/
│   └── court.example.com/
└── ordererOrganizations/   # Existing: Orderer certificates
    └── example.com/
```

## How to Use

### Option 1: Complete Deployment (Recommended)

Run the master deployment script:

```powershell
.\scripts\deploy-network.ps1
```

This will:
1. Start network (CAs, orderer, peers)
2. Generate crypto materials (test-network approach)
3. Enroll all organizations
4. Generate connection profiles
5. Generate genesis block
6. Create channel
7. Deploy chaincode

### Option 2: Step-by-Step

#### Step 1: Start CAs and Get Certificates

```powershell
.\scripts\generate-crypto-test-network.ps1
```

This will:
- Start CA containers
- Wait for `tls-cert.pem` files
- Retrieve CA certificates using `getcainfo`

#### Step 2: Enroll Organizations

```powershell
.\scripts\enroll-orgs.ps1
```

This will enroll:
- LandReg organization
- SubRegistrar organization
- Court organization
- Orderer organization

#### Step 3: Generate Connection Profiles

```powershell
.\scripts\create-connection-profiles.ps1
```

This creates:
- `connection-landreg.json`
- `connection-subregistrar.json`
- `connection-court.json`

#### Step 4: Generate Genesis Block

```powershell
.\scripts\generate-genesis-block.ps1
```

#### Step 5: Create Channel

```powershell
.\scripts\create-channel-full.ps1
```

#### Step 6: Deploy Chaincode

```powershell
.\scripts\deploy-chaincode.ps1
```

## Key Differences from Previous Approach

### What Changed:

1. **CA Volume Mounts** - Now use `fabric-ca/` structure
2. **Certificate Retrieval** - Use `getcainfo` instead of copying from containers
3. **Wait Logic** - Wait for `tls-cert.pem` (CA creates automatically)
4. **TLS Enrollment** - Proper `--csr.hosts` flags for peer/orderer TLS
5. **Certificate Copying** - Copy to well-known names (`server.crt`, etc.)

### What Stayed the Same:

- ✅ `configtx.yaml` - No changes needed
- ✅ Chaincode - No changes needed
- ✅ Backend code - No changes needed
- ✅ Frontend code - No changes needed
- ✅ Peer/Orderer volume mounts - Still point to `peerOrganizations/` and `ordererOrganizations/`

## Verification

After running the scripts, verify:

1. **CA Certificates:**
   ```powershell
   Test-Path network/organizations/fabric-ca/landreg/ca-cert.pem
   Test-Path network/organizations/fabric-ca/subregistrar/ca-cert.pem
   Test-Path network/organizations/fabric-ca/court/ca-cert.pem
   Test-Path network/organizations/fabric-ca/ordererOrg/ca-cert.pem
   ```

2. **Peer Certificates:**
   ```powershell
   Test-Path network/organizations/peerOrganizations/landreg.example.com/peers/peer0.landreg.example.com/tls/server.crt
   Test-Path network/organizations/peerOrganizations/landreg.example.com/peers/peer0.landreg.example.com/tls/server.key
   Test-Path network/organizations/peerOrganizations/landreg.example.com/peers/peer0.landreg.example.com/tls/ca.crt
   ```

3. **Connection Profiles:**
   ```powershell
   Test-Path network/organizations/peerOrganizations/landreg.example.com/connection-landreg.json
   ```

4. **Network Status:**
   ```powershell
   docker ps
   ```
   Should show all CA, orderer, and peer containers running.

## Troubleshooting

### Issue: CA containers exit immediately

**Solution:** Check if `fabric-ca/` directories exist and are writable:
```powershell
New-Item -ItemType Directory -Path network/organizations/fabric-ca/landreg -Force
```

### Issue: `tls-cert.pem` not appearing

**Solution:** 
1. Check CA container logs: `docker logs ca-landreg`
2. Verify volume mount in docker-compose.yml
3. Wait longer (CAs may take 10-30 seconds to initialize)

### Issue: `getcainfo` fails

**Solution:**
1. Ensure `tls-cert.pem` exists first
2. Wait for CA to be fully ready (check logs)
3. Verify CA is accessible: `docker ps | Select-String ca-`

### Issue: Enrollment fails

**Solution:**
1. Verify `ca-cert.pem` exists
2. Check CA container is running
3. Verify CA port is correct (8054, 9054, 10054, 7054)
4. Check CA logs for errors

## Next Steps

After successful crypto generation:

1. **Start Backend:**
   ```powershell
   cd backend
   npm run enroll-admin
   npm start
   ```

2. **Start Frontend:**
   ```powershell
   cd frontend
   npm run dev
   ```

3. **Test End-to-End:**
   - Create a land record via frontend
   - Query land records
   - Transfer land ownership

## References

- **Test-Network Source:** `fabric-test/fabric-samples/test-network/` (reference only, not modified)
- **Analysis Document:** `ANALYSIS_TEST_NETWORK.md`
- **Original Test-Network Scripts:**
  - `network.sh` - Main orchestration
  - `organizations/fabric-ca/registerEnroll.sh` - Enrollment logic
  - `organizations/ccp-generate.sh` - Connection profile generation

---

**Implementation Date:** January 2026  
**Approach:** Option A - Match Test-Network Structure  
**Status:** ✅ Complete and Ready for Testing
