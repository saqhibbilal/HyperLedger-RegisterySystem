# Network Deployment Guide

This guide explains how to deploy the complete Land Registry System network, including generating cryptographic materials, creating channels, and deploying chaincode.

## Prerequisites

- Docker Desktop running
- Network configuration files in place (Phase 2)
- Chaincode developed (Phase 3)

## Deployment Steps

### Step 1: Start the Network

Start all Fabric services (CAs, Orderer, Peers):

```powershell
.\scripts\network-start.ps1
```

This will:
- Check Docker is running
- Stop any existing network
- Start all containers
- Display network status

**Verify:** Check that all containers are running:
```powershell
docker ps
```

You should see:
- ca-orderer
- ca-landreg
- ca-subregistrar
- ca-court
- orderer.example.com
- peer0.landreg.example.com
- peer0.subregistrar.example.com
- peer0.court.example.com

### Step 2: Generate Cryptographic Materials

Generate certificates and keys for all organizations using Fabric CA:

```powershell
.\scripts\generate-crypto-materials.ps1
```

**Note:** Full crypto generation requires:
1. Using Fabric CA client to enroll administrators
2. Registering users for each organization
3. Generating MSP (Membership Service Provider) folders
4. Creating TLS certificates

This step creates the directory structure. Complete crypto generation will use Docker containers with fabric-tools.

### Step 3: Generate Genesis Block

Create the genesis block for the orderer network:

```powershell
.\scripts\generate-genesis-block.ps1
```

This uses `configtxgen` in a Docker container to generate:
- `network/system-genesis-block/genesis.block`

**Requirements:**
- Crypto materials must exist in `network/organizations/`
- `network/configtx/configtx.yaml` must be configured

### Step 4: Create Channel

Create the application channel for land registry:

```powershell
.\scripts\create-channel-full.ps1
```

This generates:
- Channel creation transaction: `network/channel-artifacts/landregistrychannel.tx`
- Creates the channel on the orderer
- Joins all peers to the channel

**Channel Details:**
- Channel Name: `landregistrychannel`
- Organizations: LandRegMSP, SubRegistrarMSP, CourtMSP

### Step 5: Deploy Chaincode

Install and deploy the land registry chaincode:

```powershell
.\scripts\deploy-chaincode.ps1
```

This performs:
1. **Package** chaincode
2. **Install** on all peer organizations
3. **Approve** chaincode definition (one approval per org)
4. **Commit** chaincode to channel

**Chaincode Details:**
- Name: `landregistry`
- Version: `1.0`
- Sequence: `1`
- Path: `github.com/landregistry/chaincode`
- Endorsement Policy: `OR('LandRegMSP.peer','SubRegistrarMSP.peer','CourtMSP.peer')`

## Automated Deployment

Run all steps in sequence:

```powershell
.\scripts\deploy-network.ps1
```

This orchestrates all deployment steps automatically.

## Manual Deployment Steps

If you prefer to deploy manually or need to troubleshoot:

### 1. Generate Crypto Materials (Manual)

Using Fabric CA client in Docker:

```powershell
# Enroll CA admin
docker exec -it ca-landreg fabric-ca-client enroll -u http://admin:adminpw@localhost:7054

# Register and enroll user
docker exec -it ca-landreg fabric-ca-client register --id.name admin --id.secret adminpw --id.attrs admin=true
docker exec -it ca-landreg fabric-ca-client enroll -u http://admin:adminpw@localhost:7054 -M /etc/hyperledger/fabric/msp
```

Repeat for each organization.

### 2. Create Channel (Manual)

Using peer CLI:

```powershell
# Create channel
docker exec -it peer0.landreg.example.com peer channel create \
  -o orderer.example.com:7050 \
  -c landregistrychannel \
  -f /etc/hyperledger/channel-artifacts/landregistrychannel.tx \
  --tls --cafile /etc/hyperledger/orderer/msp/tlscacerts/tlsca.example.com-cert.pem
```

### 3. Join Peers to Channel

```powershell
# Join peer0.landreg
docker exec -it peer0.landreg.example.com peer channel join \
  -b landregistrychannel.block

# Join peer0.subregistrar
docker exec -it peer0.subregistrar.example.com peer channel join \
  -b landregistrychannel.block

# Join peer0.court
docker exec -it peer0.court.example.com peer channel join \
  -b landregistrychannel.block
```

