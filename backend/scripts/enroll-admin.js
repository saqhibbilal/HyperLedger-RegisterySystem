/**
 * Script to enroll admin user in Fabric CA
 * Run this before starting the API server
 */

const WalletService = require('../src/fabric/wallet');
require('dotenv').config();

async function enrollAdmin() {
    try {
        console.log('Initializing wallet service...');
        const walletService = new WalletService();
        await walletService.initialize();

        console.log('Enrolling admin user...');
        const result = await walletService.enrollAdmin();

        console.log('✅ Admin enrolled successfully!');
        console.log('Admin identity:', result.identity ? 'Created' : 'Already exists');

        process.exit(0);
    } catch (error) {
        console.error('❌ Failed to enroll admin:', error.message);
        console.error('Make sure:');
        console.error('  1. Fabric network is running');
        console.error('  2. CA is accessible at', process.env.CA_ENDPOINT || 'localhost:8054');
        console.error('  3. CA admin credentials are correct');
        process.exit(1);
    }
}

enrollAdmin();
