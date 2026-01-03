const midtransClient = require('midtrans-client');
const { Client, Databases } = require('node-appwrite');

// =============================================
// UTILITY FUNCTIONS
// =============================================

/**
 * Retry a function with exponential backoff
 */
async function retryWithBackoff(fn, maxRetries = 3, operation = 'operation') {
    let lastError;

    for (let i = 0; i < maxRetries; i++) {
        try {
            return await fn();
        } catch (err) {
            lastError = err;

            if (i < maxRetries - 1) {
                const delay = 1000 * Math.pow(2, i); // 1s, 2s, 4s
                console.log(`⚠️  ${operation} failed, retrying in ${delay}ms... (attempt ${i + 1}/${maxRetries})`);
                await new Promise(resolve => setTimeout(resolve, delay));
            }
        }
    }

    throw lastError;
}

/**
 * Validate order ID format
 */
function validateOrderId(orderId) {
    if (!orderId) {
        return { valid: false, error: 'orderId is required' };
    }

    if (typeof orderId !== 'string') {
        return { valid: false, error: 'orderId must be a string' };
    }

    // Appwrite document IDs are 20 characters (alphanumeric)
    if (!/^[a-z0-9]{20}$/.test(orderId)) {
        return { valid: false, error: 'orderId must be a valid Appwrite document ID (20 alphanumeric characters)' };
    }

    return { valid: true };
}

/**
 * Validate action parameter
 */
function validateAction(action) {
    if (!action) {
        return { valid: true }; // Optional, defaults to 'create'
    }

    const validActions = ['create', 'checkStatus'];
    if (!validActions.includes(action)) {
        return {
            valid: false,
            error: `action must be one of: ${validActions.join(', ')}`
        };
    }

    return { valid: true };
}

/**
 * Map Midtrans status to order status with all edge cases
 */
function mapMidtransStatus(transactionStatus, fraudStatus) {
    const statusMap = {
        'capture': fraudStatus === 'accept' ? 'confirmed' : 'pending_payment',
        'settlement': 'confirmed',
        'pending': 'pending_payment',
        'deny': 'cancelled',
        'cancel': 'cancelled',
        'expire': 'expired',  // ✅ UPDATED: Expired payments get 'expired' status
        'refund': 'refunded',
        'partial_refund': 'partially_refunded',
        'failure': 'cancelled',
    };

    return statusMap[transactionStatus] || 'pending_payment';
}

/**
 * Create standardized error response
 */
function createErrorResponse(code, message, details = null, statusCode = 500) {
    return {
        success: false,
        error: {
            code,
            message,
            ...(details && { details })
        },
        metadata: {
            timestamp: new Date().toISOString()
        }
    };
}

/**
 * Create standardized success response
 */
function createSuccessResponse(data) {
    return {
        success: true,
        data,
        metadata: {
            timestamp: new Date().toISOString()
        }
    };
}

// =============================================
// MAIN HANDLER
// =============================================

module.exports = async ({ req, res, log, error }) => {
    const requestId = Math.random().toString(36).substring(2, 9);

    try {
        log(`[${requestId}] 📨 Request received`);

        // Parse request body
        const { action, orderId } = JSON.parse(req.body || '{}');

        log(`[${requestId}] Action: ${action || 'create'}, OrderID: ${orderId}`);

        // Validate orderId
        const orderIdValidation = validateOrderId(orderId);
        if (!orderIdValidation.valid) {
            error(`[${requestId}] ❌ Validation failed: ${orderIdValidation.error}`);
            return res.json(
                createErrorResponse('INVALID_ORDER_ID', orderIdValidation.error),
                400
            );
        }

        // Validate action
        const actionValidation = validateAction(action);
        if (!actionValidation.valid) {
            error(`[${requestId}] ❌ Validation failed: ${actionValidation.error}`);
            return res.json(
                createErrorResponse('INVALID_ACTION', actionValidation.error),
                400
            );
        }

        // Route based on action
        if (action === 'checkStatus') {
            return await checkPaymentStatus({ orderId, res, log, error, requestId });
        } else {
            return await createPayment({ orderId, res, log, error, requestId });
        }

    } catch (err) {
        error(`[${requestId}] ❌ Unexpected error: ${err.message}`);
        if (err.stack) {
            error(`[${requestId}] Stack trace: ${err.stack}`);
        }

        return res.json(
            createErrorResponse(
                'INTERNAL_ERROR',
                'An unexpected error occurred',
                err.message
            ),
            500
        );
    }
};

// =============================================
// CREATE PAYMENT
// =============================================

