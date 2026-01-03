const { Client, Databases, Query } = require('node-appwrite');
const midtransClient = require('midtrans-client');

module.exports = async function (req, res) {
    const log = (msg) => console.log(`[CHECK-PAYMENT-STATUS] ${msg}`);
    const error = (msg) => console.error(`[CHECK-PAYMENT-STATUS] ❌ ${msg}`);

    try {
        log('🔍 Payment status check initiated');

        // Parse request body
        const { orderId } = req.body || {};

        if (!orderId) {
            error('Missing orderId in request body');
            return res.json({ error: 'orderId is required' }, 400);
        }

        log(`📦 Checking status for order: ${orderId}`);

        // Initialize Appwrite
        const client = new Client()
            .setEndpoint(process.env.APPWRITE_ENDPOINT)
            .setProject(process.env.APPWRITE_PROJECT_ID)
            .setKey(process.env.APPWRITE_API_KEY);

        const databases = new Databases(client);

        // Get order from database
        log('📖 Fetching order from database...');
        const order = await databases.getDocument(
            process.env.DATABASE_ID,
            process.env.ORDERS_COLLECTION_ID,
            orderId
        );

        if (!order) {
            error(`Order not found: ${orderId}`);
            return res.json({ error: 'Order not found' }, 404);
        }

        const invoiceNumber = order.invoice_number;
        log(`🧾 Invoice number: ${invoiceNumber}`);
        log(`📊 Current order status: ${order.order_status}`);

        // Initialize Midtrans Core API client
        const isProduction = process.env.MIDTRANS_IS_PRODUCTION === 'true';
        const coreApi = new midtransClient.CoreApi({
            isProduction,
            serverKey: process.env.MIDTRANS_SERVER_KEY,
            clientKey: process.env.MIDTRANS_CLIENT_KEY
        });

        log(`🔌 Querying Midtrans Transaction Status API for: ${invoiceNumber}`);

        // Get transaction status from Midtrans
        const statusResponse = await coreApi.transaction.status(invoiceNumber);

        log(`📥 Midtrans response received`);
        log(`   Transaction Status: ${statusResponse.transaction_status}`);
        log(`   Payment Type: ${statusResponse.payment_type}`);
        log(`   Gross Amount: ${statusResponse.gross_amount}`);
        log(`   Status Code: ${statusResponse.status_code}`);

        // Map Midtrans status to order status
        let orderStatus = order.order_status; // Keep current if no change needed
        const transactionStatus = statusResponse.transaction_status;
        const fraudStatus = statusResponse.fraud_status;

        if (transactionStatus === 'capture') {
            orderStatus = fraudStatus === 'accept' ? 'confirmed' : 'pending_payment';
        } else if (transactionStatus === 'settlement') {
            orderStatus = 'confirmed';
        } else if (transactionStatus === 'pending') {
            orderStatus = 'pending_payment';
        } else if (transactionStatus === 'deny' || transactionStatus === 'cancel' || transactionStatus === 'expire') {
            orderStatus = 'cancelled';
        }

        log(`🎯 Mapped order status: ${orderStatus}`);

        // Update order if status changed
        if (orderStatus !== order.order_status) {
            log(`💾 Updating order status from "${order.order_status}" to "${orderStatus}"`);

            await databases.updateDocument(
                process.env.DATABASE_ID,
                process.env.ORDERS_COLLECTION_ID,
                orderId,
                { order_status: orderStatus }
            );

            log('✅ Order status updated successfully');
        } else {
            log('ℹ️  Order status unchanged, no update needed');
        }

        // Return response
        return res.json({
            success: true,
            orderId,
            invoiceNumber,
            transactionStatus: statusResponse.transaction_status,
            orderStatus,
            paymentType: statusResponse.payment_type,
            grossAmount: statusResponse.gross_amount,
            updatedAt: new Date().toISOString()
        });

    } catch (err) {
        error(`Error: ${err.message}`);
        console.error(err);

        // Check if it's a Midtrans API error
        if (err.httpStatusCode) {
            error(`Midtrans API Error: ${err.httpStatusCode} - ${err.ApiResponse?.status_message}`);
            return res.json({
                error: 'Midtrans API error',
                message: err.ApiResponse?.status_message || err.message,
                statusCode: err.httpStatusCode
            }, 500);
        }

        return res.json({
            error: 'Internal server error',
            message: err.message
        }, 500);
    }
};
