/**
 * Authentication middleware
 * 
 * Note: This is a simplified authentication middleware.
 * In a production environment, you would implement proper JWT/OAuth authentication.
 * For now, this checks for a user ID in the request headers or uses a default.
 */

/**
 * Authenticate user request
 * Placeholder for actual authentication logic
 */
function authenticateUser(req, res, next) {
    // In production, this would:
    // 1. Verify JWT token
    // 2. Check user permissions
    // 3. Validate MSP identity

    // For now, we'll use a simple header-based approach
    // or default to 'admin' for authorized operations

    const userId = req.headers['x-user-id'] || 'admin';

    // Verify user exists in wallet (simplified check)
    // In production, implement proper wallet/user verification

    req.user = {
        id: userId,
        mspId: process.env.ORG_MSPID || 'LandRegMSP'
    };

    next();
}

/**
 * Optional: Verify user belongs to authorized organization
 */
function verifyAuthorizedOrg(req, res, next) {
    const authorizedMSPs = ['LandRegMSP', 'SubRegistrarMSP', 'CourtMSP'];
    const userMSPId = req.user?.mspId;

    if (!authorizedMSPs.includes(userMSPId)) {
        return res.status(403).json({
            error: 'Forbidden',
            message: 'User does not belong to an authorized organization'
        });
    }

    next();
}

module.exports = {
    authenticateUser,
    verifyAuthorizedOrg
};
