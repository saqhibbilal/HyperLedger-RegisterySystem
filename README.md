# Private Land Registry System

A blockchain-based land registry system built with Hyperledger Fabric, designed to provide an immutable, auditable record of land ownership and transfers. This system mimics real government land-record systems with the added guarantees of blockchain technology.

## Overview

This project implements a permissioned blockchain network where:
- **Authorized Government Offices** (Land Registration Department, Sub-Registrar Offices, Courts) can create and update land records
- **Public Users** (citizens, buyers, banks) can view and verify land ownership history but cannot modify records
- All transactions are cryptographically signed and immutable
- Complete audit trail of all ownership transfers

## Technology Stack

- **Blockchain**: Hyperledger Fabric
- **Chaincode**: Go
- **Backend API**: Node.js + Express
- **Frontend**: Web UI (React/Vanilla JS)
- **Containerization**: Docker Desktop

## Prerequisites

Before starting, ensure you have the following installed on your Windows machine:

### Required Software

1. **Docker Desktop for Windows**
   - Download from: https://www.docker.com/products/docker-desktop/
   - Version: Latest stable release
   - Ensure WSL 2 backend is enabled (recommended)

2. **Node.js and npm**
   - Download from: https://nodejs.org/
   - Required version: Node.js v18 or higher
   - npm comes bundled with Node.js

3. **Go Programming Language**
   - Download from: https://go.dev/dl/
   - Required version: Go 1.20 or higher
   - Ensure Go is added to your system PATH

4. **Git**
   - Download from: https://git-scm.com/download/win
   - Required for cloning repositories and version control

5. **PowerShell 5.1+** (usually pre-installed on Windows 10/11)

### Optional but Recommended

- **Visual Studio Code** with Go and JavaScript extensions
- **Postman** or similar tool for API testing

## Quick Start

### Step 1: Verify Prerequisites

Run the verification script to check if all required tools are installed:

```powershell
.\scripts\verify-prerequisites.ps1
```

### Step 2: Setup Environment

Run the setup script to install Hyperledger Fabric binaries and Docker images:

```powershell
.\scripts\setup-env.ps1
```

**Note**: This script will:
- Download Hyperledger Fabric binaries
- Pull required Docker images
- Set up the project structure
- May take 10-15 minutes depending on your internet connection

### Step 3: Manual Verification

Verify each tool manually:

```powershell
# Check Docker
docker --version
docker-compose --version

# Check Node.js
node --version
npm --version

# Check Go
go version

# Check Git
git --version
```

## Project Structure

```
consortium/
├── chaincode/              # Smart contracts (Go)
├── network/                 # Fabric network configuration
├── backend/                 # REST API server
├── frontend/                # Web UI
├── scripts/                 # Automation scripts
├── docs/                    # Documentation
└── tests/                   # Test files
```

## Installation Guide

### Detailed Installation Steps

#### 1. Install Docker Desktop

1. Download Docker Desktop from the official website
2. Run the installer and follow the setup wizard
3. Enable WSL 2 backend during installation (recommended)
4. Restart your computer if prompted
5. Launch Docker Desktop and ensure it's running
6. Verify installation: `docker --version`

#### 2. Install Node.js

1. Download the LTS version from nodejs.org
2. Run the installer (includes npm)
3. Verify installation:
   ```powershell
   node --version
   npm --version
   ```

#### 3. Install Go

1. Download Go from go.dev/dl/
2. Run the installer (default location: `C:\Program Files\Go`)
3. Verify installation: `go version`
4. Ensure Go is in your PATH (installer usually does this automatically)

#### 4. Install Git

1. Download Git from git-scm.com/download/win
2. Run the installer with default settings
3. Verify installation: `git --version`

#### 5. Install Hyperledger Fabric

The setup script (`scripts/setup-env.ps1`) will handle this automatically. It will:
- Download Fabric binaries (v2.5.x)
- Pull Docker images for Fabric network
- Set up the test network structure

## Troubleshooting

### Docker Issues

- **Docker not starting**: Ensure WSL 2 is installed and updated
- **Permission denied**: Run PowerShell as Administrator
- **Port conflicts**: Check if ports 7050-7060, 8050-8060, 9050-9060 are available

### Node.js Issues

- **Command not found**: Restart PowerShell/terminal after installation
- **Version mismatch**: Use Node Version Manager (nvm-windows) if needed

### Go Issues

- **Command not found**: Add Go bin directory to PATH manually
- **GOPATH errors**: Go 1.11+ uses modules, GOPATH not required

### Network Issues

- **Slow downloads**: Fabric images are large (~2GB), ensure stable connection
- **Firewall blocking**: Allow Docker through Windows Firewall

## Next Steps

After completing Phase 1 (Environment Setup), proceed to:
- **Phase 2**: Fabric Network Configuration
- **Phase 3**: Chaincode Development
- **Phase 4**: Network Deployment
- **Phase 5**: Backend API Development
- **Phase 6**: Frontend Development
- **Phase 7**: Testing & Documentation

## Resources

- [Hyperledger Fabric Documentation](https://hyperledger-fabric.readthedocs.io/)
- [Fabric Test Network Guide](https://hyperledger-fabric.readthedocs.io/en/latest/test_network.html)
- [Fabric Chaincode Development](https://hyperledger-fabric.readthedocs.io/en/latest/chaincode4ade.html)

## License

This project is for educational and demonstration purposes.

## Support

For issues and questions, refer to the documentation in the `docs/` directory or check the troubleshooting section above.
