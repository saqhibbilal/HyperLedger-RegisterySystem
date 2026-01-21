# Test Network Setup Guide

Based on Hyperledger Fabric's test-network approach.  
Reference: https://hyperledger-fabric.readthedocs.io/en/latest/test_network.html

## Overview

This guide walks through setting up the network using Fabric's test-network methodology, adapted for our Land Registry system.

## Current Status

✅ **Structure Created:** Directory structure and MSP folders are ready  
✅ **CAs Running:** Certificate Authorities are running  
⚠️ **Crypto Enrollment:** Needs proper certificate generation  
⚠️ **Genesis Block:** Needs crypto materials first  
⚠️ **Channel & Chaincode:** Pending

## Step-by-Step Setup

### Step 1: Clean Setup

```powershell
.\scripts\test-network-setup.ps1
```

This will:
- Clean up any existing network
- Create directory structure
- Start CAs
- Create MSP folder structure

### Step 2: Generate Crypto Materials

The crypto generation is complex and requires proper Fabric CA client operations. For learning purposes, we have two options:

#### Option A: Use Fabric's Test Network (Recommended for Learning)

1. Download Fabric samples:
   ```powershell
   git clone https://github.com/hyperledger/fabric-samples.git
   cd fabric-samples/test-network
   ```

2. Study their `network.sh` script to understand crypto generation

3. Adapt their approach for our network structure

#### Option B: Manual Enrollment (Current Approach)

We're working on proper enrollment scripts. The structure is ready, but full certificate generation requires:

1. Enrolling CA admin
2. Registering users/peers
3. Enrolling to get certificates
4. Copying to MSP folders
5. Generating TLS certificates

### Step 3: Generate Genesis Block

Once crypto materials are ready:

```powershell
.\scripts\generate-genesis-block.ps1
```

### Step 4: Start Network

```powershell
cd network
docker-compose up -d
```

### Step 5: Create Channel

```powershell
.\scripts\create-channel-full.ps1
```

### Step 6: Deploy Chaincode

```powershell
.\scripts\deploy-chaincode.ps1
```

## What's Working

- ✅ Network configuration (docker-compose.yml)
- ✅ Channel configuration (configtx.yaml)
- ✅ Chaincode (ready to deploy)
- ✅ Backend API (ready)
- ✅ Frontend UI (ready)

## What Needs Work

- ⚠️ Crypto material generation (complex, requires proper CA enrollment)
- ⚠️ Genesis block (needs crypto first)
- ⚠️ Channel creation (needs genesis block)
- ⚠️ Chaincode deployment (needs channel)

## Learning Path

For learning Hyperledger Fabric:

1. **Start with Fabric's test-network:**
   - Run their `./network.sh up`
   - Study how they generate crypto
   - Understand their channel creation
   - See how they deploy chaincode

2. **Adapt to our network:**
   - Use their crypto generation approach
   - Adapt for our 3-org structure
   - Use our chaincode

3. **Full deployment:**
   - Once crypto is generated, follow steps 3-6 above

## Current Container Status

Check with:
```powershell
docker ps -a
```

Expected:
- CAs: Running (may show unhealthy initially)
- Orderer: Exited (needs crypto)
- Peers: Exited (need crypto)

## Next Steps

1. Study Fabric's test-network crypto generation
2. Adapt their approach for our network
3. Generate proper crypto materials
4. Complete network deployment
5. Test end-to-end

## References

- [Fabric Test Network Docs](https://hyperledger-fabric.readthedocs.io/en/latest/test_network.html)
- [Fabric Samples GitHub](https://github.com/hyperledger/fabric-samples)
- [Fabric CA Documentation](https://hyperledger-fabric-ca.readthedocs.io/)
