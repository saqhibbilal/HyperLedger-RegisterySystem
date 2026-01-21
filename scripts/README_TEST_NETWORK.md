# Test Network Setup Scripts

## Overview

These scripts follow Hyperledger Fabric's test-network approach for setting up our Land Registry network.

## Scripts

### 1. `test-network-setup.ps1`
Initial setup: cleans up, creates structure, starts CAs.

**Usage:**
```powershell
.\scripts\test-network-setup.ps1
```

### 2. `enroll-crypto.ps1`
Enrolls users and generates certificates using Fabric CA.

**Usage:**
```powershell
.\scripts\enroll-crypto.ps1
```

**Note:** This requires proper CA setup and may need manual intervention.

### 3. `setup-test-network.ps1`
Master script that orchestrates all steps.

**Usage:**
```powershell
.\scripts\setup-test-network.ps1
```

## Current Limitations

Crypto generation is complex and requires:
- Proper CA certificate handling
- User registration
- Certificate enrollment
- MSP folder structure
- TLS certificate generation

For learning, refer to Fabric's test-network scripts.

## Recommended Learning Path

1. Study Fabric's test-network: `fabric-samples/test-network/network.sh`
2. Understand their crypto generation approach
3. Adapt for our 3-org network
4. Complete deployment

## Status

- ✅ Structure ready
- ✅ CAs running
- ⚠️ Crypto enrollment (in progress)
- ⚠️ Genesis block (pending crypto)
- ⚠️ Channel (pending genesis)
- ⚠️ Chaincode (pending channel)
