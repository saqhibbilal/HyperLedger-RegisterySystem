const winston = require('winston');

const logger = winston.createLogger({
    level: process.env.LOG_LEVEL || 'info',
    format: winston.format.combine(
        winston.format.timestamp(),
        winston.format.errors({ stack: true }),
        winston.format.json()
    ),
    transports: [
        new winston.transports.Console(),
        new winston.transports.File({ filename: 'logs/error.log', level: 'error' })
    ]
});

/**
 * Error handling middleware
 */
function errorHandler(err, req, res, next) {
    // Log error
    logger.error('API Error', {
        error: err.message,
        stack: err.stack,
        path: req.path,
        method: req.method,
        ip: req.ip
    });

    // Determine status code
    let statusCode = err.statusCode || 500;
    let message = err.message || 'Internal Server Error';

    // Handle specific error types
    if (err.message.includes('not found') || err.message.includes('does not exist')) {
        statusCode = 404;
    } else if (err.message.includes('unauthorized') || err.message.includes('not authorized')) {
        statusCode = 401;
    } else if (err.message.includes('forbidden') || err.message.includes('permission')) {
        statusCode = 403;
    } else if (err.message.includes('validation') || err.message.includes('required')) {
        statusCode = 400;
    }

    // Send error response
    res.status(statusCode).json({
        error: {
            message: message,
            statusCode: statusCode,
            ...(process.env.NODE_ENV === 'development' && { stack: err.stack })
        }
    });
}

module.exports = errorHandler;
