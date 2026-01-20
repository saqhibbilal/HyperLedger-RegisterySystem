const { getFabricConnection } = require('../fabric/connection');

class LandService {
    /**
     * Create a new land record
     * @param {string} userId - User ID for transaction
     * @param {Object} landData - Land record data
     */
    async createLandRecord(userId, landData) {
        const { plotId, ownerId, ownerName, area, location } = landData;

        // Validate required fields
        if (!plotId || !ownerId || !ownerName || !area || !location) {
            throw new Error('Missing required fields: plotId, ownerId, ownerName, area, location');
        }

        if (typeof area !== 'number' || area <= 0) {
            throw new Error('Area must be a positive number');
        }

        const fabricConnection = getFabricConnection();
        await fabricConnection.connect(userId);

        try {
            const contract = fabricConnection.getContract();
            const result = await contract.submitTransaction(
                'CreateLandRecord',
                plotId,
                ownerId,
                ownerName,
                area.toString(),
                location
            );

            return {
                success: true,
                transactionId: result.toString(),
                message: 'Land record created successfully'
            };
        } catch (error) {
            throw new Error(`Failed to create land record: ${error.message}`);
        } finally {
            await fabricConnection.disconnect();
        }
    }

    /**
     * Transfer land ownership
     * @param {string} userId - User ID for transaction
     * @param {string} plotId - Plot ID
     * @param {Object} transferData - Transfer data
     */
    async transferLand(userId, plotId, transferData) {
        const { newOwnerId, newOwnerName } = transferData;

        if (!plotId || !newOwnerId || !newOwnerName) {
            throw new Error('Missing required fields: plotId, newOwnerId, newOwnerName');
        }

        const fabricConnection = getFabricConnection();
        await fabricConnection.connect(userId);

        try {
            const contract = fabricConnection.getContract();
            const result = await contract.submitTransaction(
                'TransferLand',
                plotId,
                newOwnerId,
                newOwnerName
            );

            return {
                success: true,
                transactionId: result.toString(),
                message: 'Land ownership transferred successfully'
            };
        } catch (error) {
            throw new Error(`Failed to transfer land: ${error.message}`);
        } finally {
            await fabricConnection.disconnect();
        }
    }

    /**
     * Query land record by plot ID
     * @param {string} plotId - Plot ID
     */
    async queryLandRecord(plotId) {
        if (!plotId) {
            throw new Error('Plot ID is required');
        }

        const fabricConnection = getFabricConnection();
        // Use 'admin' as default for read operations (public access)
        await fabricConnection.connect('admin');

        try {
            const contract = fabricConnection.getContract();
            const result = await contract.evaluateTransaction('QueryLandRecord', plotId);

            const landRecord = JSON.parse(result.toString());
            return {
                success: true,
                data: landRecord
            };
        } catch (error) {
            throw new Error(`Failed to query land record: ${error.message}`);
        } finally {
            await fabricConnection.disconnect();
        }
    }

    /**
     * Query land ownership history
     * @param {string} plotId - Plot ID
     */
    async queryLandHistory(plotId) {
        if (!plotId) {
            throw new Error('Plot ID is required');
        }

        const fabricConnection = getFabricConnection();
        await fabricConnection.connect('admin');

        try {
            const contract = fabricConnection.getContract();
            const result = await contract.evaluateTransaction('QueryLandHistory', plotId);

            const history = JSON.parse(result.toString());
            return {
                success: true,
                data: history
            };
        } catch (error) {
            throw new Error(`Failed to query land history: ${error.message}`);
        } finally {
            await fabricConnection.disconnect();
        }
    }

    /**
     * Get all land records (authorized only)
     * @param {string} userId - User ID for transaction
     */
    async getAllLandRecords(userId) {
        const fabricConnection = getFabricConnection();
        await fabricConnection.connect(userId);

        try {
            const contract = fabricConnection.getContract();
            const result = await contract.evaluateTransaction('GetAllLandRecords');

            const records = JSON.parse(result.toString());
            return {
                success: true,
                data: records
            };
        } catch (error) {
            throw new Error(`Failed to get all land records: ${error.message}`);
        } finally {
            await fabricConnection.disconnect();
        }
    }

    /**
     * Update land status
     * @param {string} userId - User ID for transaction
     * @param {string} plotId - Plot ID
     * @param {string} status - New status (active, pending, disputed)
     */
    async updateLandStatus(userId, plotId, status) {
        if (!plotId || !status) {
            throw new Error('Missing required fields: plotId, status');
        }

        const validStatuses = ['active', 'pending', 'disputed'];
        if (!validStatuses.includes(status)) {
            throw new Error(`Invalid status. Must be one of: ${validStatuses.join(', ')}`);
        }

        const fabricConnection = getFabricConnection();
        await fabricConnection.connect(userId);

        try {
            const contract = fabricConnection.getContract();
            const result = await contract.submitTransaction(
                'UpdateLandStatus',
                plotId,
                status
            );

            return {
                success: true,
                transactionId: result.toString(),
                message: 'Land status updated successfully'
            };
        } catch (error) {
            throw new Error(`Failed to update land status: ${error.message}`);
        } finally {
            await fabricConnection.disconnect();
        }
    }
}

module.exports = new LandService();
