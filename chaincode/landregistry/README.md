# Land Registry Chaincode

Smart contract implementation for the Land Registry System built on Hyperledger Fabric.

## Overview

This chaincode provides functions for managing land ownership records on a permissioned blockchain. It enforces access control to ensure only authorized government organizations can create and modify records, while allowing public read access.

## Functions

### CreateLandRecord
Creates a new land ownership record.

**Parameters:**
- `plotId` (string): Unique identifier for the land parcel
- `ownerId` (string): Unique identifier for the owner
- `ownerName` (string): Name of the owner
- `area` (float64): Area of the land parcel
- `location` (string): Location/address of the land parcel

**Access:** Authorized organizations only (LandRegMSP, SubRegistrarMSP, CourtMSP)

**Example:**
```go
CreateLandRecord(ctx, "PLOT001", "OWNER001", "John Doe", 100.5, "123 Main St, City")
```

### TransferLand
Transfers ownership of a land parcel to a new owner.

**Parameters:**
- `plotId` (string): Unique identifier for the land parcel
- `newOwnerId` (string): Unique identifier for the new owner
- `newOwnerName` (string): Name of the new owner

**Access:** Authorized organizations only

**Example:**
```go
TransferLand(ctx, "PLOT001", "OWNER002", "Jane Smith")
```

### QueryLandRecord
Queries a land record by plot ID.

**Parameters:**
- `plotId` (string): Unique identifier for the land parcel

**Returns:** LandRecord object

**Access:** Public (anyone can query)

**Example:**
```go
record, err := QueryLandRecord(ctx, "PLOT001")
```

### QueryLandHistory
Queries the complete ownership history of a land parcel.

**Parameters:**
- `plotId` (string): Unique identifier for the land parcel

**Returns:** Array of TransferRecord objects

**Access:** Public (anyone can query)

**Example:**
```go
history, err := QueryLandHistory(ctx, "PLOT001")
```

### GetAllLandRecords
Returns all land records in the system.

**Returns:** Array of LandRecord objects

**Access:** Authorized organizations only

**Example:**
```go
records, err := GetAllLandRecords(ctx)
```

### UpdateLandStatus
Updates the status of a land record (active, pending, disputed).

**Parameters:**
- `plotId` (string): Unique identifier for the land parcel
- `status` (string): New status (must be "active", "pending", or "disputed")

**Access:** Authorized organizations only

**Example:**
```go
UpdateLandStatus(ctx, "PLOT001", "disputed")
```

## Data Structures

### LandRecord
```go
type LandRecord struct {
    PlotID          string   `json:"plotId"`
    OwnerID         string   `json:"ownerId"`
    OwnerName       string   `json:"ownerName"`
    Area            float64  `json:"area"`
    Location        string   `json:"location"`
    Timestamp       string   `json:"timestamp"`
    PreviousOwnerID string   `json:"previousOwnerId"`
    TransferHistory []string `json:"transferHistory"`
    Status          string   `json:"status"`
    CreatedBy       string   `json:"createdBy"`
    LastModifiedBy  string   `json:"lastModifiedBy"`
}
```

### TransferRecord
```go
type TransferRecord struct {
    TransferID    string `json:"transferId"`
    PlotID        string `json:"plotId"`
    FromOwnerID   string `json:"fromOwnerId"`
    ToOwnerID     string `json:"toOwnerId"`
    ToOwnerName   string `json:"toOwnerName"`
    Timestamp     string `json:"timestamp"`
    AuthorizedBy  string `json:"authorizedBy"`
    TransactionID string `json:"transactionId"`
}
```

## Access Control

The chaincode enforces access control based on MSP (Membership Service Provider) IDs:

**Authorized MSPs:**
- `LandRegMSP` - Land Registration Department
- `SubRegistrarMSP` - Sub-Registrar Offices
- `CourtMSP` - Court Authority

**Public Functions:**
- `QueryLandRecord` - Anyone can query individual records
- `QueryLandHistory` - Anyone can query ownership history

**Restricted Functions:**
- `CreateLandRecord` - Only authorized organizations
- `TransferLand` - Only authorized organizations
- `GetAllLandRecords` - Only authorized organizations
- `UpdateLandStatus` - Only authorized organizations

## Building and Testing

### Prerequisites
- Go 1.20 or higher
- Hyperledger Fabric dependencies

### Build
```bash
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

### Clean Build Artifacts
```bash
make clean
```

## Deployment

The chaincode will be deployed in Phase 4 using:
1. Package the chaincode
2. Install on all peer organizations
3. Approve chaincode definition
4. Commit chaincode definition to channel

## Error Handling

All functions include comprehensive error handling:
- Input validation
- Access control checks
- State validation
- Transaction rollback on errors

## Status Values

Valid status values for land records:
- `active` - Land is active and transferable
- `pending` - Land transfer is pending approval
- `disputed` - Land is under dispute and cannot be transferred

## Security Considerations

1. **Access Control**: Only authorized MSPs can modify records
2. **Input Validation**: All inputs are validated before processing
3. **Immutable History**: Transfer history is permanently recorded
4. **Status Checks**: Transfers are blocked for disputed/pending lands
5. **Transaction IDs**: All transfers are linked to blockchain transaction IDs

## Future Enhancements

Potential improvements:
- Support for partial land transfers
- Multi-signature requirements for high-value transfers
- Integration with external identity systems
- Support for land documents/metadata
- Advanced querying and filtering capabilities
