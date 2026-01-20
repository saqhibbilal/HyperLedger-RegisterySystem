const express = require('express');
const { body, param, validationResult } = require('express-validator');
const landService = require('../services/landService');
const { authenticateUser } = require('../middleware/auth');

const router = express.Router();

// Validation middleware
const validate = (req, res, next) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
        return res.status(400).json({ errors: errors.array() });
    }
    next();
};

// Public routes (no authentication required)
/**
 * GET /api/land/:plotId
 * Query a land record by plot ID (public access)
 */
router.get('/:plotId',
    param('plotId').notEmpty().withMessage('Plot ID is required'),
    validate,
    async (req, res, next) => {
        try {
            const { plotId } = req.params;
            const result = await landService.queryLandRecord(plotId);
            res.json(result);
        } catch (error) {
            next(error);
        }
    }
);

/**
 * GET /api/land/:plotId/history
 * Query land ownership history (public access)
 */
router.get('/:plotId/history',
    param('plotId').notEmpty().withMessage('Plot ID is required'),
    validate,
    async (req, res, next) => {
        try {
            const { plotId } = req.params;
            const result = await landService.queryLandHistory(plotId);
            res.json(result);
        } catch (error) {
            next(error);
        }
    }
);

// Protected routes (require authentication)
/**
 * POST /api/land/create
 * Create a new land record (authorized only)
 */
router.post('/create',
    authenticateUser,
    [
        body('plotId').notEmpty().withMessage('Plot ID is required'),
        body('ownerId').notEmpty().withMessage('Owner ID is required'),
        body('ownerName').notEmpty().withMessage('Owner name is required'),
        body('area').isFloat({ min: 0.01 }).withMessage('Area must be a positive number'),
        body('location').notEmpty().withMessage('Location is required')
    ],
    validate,
    async (req, res, next) => {
        try {
            const userId = req.user?.id || 'admin'; // Default to admin if not specified
            const landData = req.body;
            const result = await landService.createLandRecord(userId, landData);
            res.status(201).json(result);
        } catch (error) {
            next(error);
        }
    }
);

/**
 * POST /api/land/transfer
 * Transfer land ownership (authorized only)
 */
router.post('/transfer',
    authenticateUser,
    [
        body('plotId').notEmpty().withMessage('Plot ID is required'),
        body('newOwnerId').notEmpty().withMessage('New owner ID is required'),
        body('newOwnerName').notEmpty().withMessage('New owner name is required')
    ],
    validate,
    async (req, res, next) => {
        try {
            const userId = req.user?.id || 'admin';
            const { plotId, newOwnerId, newOwnerName } = req.body;
            const result = await landService.transferLand(userId, plotId, {
                newOwnerId,
                newOwnerName
            });
            res.json(result);
        } catch (error) {
            next(error);
        }
    }
);

/**
 * GET /api/land
 * Get all land records (authorized only)
 */
router.get('/',
    authenticateUser,
    async (req, res, next) => {
        try {
            const userId = req.user?.id || 'admin';
            const result = await landService.getAllLandRecords(userId);
            res.json(result);
        } catch (error) {
            next(error);
        }
    }
);

/**
 * PUT /api/land/:plotId/status
 * Update land status (authorized only)
 */
router.put('/:plotId/status',
    authenticateUser,
    [
        param('plotId').notEmpty().withMessage('Plot ID is required'),
        body('status').isIn(['active', 'pending', 'disputed']).withMessage('Invalid status')
    ],
    validate,
    async (req, res, next) => {
        try {
            const userId = req.user?.id || 'admin';
            const { plotId } = req.params;
            const { status } = req.body;
            const result = await landService.updateLandStatus(userId, plotId, status);
            res.json(result);
        } catch (error) {
            next(error);
        }
    }
);

module.exports = router;