### 4. Install Chaincode

```powershell
# Package chaincode
docker exec -it peer0.landreg.example.com peer lifecycle chaincode package landregistry.tar.gz \
  --path /opt/gopath/src/github.com/landregistry/chaincode \
  --lang golang \
  --label landregistry_1.0

# Install on all peers
docker exec -it peer0.landreg.example.com peer lifecycle chaincode install landregistry.tar.gz
docker exec -it peer0.subregistrar.example.com peer lifecycle chaincode install landregistry.tar.gz
docker exec -it peer0.court.example.com peer lifecycle chaincode install landregistry.tar.gz
```

### 5. Approve and Commit

```powershell
# Get package ID (from installation output)
PACKAGE_ID="<package-id-from-install>"

# Approve for each organization
docker exec -it peer0.landreg.example.com peer lifecycle chaincode approveformyorg \
  -o orderer.example.com:7050 \
  --channelID landregistrychannel \
  --name landregistry \
  --version 1.0 \
  --package-id $PACKAGE_ID \
  --sequence 1 \
  --tls --cafile /etc/hyperledger/orderer/msp/tlscacerts/tlsca.example.com-cert.pem

# Repeat for other organizations, then commit
docker exec -it peer0.landreg.example.com peer lifecycle chaincode commit \
  -o orderer.example.com:7050 \
  --channelID landregistrychannel \
  --name landregistry \
  --version 1.0 \
  --sequence 1 \
  --tls --cafile /etc/hyperledger/orderer/msp/tlscacerts/tlsca.example.com-cert.pem \
  --peerAddresses peer0.landreg.example.com:7051 \
  --peerAddresses peer0.subregistrar.example.com:8051 \
  --peerAddresses peer0.court.example.com:9051
```

## Verification

### Check Network Status

```powershell
docker ps
```

All containers should be running.

### Check Channel

```powershell
docker exec -it peer0.landreg.example.com peer channel list
```

Should show `landregistrychannel`.

### Check Chaincode

```powershell
docker exec -it peer0.landreg.example.com peer lifecycle chaincode querycommitted \
  --channelID landregistrychannel
```

Should show chaincode committed.

### Test Chaincode

```powershell
# Create a land record (requires proper identity)
docker exec -it peer0.landreg.example.com peer chaincode invoke \
  -o orderer.example.com:7050 \
  -C landregistrychannel \
  -n landregistry \
  -c '{"function":"CreateLandRecord","Args":["PLOT001","OWNER001","John Doe","100.5","City Center"]}' \
  --tls --cafile /etc/hyperledger/orderer/msp/tlscacerts/tlsca.example.com-cert.pem
```

## Troubleshooting

### Containers Not Starting

Check Docker logs:
```powershell
docker logs <container-name>
```

### Crypto Materials Missing

Ensure crypto materials are generated in:
- `network/organizations/ordererOrganizations/`
- `network/organizations/peerOrganizations/`

### Channel Creation Fails

Verify:
1. Genesis block exists
2. Crypto materials are correct
3. Orderer is running and healthy

### Chaincode Installation Fails

Check:
1. Chaincode is properly packaged
2. Peer has correct MSP identity
3. Channel exists and peer is joined

### Permission Errors

Ensure:
1. Docker has proper permissions
2. File paths are accessible
3. Volume mounts are correct

## Clean Up

To completely reset the network:

```powershell
# Stop network
.\scripts\network-stop.ps1

# Remove crypto materials
Remove-Item -Recurse -Force network/organizations/*
Remove-Item -Recurse -Force network/channel-artifacts/*
Remove-Item -Recurse -Force network/system-genesis-block/*

# Restart
.\scripts\network-start.ps1
```

## Next Steps

After successful deployment:
1. **Phase 5**: Build backend API to interact with the network
2. **Phase 6**: Build frontend UI for users
3. **Phase 7**: Testing and documentation

## References

- [Hyperledger Fabric Documentation](https://hyperledger-fabric.readthedocs.io/)
- [Fabric Test Network Guide](https://hyperledger-fabric.readthedocs.io/en/latest/test_network.html)
- [Fabric CA Operations](https://hyperledger-fabric-ca.readthedocs.io/)
