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

## Full Deployment (Fabric network + channel + chaincode)

Run from the project root: `C:\Users\USER\Desktop\consortium`

### Clean-slate (if you previously used the 3-org setup)

If you already ran with the old config (Court/SubRegistrar in the channel), do a reset:

```powershell
cd network
docker-compose down
Remove-Item -Force channel-artifacts\landregistrychannel.block -ErrorAction SilentlyContinue
Remove-Item -Force system-genesis-block\genesis.block -ErrorAction SilentlyContinue
cd ..
```

Then continue from step 1 below.

### Run order

1. **Start CAs and network**
   ```powershell
   cd network
   docker-compose up -d
   cd ..
   ```
   Or: `.\scripts\network-start.ps1`

2. **Enroll crypto** (admins, peer0, TLS for LandReg; Court/SubRegistrar optional)
   ```powershell
   .\scripts\enroll-crypto.ps1
   ```

3. **Generate genesis block**
   ```powershell
   .\scripts\generate-genesis-block.ps1
   ```

4. **Restart orderer/peers** so the orderer uses the new genesis
   ```powershell
   cd network
   docker-compose down
   docker-compose up -d
   cd ..
   ```
   Or: `.\scripts\start-peers.ps1` (after a full `docker-compose up -d` once)

5. **Create channel**
   ```powershell
   .\scripts\create-channel-full.ps1
   ```

6. **Deploy chaincode**
   ```powershell
   .\scripts\deploy-chaincode.ps1
   ```

The channel is **1-org (LandReg only)**; one approval is enough for lifecycle, so chaincode deploy works without Court or SubRegistrar.

### One-command deploy (run in PowerShell, from project root)

```powershell
.\scripts\run-and-test.ps1
```

Use `-CleanSlate` if you previously had the 3-org setup:

```powershell
.\scripts\run-and-test.ps1 -CleanSlate
```

## Current Working Components

- ✅ Frontend UI (fully functional)
- ✅ Backend API (ready, needs Fabric connection)
- ✅ Chaincode (ready to deploy)
- ✅ Network configuration (ready)
- ⚠️ Crypto materials (needs generation)
- ⚠️ Channel (needs creation)
- ⚠️ Chaincode deployment (pending)
