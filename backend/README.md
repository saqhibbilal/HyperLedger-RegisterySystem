# Land Registry Backend API

REST API backend for the Land Registry System built on Hyperledger Fabric.

## Overview

This backend provides a REST API interface to interact with the Hyperledger Fabric network. It uses the Fabric SDK to submit transactions and query the blockchain.

## Features

- RESTful API for land registry operations
- Integration with Hyperledger Fabric SDK
- Wallet management for user identities
- Authentication middleware (simplified)
- Error handling and logging
- Input validation
- Health check endpoints

## Prerequisites

- Node.js v18 or higher
- npm v9 or higher
- Hyperledger Fabric network running (Phase 4)
- Crypto materials generated
- Channel created and chaincode deployed

## Installation

1. Install dependencies:
```bash
npm install
```

2. Configure environment:
```bash
cp .env.example .env
# Edit .env with your network configuration
```

3. Ensure wallet directory exists:
```bash
mkdir -p wallet logs
```

## Configuration

Edit `.env` file with your network configuration:

```env
PORT=3000
CHANNEL_NAME=landregistrychannel
CHAINCODE_NAME=landregistry
ORG_MSPID=LandRegMSP
CA_ENDPOINT=localhost:8054
WALLET_PATH=./wallet
CONNECTION_PROFILE_PATH=../network/organizations/peerOrganizations/landreg.example.com/connection-landreg.yaml
```

## Usage

### Start Server

Development mode (with auto-reload):
```bash
npm run dev
```

Production mode:
```bash
npm start
```

Server will start on `http://localhost:3000`

## API Endpoints

### Public Endpoints

#### GET /api/health
Health check endpoint.

**Response:**
```json
{
  "status": "healthy",
  "timestamp": "2024-01-20T10:00:00.000Z",
  "service": "Land Registry API",
  "version": "1.0.0"
}
```

#### GET /api/health/fabric
Check Fabric network connection.

#### GET /api/land/:plotId
Query a land record by plot ID.

**Example:**
```bash
GET /api/land/PLOT001
```

**Response:**
```json
{
  "success": true,
  "data": {
    "plotId": "PLOT001",
    "ownerId": "OWNER001",
    "ownerName": "John Doe",
    "area": 100.5,
    "location": "City Center",
    "status": "active",
    ...
  }
}
```

#### GET /api/land/:plotId/history
Query land ownership history.

**Example:**
```bash
GET /api/land/PLOT001/history
```

### Protected Endpoints (Require Authentication)

These endpoints require the `X-User-ID` header or default to 'admin'.

#### POST /api/land/create
Create a new land record.

**Headers:**
```
X-User-ID: admin
```

**Body:**
```json
{
  "plotId": "PLOT001",
  "ownerId": "OWNER001",
  "ownerName": "John Doe",
  "area": 100.5,
  "location": "City Center"
}
```

#### POST /api/land/transfer
Transfer land ownership.

**Body:**
```json
{
  "plotId": "PLOT001",
  "newOwnerId": "OWNER002",
  "newOwnerName": "Jane Smith"
}
```

#### GET /api/land
Get all land records.

#### PUT /api/land/:plotId/status
Update land status.

**Body:**
```json
{
  "status": "disputed"
}
```

## Wallet Management

### Enroll Admin

Before using the API, you need to enroll the admin user:

```javascript
const WalletService = require('./src/fabric/wallet');
const walletService = new WalletService();

await walletService.enrollAdmin();
```

Or use the wallet management script (to be created).

## Project Structure

```
backend/
├── src/
│   ├── fabric/
│   │   ├── connection.js      # Fabric network connection
│   │   └── wallet.js          # Wallet management
│   ├── services/
│   │   └── landService.js     # Business logic for land operations
│   ├── routes/
│   │   ├── landRoutes.js      # Land API routes
│   │   └── healthRoutes.js    # Health check routes
│   └── middleware/
│       ├── auth.js            # Authentication middleware
│       └── errorHandler.js    # Error handling
├── wallet/                    # Fabric wallet (created at runtime)
├── logs/                      # Application logs
├── server.js                  # Main server file
├── package.json
└── .env.example
```

## Error Handling

The API returns standardized error responses:

```json
{
  "error": {
    "message": "Error message",
    "statusCode": 400
  }
}
```

## Logging

Logs are written to:
- Console (development)
- `logs/combined.log` (all logs)
- `logs/error.log` (errors only)

## Testing

Run tests:
```bash
npm test
```

## Troubleshooting

### Wallet Not Found
Ensure admin is enrolled:
```javascript
const walletService = new WalletService();
await walletService.enrollAdmin();
```

### Connection Failed
1. Verify Fabric network is running
2. Check connection profile path
3. Verify crypto materials exist
4. Check channel and chaincode are deployed

### Transaction Fails
1. Verify user has proper MSP identity
2. Check endorsement policy requirements
3. Verify user has permissions for the operation

## Development

### Code Structure

- **Services**: Business logic and Fabric SDK interactions
- **Routes**: HTTP endpoints and request validation
- **Middleware**: Authentication, error handling
- **Fabric**: Network connection and wallet management

### Adding New Endpoints

1. Add service method in `src/services/landService.js`
2. Add route in `src/routes/landRoutes.js`
3. Add validation rules
4. Update API documentation

## Security Notes

- Current authentication is simplified
- Production should use proper JWT/OAuth
- Wallet should be secured
- Use HTTPS in production
- Implement rate limiting
- Validate all inputs

## Next Steps

- Implement proper JWT authentication
- Add user registration endpoint
- Add API key authentication option
- Implement request rate limiting
- Add API documentation (Swagger/OpenAPI)
- Add comprehensive tests

## License

MIT
