const { Wallets } = require('fabric-network');
const { Gateway } = require('fabric-network');
const FabricCAServices = require('fabric-ca-client');
const fs = require('fs');
const path = require('path');

class WalletService {
    constructor() {
        this.wallet = null;
        this.walletPath = process.env.WALLET_PATH || path.join(__dirname, '../../wallet');
    }

    /**
     * Initialize wallet
     */
    async initialize() {
        try {
            // Ensure wallet directory exists
            if (!fs.existsSync(this.walletPath)) {
                fs.mkdirSync(this.walletPath, { recursive: true });
            }

            this.wallet = await Wallets.newFileSystemWallet(this.walletPath);
            return this.wallet;
        } catch (error) {
            throw new Error(`Failed to initialize wallet: ${error.message}`);
        }
    }

    /**
     * Enroll admin user
     */
    async enrollAdmin() {
        try {
            if (!this.wallet) {
                await this.initialize();
            }

            // Check if admin already exists
            const adminExists = await this.wallet.get('admin');
            if (adminExists) {
                return { message: 'Admin already enrolled', identity: adminExists };
            }

            // Get CA connection info
            const caName = process.env.CA_NAME || 'ca-landreg';
            const caEndpoint = process.env.CA_ENDPOINT || 'localhost:8054';
            const caAdminUsername = process.env.CA_ADMIN_USERNAME || 'admin';
            const caAdminPassword = process.env.CA_ADMIN_PASSWORD || 'adminpw';

            // Create CA client
            // CA has TLS_ENABLED=true, so we need to use HTTPS
            // For local development with self-signed certs, disable TLS verification
            const caURL = `https://${caEndpoint}`;
            const tlsOptions = {
                trustedRoots: [],
                verify: false // Disable TLS verification for local development
            };
            const ca = new FabricCAServices(caURL, tlsOptions, caName);

            // Enroll admin (if not already done in try-catch above)
            const enrollment = await ca.enroll({
                enrollmentID: caAdminUsername,
                enrollmentSecret: caAdminPassword
            });

            // Create identity
            const orgMSPID = process.env.ORG_MSPID || 'LandRegMSP';
            const x509Identity = {
                credentials: {
                    certificate: enrollment.certificate,
                    privateKey: enrollment.key.toBytes()
                },
                mspId: orgMSPID,
                type: 'X.509'
            };

            // Add to wallet
            await this.wallet.put('admin', x509Identity);

            return { message: 'Admin enrolled successfully', identity: x509Identity };
        } catch (error) {
            throw new Error(`Failed to enroll admin: ${error.message}`);
        }
    }

    /**
     * Register a new user
     * @param {string} userId - User ID to register
     * @param {string} affiliation - User affiliation (optional)
     */
    async registerUser(userId, affiliation = '') {
        try {
            if (!this.wallet) {
                await this.initialize();
            }

            // Check if user already exists
            const userExists = await this.wallet.get(userId);
            if (userExists) {
                return { message: `User ${userId} already registered`, identity: userExists };
            }

            // Check if admin exists
            const adminExists = await this.wallet.get('admin');
            if (!adminExists) {
                throw new Error('Admin not enrolled. Please enroll admin first.');
            }

            // Get CA connection info
            const caEndpoint = process.env.CA_ENDPOINT || 'localhost:8054';
            const caURL = `http://${caEndpoint}`;
            const ca = new FabricCAServices(caURL);

            // Create CA admin gateway connection (simplified - in production, use proper admin connection)
            // For now, this is a placeholder - actual implementation requires proper admin identity

            // Note: User registration requires admin privileges
            // This is a simplified version - production code would use proper admin gateway connection

            throw new Error('User registration requires proper admin gateway connection. Use CA admin interface directly.');
        } catch (error) {
            throw new Error(`Failed to register user: ${error.message}`);
        }
    }

    /**
     * Get user identity from wallet
     * @param {string} userId - User ID
     */
    async getUser(userId) {
        try {
            if (!this.wallet) {
                await this.initialize();
            }

            const identity = await this.wallet.get(userId);
            if (!identity) {
                throw new Error(`User ${userId} not found in wallet`);
            }

            return identity;
        } catch (error) {
            throw new Error(`Failed to get user: ${error.message}`);
        }
    }

    /**
     * List all identities in wallet
     */
    async listUsers() {
        try {
            if (!this.wallet) {
                await this.initialize();
            }

            // FileSystemWallet doesn't have direct list method
            // This would need to read the wallet directory
            const files = fs.readdirSync(this.walletPath);
            return files.filter(file => file.endsWith('.id'));
        } catch (error) {
            throw new Error(`Failed to list users: ${error.message}`);
        }
    }
}

module.exports = WalletService;
