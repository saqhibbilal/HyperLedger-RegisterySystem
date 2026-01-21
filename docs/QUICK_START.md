# Quick Start Guide

## Current Status

✅ **Phase 1-6 Complete:**
- Environment setup
- Network configuration
- Chaincode development
- Backend API
- Frontend UI

⚠️ **Phase 4 Pending:**
- Full crypto material generation
- Channel creation
- Chaincode deployment

## Quick Test (Without Full Fabric Network)

You can test the frontend and backend connection:

### 1. Start Backend
```powershell
cd backend
npm start
```

### 2. Start Frontend
```powershell
cd frontend
npm run dev
```

### 3. Test Frontend
- Open `http://localhost:3001`
- UI will work, but API calls will fail until Fabric network is deployed

## Full Deployment (Requires Crypto Generation)

For a fully working system, you need to complete Phase 4:

1. **Generate Crypto Materials** - Complex, requires Fabric CA client
2. **Generate Genesis Block** - Requires crypto materials
3. **Create Channel** - Requires genesis block
4. **Deploy Chaincode** - Requires channel

## Recommendation

For a working example, refer to Hyperledger Fabric's test-network:
- Location: `fabric-samples/test-network`
- Has complete crypto generation scripts
- Can be adapted for this project

## Current Working Components

- ✅ Frontend UI (fully functional)
- ✅ Backend API (ready, needs Fabric connection)
- ✅ Chaincode (ready to deploy)
- ✅ Network configuration (ready)
- ⚠️ Crypto materials (needs generation)
- ⚠️ Channel (needs creation)
- ⚠️ Chaincode deployment (pending)
