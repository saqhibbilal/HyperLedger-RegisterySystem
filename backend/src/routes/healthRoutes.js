const express = require('express');
const { getFabricConnection } = require('../fabric/connection');

const router = express.Router();

/**
 * GET /api/health
 * Health check endpoint
 */
router.get('/', (req, res) => {
    res.json({
        status: 'healthy',
        timestamp: new Date().toISOString(),
        service: 'Land Registry API',
        version: '1.0.0'
    });
});

/**
 * GET /api/health/fabric
 * Check Fabric network connection
 */
router.get('/fabric', async (req, res) => {
    try {
        const fabricConnection = getFabricConnection();
        await fabricConnection.connect('admin');

        // Try to get contract
        const contract = fabricConnection.getContract();

        await fabricConnection.disconnect();

        res.json({
            status: 'connected',
            fabric: 'operational',
            timestamp: new Date().toISOString()
        });
    } catch (error) {
        res.status(503).json({
            status: 'unhealthy',
            fabric: 'disconnected',
            error: error.message,
            timestamp: new Date().toISOString()
        });
    }
});

module.exports = router;
