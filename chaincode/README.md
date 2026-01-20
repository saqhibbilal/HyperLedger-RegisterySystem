# Chaincode Development

This directory contains the smart contract (chaincode) implementation for the Land Registry System.

## Structure

```
chaincode/
└── landregistry/
    ├── go.mod                 # Go module dependencies
    ├── landregistry.go        # Main chaincode implementation
    ├── landregistry_test.go   # Unit tests
    ├── Makefile              # Build and test commands
    └── README.md             # Chaincode documentation
```

## Quick Start

### Build Chaincode

```bash
cd chaincode/landregistry
make build
```

### Run Tests

```bash
make test
```

### Format Code

```bash
make fmt
```

## Chaincode Functions

### Public Functions (Anyone can call)
- `QueryLandRecord(plotId)` - Query a land record by plot ID
- `QueryLandHistory(plotId)` - Query ownership history

### Authorized Functions (Government organizations only)
- `CreateLandRecord(plotId, ownerId, ownerName, area, location)` - Create new land record
- `TransferLand(plotId, newOwnerId, newOwnerName)` - Transfer ownership
- `GetAllLandRecords()` - Get all land records
- `UpdateLandStatus(plotId, status)` - Update land status

## Access Control

The chaincode enforces access control based on MSP IDs:
- **Authorized MSPs**: LandRegMSP, SubRegistrarMSP, CourtMSP
- **Public Access**: Query functions are available to everyone

## Data Models

### LandRecord
- PlotID, OwnerID, OwnerName
- Area, Location
- Timestamp, PreviousOwnerID
- TransferHistory, Status
- CreatedBy, LastModifiedBy

### TransferRecord
- TransferID, PlotID
- FromOwnerID, ToOwnerID, ToOwnerName
- Timestamp, AuthorizedBy, TransactionID

## Status Values

- `active` - Land is active and transferable
- `pending` - Transfer pending approval
- `disputed` - Under dispute, cannot transfer

## Deployment

Chaincode will be deployed in Phase 4:
1. Package chaincode
2. Install on all peer organizations
3. Approve chaincode definition
4. Commit to channel

## Testing

Unit tests are included in `landregistry_test.go`. Run with:
```bash
go test -v
```

## Documentation

See `chaincode/landregistry/README.md` for detailed documentation.
