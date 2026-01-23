# Deep Analysis: Fabric Test-Network Crypto Generation Approach

## Executive Summary

After analyzing Fabric's test-network implementation, I've identified the **exact methodology** they use for crypto generation. This document maps their proven approach to our 3-org network structure.

---

## Key Discoveries

### 1. **CA Certificate Generation Flow**

**How test-network does it:**
1. **Start CA containers** with volumes mounted to `organizations/fabric-ca/{org}/`
2. **Wait for CA to write `tls-cert.pem`** to the mounted volume (CA creates this automatically)
3. **Use `fabric-ca-client getcainfo`** to retrieve the CA certificate and save as `ca-cert.pem`
4. **Use `ca-cert.pem`** for all subsequent enrollment operations

**Critical insight:** The CA container **automatically writes** `tls-cert.pem` to the mounted volume when it starts. We don't need to copy it from the container - it's already there!

### 2. **Certificate Directory Structure**

Test-network creates certificates in this structure:
```
organizations/
├── fabric-ca/
│   ├── org1/
│   │   ├── tls-cert.pem          # Created by CA container automatically
│   │   ├── ca-cert.pem           # Retrieved via getcainfo
│   │   └── fabric-ca-server.db   # CA database
│   ├── org2/ (same structure)
│   └── ordererOrg/ (same structure)
│
├── peerOrganizations/
│   ├── org1.example.com/
│   │   ├── msp/
│   │   │   ├── config.yaml       # NodeOUs configuration
│   │   │   ├── cacerts/          # CA certs
│   │   │   └── tlscacerts/       # TLS CA certs
│   │   ├── ca/                   # CA cert for clients
│   │   ├── tlsca/                # TLS CA cert for clients
│   │   ├── peers/
│   │   │   └── peer0.org1.example.com/
│   │   │       ├── msp/          # Peer MSP
│   │   │       └── tls/          # Peer TLS certs (server.crt, server.key, ca.crt)
│   │   └── users/
│   │       ├── Admin@org1.example.com/msp/
│   │       └── User1@org1.example.com/msp/
│   └── org2.example.com/ (same structure)
│
└── ordererOrganizations/
    └── example.com/
        ├── msp/
        ├── orderers/
        │   └── orderer.example.com/
        │       ├── msp/
        │       └── tls/          # Orderer TLS certs
        └── users/
            └── Admin@example.com/msp/
```

### 3. **Enrollment Process (Per Organization)**

For each organization, test-network follows this exact sequence:

1. **Enroll CA Admin**
   ```bash
   fabric-ca-client enroll -u https://admin:adminpw@localhost:PORT \
     --caname ca-orgX \
     --tls.certfiles "${PWD}/organizations/fabric-ca/orgX/ca-cert.pem"
   ```

2. **Create MSP config.yaml** (NodeOUs configuration)
   - Defines client, peer, admin, orderer organizational units
   - Points to CA certificate

3. **Copy CA certs** to multiple locations:
   - `msp/tlscacerts/ca.crt`
   - `tlsca/tlsca.orgX.example.com-cert.pem`
   - `ca/ca.orgX.example.com-cert.pem`

4. **Register identities:**
   - `peer0` (type: peer)
   - `user1` (type: client)
   - `orgXadmin` (type: admin)

5. **Enroll peer0:**
   - MSP enrollment: `-M .../peers/peer0.orgX.example.com/msp`
   - TLS enrollment: `-M .../peers/peer0.orgX.example.com/tls --enrollment.profile tls --csr.hosts peer0.orgX.example.com --csr.hosts localhost`

6. **Copy TLS certs** to well-known names:
   - `tls/ca.crt` (from `tlscacerts/`)
   - `tls/server.crt` (from `signcerts/`)
   - `tls/server.key` (from `keystore/`)

7. **Enroll users:**
   - User1 MSP
   - Admin MSP

### 4. **Connection Profile Generation**

Test-network generates connection profiles using:
- Template file: `organizations/ccp-template.json`
- Script: `organizations/ccp-generate.sh`
- Output: `organizations/peerOrganizations/orgX.example.com/connection-orgX.json`

