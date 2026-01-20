# Land Registry Network Configuration

This directory contains all configuration files for the Hyperledger Fabric network used by the Land Registry System.

## Network Architecture

The network consists of:

1. **Orderer Organization** (OrdererMSP)
   - Single orderer node for transaction ordering

2. **Land Registration Department** (LandRegMSP)
   - Main registration authority
   - Peer: `peer0.landreg.example.com:7051`

3. **Sub-Registrar Office** (SubRegistrarMSP)
   - Sub-registrar offices
   - Peer: `peer0.subregistrar.example.com:8051`

4. **Court Authority** (CourtMSP)
   - Court system for dispute resolution
   - Peer: `peer0.court.example.com:9051`

## Directory Structure

```
network/
├── docker-compose.yml          # Docker Compose configuration for all services
├── configtx/
│   └── configtx.yaml          # Channel and organization configuration
├── organizations/              # Generated crypto materials (created at runtime)
│   ├── ordererOrganizations/
│   └── peerOrganizations/
├── channel-artifacts/         # Generated channel artifacts (created at runtime)
├── system-genesis-block/      # Generated genesis block (created at runtime)
└── .env.example               # Environment variables template
```

## Configuration Files

### docker-compose.yml

Defines all network services:
- 4 Certificate Authorities (CAs) - one for each organization
- 1 Orderer node
- 3 Peer nodes (one for each organization)

### configtx.yaml

Defines:
- Organization MSPs and policies
- Channel configuration
- Orderer configuration
- Application capabilities

### .env.example

Contains environment variables for network configuration. Copy to `.env` and modify as needed.

## Usage

### Start the Network

```powershell
.\scripts\network-start.ps1
```

This will:
1. Check Docker is running
2. Stop any existing network
3. Start all Fabric services
4. Display network status

### Stop the Network

```powershell
.\scripts\network-stop.ps1
```

This will:
1. Stop all containers
2. Remove volumes
3. Clean up network resources

### Generate Crypto Materials

```powershell
.\scripts\generate-crypto.ps1
```

**Note**: Full crypto generation will be completed in Phase 4 with Fabric CA client tools.

### Create Channel

```powershell
.\scripts\create-channel.ps1
```

**Note**: Full channel creation will be completed in Phase 4 with configtxgen and peer commands.

## Ports

The network uses the following ports:

| Service | Port | Description |
|---------|------|-------------|
| Orderer | 7050 | Orderer service |
| CA Orderer | 7054 | CA service for orderer |
| CA LandReg | 8054 | CA service for Land Registration |
| CA SubRegistrar | 9054 | CA service for Sub-Registrar |
| CA Court | 10054 | CA service for Court |
| Peer0 LandReg | 7051, 7052 | Peer service and chaincode |
| Peer0 SubRegistrar | 8051, 8052 | Peer service and chaincode |
| Peer0 Court | 9051, 9052 | Peer service and chaincode |

## Endorsement Policy

The default endorsement policy requires a majority of organizations:
```
OR('LandRegMSP.peer','SubRegistrarMSP.peer','CourtMSP.peer')
```

This means at least 2 out of 3 organizations must endorse transactions.

## Troubleshooting

### Port Conflicts

If you encounter port conflicts, check which ports are in use:
```powershell
netstat -ano | findstr "7050 7051 8051 9051"
```

### Container Issues

View container logs:
```powershell
docker logs <container-name>
```

View all containers:
```powershell
docker ps -a
```

### Network Reset

To completely reset the network:
```powershell
.\scripts\network-stop.ps1
Remove-Item -Recurse -Force network/organizations
Remove-Item -Recurse -Force network/channel-artifacts
Remove-Item -Recurse -Force network/system-genesis-block
```

## Next Steps

After setting up the network configuration:
1. **Phase 3**: Develop chaincode (smart contracts)
2. **Phase 4**: Generate crypto materials, create channel, deploy chaincode
3. **Phase 5**: Build backend API
4. **Phase 6**: Build frontend UI

## References

- [Hyperledger Fabric Documentation](https://hyperledger-fabric.readthedocs.io/)
- [Fabric Test Network](https://hyperledger-fabric.readthedocs.io/en/latest/test_network.html)
- [Fabric CA Documentation](https://hyperledger-fabric-ca.readthedocs.io/)