async function createPayment({ orderId, res, log, error, requestId }) {
    const startTime = Date.now();
    log(`[${requestId}] 📝 Creating payment for order: ${orderId}`);

    try {
        // Initialize Appwrite client
        const client = new Client()
            .setEndpoint(process.env.APPWRITE_ENDPOINT || 'https://cloud.appwrite.io/v1')
            .setProject(process.env.APPWRITE_PROJECT_ID)
            .setKey(process.env.APPWRITE_API_KEY);

        const databases = new Databases(client);

        // Get order from database with retry
        log(`[${requestId}] 🔍 Fetching order from database...`);

        const order = await retryWithBackoff(
            () => databases.getDocument(
                process.env.DATABASE_ID,
                process.env.ORDERS_COLLECTION_ID,
                orderId
            ),
            3,
            'Database fetch'
        );

        if (!order) {
            error(`[${requestId}] ❌ Order not found: ${orderId}`);
            return res.json(
                createErrorResponse('ORDER_NOT_FOUND', 'Order not found in database'),
                404
            );
        }

        log(`[${requestId}] ✅ Order found: ${order.invoice_number}, Amount: Rp ${order.total_price}`);

        // Validate order can be paid
        if (order.order_status === 'confirmed') {
            error(`[${requestId}] ⚠️  Order already confirmed`);
            return res.json(
                createErrorResponse(
                    'ORDER_ALREADY_PAID',
                    'This order has already been paid',
                    `Order status: ${order.order_status}`
                ),
                400
            );
        }

        if (order.order_status === 'cancelled') {
            error(`[${requestId}] ⚠️  Order is cancelled`);
            return res.json(
                createErrorResponse(
                    'ORDER_CANCELLED',
                    'Cannot create payment for cancelled order'
                ),
                400
            );
        }

        // Initialize Midtrans Snap client
        const isProduction = process.env.MIDTRANS_IS_PRODUCTION === 'true';
        log(`[${requestId}] 🔧 Midtrans mode: ${isProduction ? 'PRODUCTION' : 'SANDBOX'}`);

        const snap = new midtransClient.Snap({
            isProduction: isProduction,
            serverKey: process.env.MIDTRANS_SERVER_KEY,
            clientKey: process.env.MIDTRANS_CLIENT_KEY,
        });

        // Prepare transaction parameters
        const parameter = {
            transaction_details: {
                order_id: order.invoice_number,
                gross_amount: parseInt(order.total_price),
            },
            customer_details: {
                first_name: order.customer_name,
                phone: order.table_number,
            },
            enabled_payments: [
                'gopay', 'shopeepay', 'other_qris',
                'bca_va', 'bni_va', 'bri_va', 'permata_va',
                'credit_card'
            ],
            callbacks: {
                finish: `myapp://payment/finish?order_id=${orderId}`,
            },
        };

        log(`[${requestId}] 💳 Creating Snap transaction...`);

        // Create transaction with retry
        const transaction = await retryWithBackoff(
            () => snap.createTransaction(parameter),
            3,
            'Midtrans create transaction'
        );

        const duration = Date.now() - startTime;
        log(`[${requestId}] ✅ Snap token created successfully in ${duration}ms`);
        log(`[${requestId}]    Token: ${transaction.token}`);
        log(`[${requestId}]    Redirect URL: ${transaction.redirect_url}`);

        // Return success response
        return res.json(
            createSuccessResponse({
                snapToken: transaction.token,
                redirectUrl: transaction.redirect_url,
                orderId: orderId,
                orderNumber: order.invoice_number,
            })
        );

    } catch (err) {
        const duration = Date.now() - startTime;
        error(`[${requestId}] ❌ Create payment failed after ${duration}ms: ${err.message}`);

        // Handle Midtrans-specific errors
        if (err.httpStatusCode) {
            error(`[${requestId}] Midtrans API Error: ${err.httpStatusCode}`);

            if (err.httpStatusCode === 401) {
                return res.json(
                    createErrorResponse(
                        'MIDTRANS_AUTH_ERROR',
                        'Midtrans authentication failed',
                        'Please check server key configuration'
                    ),
                    500
                );
            }

            if (err.httpStatusCode === 400) {
                return res.json(
                    createErrorResponse(
                        'MIDTRANS_INVALID_REQUEST',
                        'Invalid payment request',
                        err.ApiResponse?.status_message || err.message
                    ),
                    400
                );
            }
        }

        // Generic error
        return res.json(
            createErrorResponse(
                'PAYMENT_CREATION_FAILED',
                'Failed to create payment',
                err.message
            ),
            500
        );
    }
}

// =============================================
// CHECK PAYMENT STATUS
// =============================================