**Template variables:**
- `${ORG}` - Organization number
- `${P0PORT}` - Peer port (7051, 9051, etc.)
- `${CAPORT}` - CA port (7054, 8054, etc.)
- `${PEERPEM}` - TLS CA cert (one-line format)
- `${CAPEM}` - CA cert (one-line format)

---

## Mapping to Our 3-Org Network

### Our Organizations:
1. **LandReg** → `landreg.example.com` (Ports: CA=8054, Peer=7051)
2. **SubRegistrar** → `subregistrar.example.com` (Ports: CA=9054, Peer=8051)
3. **Court** → `court.example.com` (Ports: CA=10054, Peer=9051)
4. **Orderer** → `example.com` (Ports: CA=7054, Orderer=7050)

### Our CA Container Names:
- `ca-orderer` → Port 7054
- `ca-landreg` → Port 8054
- `ca-subregistrar` → Port 9054
- `ca-court` → Port 10054

### Our Volume Mounts (from docker-compose.yml):
```yaml
# Orderer CA
- ./organizations/ordererOrganizations/example.com/ca/:/etc/hyperledger/fabric-ca-server-config

# LandReg CA
- ./organizations/peerOrganizations/landreg.example.com/ca/:/etc/hyperledger/fabric-ca-server-config

# SubRegistrar CA
- ./organizations/peerOrganizations/subregistrar.example.com/ca/:/etc/hyperledger/fabric-ca-server-config

# Court CA
- ./organizations/peerOrganizations/court.example.com/ca/:/etc/hyperledger/fabric-ca-server-config
```

**⚠️ CRITICAL ISSUE FOUND:** Our volume mounts point to `/ca/` but test-network mounts to `/fabric-ca/{org}/`. The CA writes `tls-cert.pem` to its home directory, which is the mounted volume root.

**Solution:** We need to adjust our volume mounts OR create a separate `fabric-ca/` directory structure like test-network does.

---

## Adaptation Strategy

### Option A: Match Test-Network Structure (Recommended)
- Create `network/organizations/fabric-ca/` directory
- Mount CAs to `fabric-ca/{org}/` (like test-network)
- Keep our existing `peerOrganizations/` and `ordererOrganizations/` structure
- Update docker-compose.yml volume mounts

### Option B: Adapt to Our Current Structure
- Keep current volume mounts
- Extract `tls-cert.pem` from CA container's home directory
- Use `getcainfo` to get `ca-cert.pem`
- Continue with enrollment

**Recommendation:** Option A is cleaner and matches proven test-network approach.

---

## Step-by-Step Process (Adapted for Our Network)

### Phase 1: Start CAs and Wait for Certificates

1. **Start CA containers:**
   ```powershell
   docker-compose -f network/docker-compose.yml up -d ca-orderer ca-landreg ca-subregistrar ca-court
   ```

2. **Wait for `tls-cert.pem` to appear** in each CA's mounted volume:
   - `network/organizations/fabric-ca/ordererOrg/tls-cert.pem`
   - `network/organizations/fabric-ca/landreg/tls-cert.pem`
   - `network/organizations/fabric-ca/subregistrar/tls-cert.pem`
   - `network/organizations/fabric-ca/court/tls-cert.pem`

3. **Get CA certificates** using `fabric-ca-client getcainfo`:
   ```powershell
   # For each CA
   fabric-ca-client getcainfo -u https://admin:adminpw@localhost:PORT \
     --caname ca-orgname \
     --tls.certfiles "network/organizations/fabric-ca/orgname/tls-cert.pem"
   ```
   This creates `ca-cert.pem` in the same directory.

### Phase 2: Enroll Organizations

For each organization (LandReg, SubRegistrar, Court, Orderer):

1. **Enroll CA admin**
2. **Create MSP config.yaml** with NodeOUs
3. **Copy CA certs** to required locations
4. **Register identities** (peer0, admin, user1)
5. **Enroll peer0/orderer** (MSP + TLS)
6. **Copy TLS certs** to well-known names
7. **Enroll users** (Admin, User1)

### Phase 3: Generate Connection Profiles

Create connection profiles for each peer organization:
- `connection-landreg.json`
- `connection-subregistrar.json`
- `connection-court.json`

