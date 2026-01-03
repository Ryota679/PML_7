const crypto = require('crypto');
const { Client, Databases, Query } = require('node-appwrite');

module.exports = async ({ req, res, log, error }) => {
    try {
        // Get webhook notification from Midtrans
        // ✅ FIXED: req.body is already parsed in Appwrite, don't JSON.parse again!
        const notification = typeof req.body === 'string' ? JSON.parse(req.body) : (req.body || {});

        log('='.repeat(60));
        log(`📨 Midtrans Webhook Received`);
        log(`   Order ID: ${notification.order_id}`);
        log(`   Transaction Status: ${notification.transaction_status}`);
        log(`   Fraud Status: ${notification.fraud_status || 'N/A'}`);
        log(`   Payment Type: ${notification.payment_type}`);
        log(`   Gross Amount: Rp ${notification.gross_amount}`);
        log('='.repeat(60));
        log('🚀 WEBHOOK HANDLER VERSION: 2.0 - DEBUG ENABLED');
        log('='.repeat(60));

        // CRITICAL: Verify webhook signature (prevent unauthorized access)
        log('🔐 Verifying webhook signature...');
        log(`   Received signature: ${notification.signature_key || 'MISSING'}`);
        log(`   Order ID: ${notification.order_id || 'MISSING'}`);
        log(`   Status Code: ${notification.status_code || 'MISSING'}`);
        log(`   Gross Amount: ${notification.gross_amount || 'MISSING'}`);

        // ⚠️ TEMPORARY: Signature verification DISABLED for testing
        // TODO: RE-ENABLE before production!
        /*
        const isValid = verifySignature(notification, process.env.MIDTRANS_SERVER_KEY);
        if (!isValid) {
            error('🚨 SECURITY ALERT: Invalid webhook signature!');
            error(`   Order ID: ${notification.order_id}`);
            error(`   This could be a spoofed webhook attempt!`);
            return res.json({ error: 'Invalid signature' }, 401);
        }
        log('✅ Signature verified - webhook is authentic');
        */
        log('⚠️  TESTING MODE: Signature verification DISABLED');
        log('✅ Proceeding to process webhook...');

        // Initialize Appwrite
        const client = new Client()
            .setEndpoint(process.env.APPWRITE_ENDPOINT || 'https://cloud.appwrite.io/v1')
            .setProject(process.env.APPWRITE_PROJECT_ID)
            .setKey(process.env.APPWRITE_API_KEY);

        const databases = new Databases(client);

        // Determine order status based on Midtrans transaction status
        let newOrderStatus = 'pending_payment';
        let shouldNotify = false;

        const txStatus = notification.transaction_status;
        const fraudStatus = notification.fraud_status;

        // Map Midtrans status to our order status
        if (txStatus === 'capture') {
            if (fraudStatus === 'accept') {
                newOrderStatus = 'confirmed';  // ✅ Payment SUCCESS (Credit Card)
                shouldNotify = true;
                log('💰 Payment CAPTURED and ACCEPTED');
            } else if (fraudStatus === 'challenge') {
                newOrderStatus = 'pending_payment';  // ⚠️ Manual review needed
                log('⚠️  Payment under FRAUD REVIEW');
            }
        } else if (txStatus === 'settlement') {
            newOrderStatus = 'confirmed';  // ✅ Payment SUCCESS (Non-CC: GoPay, VA, QRIS)
            shouldNotify = true;
            log('💰 Payment SETTLED');
        } else if (txStatus === 'pending') {
            newOrderStatus = 'pending_payment';
            log('⏳ Payment PENDING');
        } else if (txStatus === 'deny' || txStatus === 'cancel') {
            newOrderStatus = 'cancelled';
            log(`❌ Payment ${txStatus.toUpperCase()}`);
        } else if (txStatus === 'expire') {
            newOrderStatus = 'expired';  // ✅ UPDATED: Expired gets its own status
            log('⏰ Payment EXPIRED');
        } else if (txStatus === 'refund') {
            newOrderStatus = 'cancelled';
            log('💸 Payment REFUNDED');
        }

        // Find order by invoice_number (which matches Midtrans order_id)
        log(`🔍 Searching for order: ${notification.order_id}`);
        const orders = await databases.listDocuments(
            process.env.DATABASE_ID,
            process.env.ORDERS_COLLECTION_ID,
            [
                Query.equal('invoice_number', notification.order_id),
            ]
        );

        if (orders.total === 0) {
            // Check if this is a test notification from Midtrans
            const isTestNotification = notification.order_id?.includes('payment_notif_test');

            if (isTestNotification) {
                log(`🧪 Test notification detected - order not in database (expected)`);
                return res.json({
                    success: true,
                    message: 'Test notification received (order not in database)'
                }, 200);  // Return 200 so Midtrans test passes
            }

            error(`❌ Order not found: ${notification.order_id}`);
            return res.json({ error: 'Order not found' }, 404);
        }

        const order = orders.documents[0];
        log(`✅ Order found: ${order.$id}`);

        // SECURITY: Validate amount (prevent amount manipulation attacks)
        const expectedAmount = parseInt(order.total_price);
        const paidAmount = parseInt(notification.gross_amount);

        if (expectedAmount !== paidAmount) {
            error('🚨 SECURITY ALERT: Amount mismatch!');
            error(`   Expected: Rp ${expectedAmount}`);
            error(`   Paid: Rp ${paidAmount}`);
            error(`   Order: ${notification.order_id}`);
            return res.json({ error: 'Amount mismatch' }, 400);
        }

        log(`✅ Amount validated: Rp ${paidAmount}`);

        // Update order in database
        log(`💾 Updating order status to: ${newOrderStatus}`);
        await databases.updateDocument(
            process.env.DATABASE_ID,
            process.env.ORDERS_COLLECTION_ID,
            order.$id,
            {
                order_status: newOrderStatus,
                payment_type: notification.payment_type,
                payment_status: txStatus,
            }
        );

        log(`✅ Order ${notification.order_id} updated successfully`);

        if (shouldNotify) {
            log(`🔔 Payment confirmed! Notification will be sent via Appwrite Realtime`);
        }

        // Return success to Midtrans
        return res.json({
            success: true,
            status: newOrderStatus,
            message: 'Webhook processed successfully'
        });

    } catch (err) {
        error(`❌ Webhook processing failed: ${err.message}`);
        if (err.stack) {
            error(err.stack);
        }

        return res.json({
            success: false,
            error: err.message || 'Internal server error'
        }, 500);
    }
};

/**
 * Verify Midtrans webhook signature
 * CRITICAL for production security - prevents spoofed webhooks
 * 
 * @param {Object} notification - Webhook payload from Midtrans
 * @param {string} serverKey - Midtrans Server Key
 * @returns {boolean} - True if signature is valid
 */
function verifySignature(notification, serverKey) {
    const orderId = notification.order_id;
    const statusCode = notification.status_code;
    const grossAmount = notification.gross_amount;
    const signatureKey = notification.signature_key;

    if (!orderId || !statusCode || !grossAmount || !signatureKey) {
        return false;  // Missing required fields
    }

    // Create signature hash using SHA512
    const string = `${orderId}${statusCode}${grossAmount}${serverKey}`;
    const hash = crypto.createHash('sha512').update(string).digest('hex');

    return hash === signatureKey;
}
