# Crypto Generation Guide

## Overview

This guide explains how to generate crypto materials using Fabric CA, following Hyperledger Fabric's test-network approach.

## Script: `generate-crypto-fabric-ca.ps1`

This script follows the same pattern as Fabric's `network.sh` when using `CRYPTO="Certificate Authorities"`.

### Steps:

1. **Clean up** existing crypto materials
2. **Start CAs** using docker-compose
3. **Wait for CA certificates** to be created
4. **Verify CA services** are ready using `fabric-ca-client getcainfo`
5. **Create identities** by enrolling admins and registering/enrolling peers
6. **Create MSP config files** (config.yaml)

## Usage

```powershell
.\scripts\generate-crypto-fabric-ca.ps1
```

## What It Does

### For Each Organization (LandReg, SubRegistrar, Court):

1. **Enroll Admin:**
   - Creates admin MSP directory structure
   - Enrolls admin user using Fabric CA client
   - Stores certificates in `organizations/peerOrganizations/{org}.example.com/users/Admin@{org}.example.com/msp`

2. **Register and Enroll Peer:**
   - Registers peer identity with CA
   - Enrolls peer to get certificates
   - Stores in `organizations/peerOrganizations/{org}.example.com/peers/peer0.{org}.example.com/msp`

### For Orderer:

1. **Enroll Orderer Admin**
2. **Register and Enroll Orderer**

## CA Certificate Locations

Based on docker-compose.yml volumes:
- **LandReg:** `network/organizations/peerOrganizations/landreg.example.com/ca/ca-cert.pem`
- **SubRegistrar:** `network/organizations/peerOrganizations/subregistrar.example.com/ca/ca-cert.pem`
- **Court:** `network/organizations/peerOrganizations/court.example.com/ca/ca-cert.pem`
- **Orderer:** `network/organizations/ordererOrganizations/example.com/ca/ca-cert.pem`

## Troubleshooting

### CA Certificates Not Found

If CA certificates aren't ready:
1. Wait longer (CAs need time to initialize)
2. Check CA logs: `docker logs ca-landreg`
3. Manually copy: `docker cp ca-landreg:/etc/hyperledger/fabric-ca-server-config/ca-cert.pem network/organizations/peerOrganizations/landreg.example.com/ca/ca-cert.pem`

### Enrollment Fails

If enrollment fails:
1. Verify CA is running: `docker ps | grep ca-`
2. Check CA is ready: `docker logs ca-landreg`
3. Verify CA certificate exists
4. Check network connectivity: `docker network ls`

## Next Steps

After crypto generation:
1. Generate genesis block
2. Start network
3. Create channel
4. Deploy chaincode