### Phase 4: Generate Genesis Block

Use `configtxgen` with our existing `configtx.yaml` (no changes needed).

---

## Key Differences from Our Previous Attempts

### What We Were Missing:

1. **Waiting for `tls-cert.pem`** - CA creates this automatically, we just need to wait
2. **Using `getcainfo`** - This retrieves the CA cert properly
3. **Proper directory structure** - Test-network uses `fabric-ca/` separate from `peerOrganizations/`
4. **TLS enrollment with `--csr.hosts`** - Critical for peer/orderer TLS certs
5. **Copying TLS certs to well-known names** - `server.crt`, `server.key`, `ca.crt` in `tls/` directory

### What We Got Right:

1. ✅ Using Fabric CA (not cryptogen)
2. ✅ Registering identities before enrolling
3. ✅ Creating MSP config.yaml
4. ✅ Volume mounts in docker-compose.yml (just need path adjustment)

---

## PowerShell Adaptation Notes

### Challenges:
1. **Bash vs PowerShell** - Test-network uses bash, we need PowerShell
2. **Path separators** - `/` vs `\`
3. **Variable syntax** - `$VAR` vs `$env:VAR` or `$VAR`
4. **Command chaining** - `&&` vs `;` or separate commands
5. **String escaping** - Different rules in PowerShell

### Solutions:
1. Use PowerShell equivalents for all bash commands
2. Use `Join-Path` for cross-platform paths
3. Use PowerShell variables and string interpolation
4. Use `;` or separate commands instead of `&&`
5. Use single quotes for strings with special chars, or escape properly

---

## Files We Need to Create/Modify

### New Files:
1. `scripts/generate-crypto-test-network.ps1` - Main crypto generation script
2. `scripts/enroll-org.ps1` - Function to enroll a single organization
3. `scripts/create-connection-profiles.ps1` - Generate connection JSON files
4. `network/organizations/ccp-template.json` - Connection profile template

### Modified Files:
1. `network/docker-compose.yml` - Update CA volume mounts to use `fabric-ca/` structure
2. `scripts/generate-genesis-block.ps1` - Should work as-is after crypto is generated
3. `scripts/deploy-network.ps1` - Orchestrate new crypto generation

### Unchanged Files:
- ✅ `network/configtx/configtx.yaml` - No changes needed
- ✅ All chaincode - No changes needed
- ✅ All backend code - No changes needed
- ✅ All frontend code - No changes needed

---

## Critical Success Factors

1. **CA Volume Mounts** - Must match where CA writes `tls-cert.pem`
2. **Wait Logic** - Must wait for `tls-cert.pem` before proceeding
3. **getcainfo** - Must use this to get `ca-cert.pem` (not copy from container)
4. **TLS Enrollment** - Must use `--enrollment.profile tls` with `--csr.hosts`
5. **Certificate Copying** - Must copy TLS certs to well-known names (`server.crt`, etc.)
6. **Connection Profiles** - Must generate for backend to connect

---

## Next Steps

1. **Update docker-compose.yml** - Adjust CA volume mounts to `fabric-ca/` structure
2. **Create PowerShell scripts** - Adapt test-network bash scripts to PowerShell
3. **Test CA startup** - Verify `tls-cert.pem` appears in mounted volumes
4. **Test enrollment** - Verify one organization enrollment works
5. **Scale to all orgs** - Apply to all 4 organizations
6. **Generate connection profiles** - Create JSON files for backend
7. **Test end-to-end** - Verify network starts, backend connects, chaincode deploys

---

## Conclusion

The test-network approach is **proven and reliable**. The key was understanding:
- CA automatically writes `tls-cert.pem` to mounted volume
- Use `getcainfo` to retrieve CA cert
- Proper TLS enrollment with `--csr.hosts`
- Copy TLS certs to well-known names
- Separate `fabric-ca/` directory structure

By adapting this approach to our 3-org network, we can achieve working crypto generation without reinventing the wheel.

---

**Analysis Date:** January 2026  
**Test-Network Version:** Latest (from fabric-samples repository)  
**Our Network:** 3 peer orgs + 1 orderer org
