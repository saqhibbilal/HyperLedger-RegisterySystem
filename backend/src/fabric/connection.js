const { Gateway, Wallets } = require('fabric-network');
const fs = require('fs');
const path = require('path');

class FabricConnection {
    constructor() {
        this.gateway = new Gateway();
        this.wallet = null;
        this.network = null;
        this.contract = null;
    }

    /**
     * Initialize wallet
     */
    async initializeWallet() {
        try {
            const walletPath = process.env.WALLET_PATH || path.join(__dirname, '../../wallet');

            // Ensure wallet directory exists
            if (!fs.existsSync(walletPath)) {
                fs.mkdirSync(walletPath, { recursive: true });
            }

            this.wallet = await Wallets.newFileSystemWallet(walletPath);
            return this.wallet;
        } catch (error) {
            throw new Error(`Failed to initialize wallet: ${error.message}`);
        }
    }

    /**
     * Connect to Fabric network
     * @param {string} userId - User identity ID
     */
    async connect(userId = 'admin') {
        try {
            if (!this.wallet) {
                await this.initializeWallet();
            }

            // Check if user exists in wallet
            const userExists = await this.wallet.get(userId);
            if (!userExists) {
                throw new Error(`User ${userId} does not exist in wallet. Please enroll first.`);
            }

            // Load connection profile
            const connectionProfilePath = process.env.CONNECTION_PROFILE_PATH ||
                path.join(__dirname, '../../../network/organizations/peerOrganizations/landreg.example.com/connection-landreg.json');

            if (!fs.existsSync(connectionProfilePath)) {
                throw new Error(`Connection profile not found at ${connectionProfilePath}`);
            }

            // Read JSON connection profile
            const connectionProfile = JSON.parse(fs.readFileSync(connectionProfilePath, 'utf8'));

            // Connection options
            const connectionOptions = {
                wallet: this.wallet,
                identity: userId,
                discovery: { enabled: false, asLocalhost: true }, // Disable discovery for now
                eventHandlerOptions: {
                    commitTimeout: 300,
                    strategy: null
                }
            };

            // Connect to gateway
            await this.gateway.connect(connectionProfile, connectionOptions);

            // Get network and contract
            const channelName = process.env.CHANNEL_NAME || 'landregistrychannel';
            const chaincodeName = process.env.CHAINCODE_NAME || 'landregistry';

            this.network = await this.gateway.getNetwork(channelName);
            this.contract = this.network.getContract(chaincodeName);

            return {
                gateway: this.gateway,
                network: this.network,
                contract: this.contract
            };
        } catch (error) {
            throw new Error(`Failed to connect to Fabric network: ${error.message}`);
        }
    }

    /**
     * Disconnect from network
     */
    async disconnect() {
        try {
            if (this.gateway) {
                await this.gateway.disconnect();
            }
            this.network = null;
            this.contract = null;
        } catch (error) {
            throw new Error(`Failed to disconnect: ${error.message}`);
        }
    }

    /**
     * Get contract instance
     */
    getContract() {
        if (!this.contract) {
            throw new Error('Not connected to network. Call connect() first.');
        }
        return this.contract;
    }
}

// Singleton instance
let fabricConnection = null;

/**
 * Get Fabric connection instance
 */
function getFabricConnection() {
    if (!fabricConnection) {
        fabricConnection = new FabricConnection();
    }
    return fabricConnection;
}

module.exports = {
    FabricConnection,
    getFabricConnection
};