async function checkPaymentStatus({ orderId, res, log, error, requestId }) {
    const startTime = Date.now();
    log(`[${requestId}] 🔍 Checking payment status for order: ${orderId}`);

    try {
        // Initialize Appwrite client
        const client = new Client()
            .setEndpoint(process.env.APPWRITE_ENDPOINT || 'https://cloud.appwrite.io/v1')
            .setProject(process.env.APPWRITE_PROJECT_ID)
            .setKey(process.env.APPWRITE_API_KEY);

        const databases = new Databases(client);

        // Get order from database with retry
        log(`[${requestId}] 📖 Fetching order from database...`);

        const order = await retryWithBackoff(
            () => databases.getDocument(
                process.env.DATABASE_ID,
                process.env.ORDERS_COLLECTION_ID,
                orderId
            ),
            3,
            'Database fetch'
        );

        if (!order) {
            error(`[${requestId}] ❌ Order not found: ${orderId}`);
            return res.json(
                createErrorResponse('ORDER_NOT_FOUND', 'Order not found in database'),
                404
            );
        }

        const invoiceNumber = order.invoice_number;
        log(`[${requestId}] 🧾 Invoice number: ${invoiceNumber}`);
        log(`[${requestId}] 📊 Current order status: ${order.order_status}`);

        // Initialize Midtrans Core API client
        const isProduction = process.env.MIDTRANS_IS_PRODUCTION === 'true';
        const coreApi = new midtransClient.CoreApi({
            isProduction,
            serverKey: process.env.MIDTRANS_SERVER_KEY,
            clientKey: process.env.MIDTRANS_CLIENT_KEY
        });

        log(`[${requestId}] 🔌 Querying Midtrans Transaction Status API...`);

        // Get transaction status with retry
        const statusResponse = await retryWithBackoff(
            () => coreApi.transaction.status(invoiceNumber),
            3,
            'Midtrans status check'
        );

        log(`[${requestId}] 📥 Midtrans response received`);
        log(`[${requestId}]    Transaction Status: ${statusResponse.transaction_status}`);
        log(`[${requestId}]    Payment Type: ${statusResponse.payment_type}`);
        log(`[${requestId}]    Gross Amount: ${statusResponse.gross_amount}`);
        log(`[${requestId}]    Status Code: ${statusResponse.status_code}`);

        // Map Midtrans status to order status
        const transactionStatus = statusResponse.transaction_status;
        const fraudStatus = statusResponse.fraud_status;
        const orderStatus = mapMidtransStatus(transactionStatus, fraudStatus);

        log(`[${requestId}] 🎯 Mapped order status: ${orderStatus}`);

        // Update order if status changed
        if (orderStatus !== order.order_status) {
            log(`[${requestId}] 💾 Updating order status from "${order.order_status}" to "${orderStatus}"`);

            await retryWithBackoff(
                () => databases.updateDocument(
                    process.env.DATABASE_ID,
                    process.env.ORDERS_COLLECTION_ID,
                    orderId,
                    { order_status: orderStatus }
                ),
                3,
                'Database update'
            );

            log(`[${requestId}] ✅ Order status updated successfully`);
        } else {
            log(`[${requestId}] ℹ️  Order status unchanged, no update needed`);
        }

        const duration = Date.now() - startTime;
        log(`[${requestId}] ✅ Status check completed in ${duration}ms`);

        // Return response
        return res.json(
            createSuccessResponse({
                orderId,
                invoiceNumber,
                transactionStatus: statusResponse.transaction_status,
                orderStatus,
                paymentType: statusResponse.payment_type,
                grossAmount: statusResponse.gross_amount,
                fraudStatus: statusResponse.fraud_status,
            })
        );

    } catch (err) {
        const duration = Date.now() - startTime;
        error(`[${requestId}] ❌ Status check failed after ${duration}ms: ${err.message}`);

        // Handle Midtrans-specific errors
        if (err.httpStatusCode) {
            error(`[${requestId}] Midtrans API Error: ${err.httpStatusCode}`);

            if (err.httpStatusCode === 404) {
                return res.json(
                    createErrorResponse(
                        'TRANSACTION_NOT_FOUND',
                        'Transaction not found in Midtrans',
                        'Payment may not have been created yet'
                    ),
                    404
                );
            }

            if (err.httpStatusCode === 401) {
                return res.json(
                    createErrorResponse(
                        'MIDTRANS_AUTH_ERROR',
                        'Midtrans authentication failed',
                        'Please check server key configuration'
                    ),
                    500
                );
            }

            if (err.httpStatusCode >= 500) {
                return res.json(
                    createErrorResponse(
                        'MIDTRANS_SERVER_ERROR',
                        'Midtrans service unavailable',
                        'Please try again later'
                    ),
                    503
                );
            }
        }

        // Generic error
        return res.json(
            createErrorResponse(
                'STATUS_CHECK_FAILED',
                'Failed to check payment status',
                err.message
            ),
            500
        );
    }
}
