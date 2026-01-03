# Midtrans Payment Gateway Integration Guide

## Overview
Integrate Midtrans payment gateway to enable customers to pay orders online. When payment is successful, the order status updates and tenant receives notification.

---

## Table of Contents
1. [Registration & Setup](#registration--setup)
2. [Architecture Overview](#architecture-overview)
3. [Implementation Steps](#implementation-steps)
4. [Webhook Configuration](#webhook-configuration)
5. [Notification Integration](#notification-integration)
6. [Testing](#testing)

---

## Registration & Setup

> [!IMPORTANT]
> **Production Implementation Required**
> 
> This guide focuses on **Production** setup for real transactions. We recommend testing in **Sandbox** first, then migrating to Production after verification.

### 1. Create Midtrans Account

#### Production Account (Required)
1. Go to https://midtrans.com
2. Click "Sign Up" → Choose **"Business Account"**
3. Fill in business information:
   - Business name
   - Business type (PT, CV, Individual, etc.)
   - NPWP (Tax ID)
   - Business address
   - Bank account details
4. Submit required documents:
   - ✅ KTP/Passport (Director/Owner)
   - ✅ NPWP
   - ✅ Business registration (if applicable)
   - ✅ Bank account statement
5. Wait for approval (1-3 business days)

#### Sandbox Account (For Testing)
1. Go to https://dashboard.sandbox.midtrans.com
2. Quick signup (no verification needed)
3. Use for development and testing

### 2. Get Production Credentials

After your **Production** account is **approved**:

1. Login to https://dashboard.midtrans.com (**NOT** sandbox)
2. Go to Settings → Access Keys
3. Copy your Production credentials:
   - **Server Key**: `Mid-server-xxxxxxxxxxxxx` ← Production (NO "SB-" prefix!)
   - **Client Key**: `Mid-client-xxxxxxxxxxxxx` ← Production

**Keep these secret!** Never commit to Git or expose in frontend.

#### Sandbox Credentials (For Testing)

1. Login to https://dashboard.sandbox.midtrans.com
2. Get Sandbox credentials:
   - **Server Key**: `SB-Mid-server-xxxxx` ← Sandbox (HAS "SB-" prefix)
   - **Client Key**: `SB-Mid-client-xxxxx` ← Sandbox

### 3. Enable Payment Methods

**In Production Dashboard:**
1. Go to Settings → Configuration
2. Enable payment methods (requires approval):
   - ✅ Credit/Debit Card (Visa, Mastercard, JCB)
   - ✅ GoPay (requires merchant approval)
   - ✅ ShopeePay (requires merchant approval)
   - ✅ Bank Transfer (BCA, Mandiri, BNI, BRI, Permata, CIMB)
   - ✅ QRIS
   - ✅ Alfamart/Indomaret (COD)
   - ✅ Kredivo, Akulaku (Paylater)

> [!WARNING]
> Some payment methods require **additional merchant verification** (e.g., GoPay, ShopeePay). Allow 1-2 weeks for approval.

### 4. Production Requirements Checklist

Before going live:
- [ ] Production account **approved** by Midtrans
- [ ] All required business documents submitted
- [ ] Production Server Key obtained (starts with `Mid-server-`)
- [ ] Production Client Key obtained (starts with `Mid-client-`)
- [ ] Payment methods enabled and approved
- [ ] Webhook URL configured (HTTPS required)
- [ ] Terms & Conditions agreed
- [ ] Settlement bank account verified

---

## Architecture Overview

```
┌─────────────────┐
│  Customer App   │
│  (Flutter)      │
└────────┬────────┘
         │ 1. Create order
         ▼
┌─────────────────────────────┐
│  Appwrite Database          │
│  - Orders collection        │
│  - status: "pending_payment"│
└────────┬────────────────────┘
         │ 2. Get order details
         ▼
┌─────────────────────────────┐
│  Appwrite Function          │
│  "create-midtrans-payment"  │
│  - Generate Snap Token      │
└────────┬────────────────────┘
         │ 3. Return Snap Token
         ▼
┌─────────────────┐
│  Customer App   │
│  - Open Midtrans│
│  - Complete Pay │
└────────┬────────┘
         │ 4. Payment success
         ▼
┌─────────────────────────────┐
│  Midtrans Server            │
│  - Send webhook             │
└────────┬────────────────────┘
         │ 5. Webhook notification
         ▼
┌─────────────────────────────┐
│  Appwrite Function          │
│  "midtrans-webhook-handler" │
│  - Verify signature         │
│  - Update order status      │
│  - Update order → "confirmed"
└────────┬────────────────────┘
         │ 6. Database update
         ▼
┌─────────────────────────────┐
│  Appwrite Realtime          │
│  - Emit "update" event      │
└────────┬────────────────────┘
         │ 7. Realtime subscription
         ▼
┌─────────────────┐
│  Tenant App     │
│  - Show notif   │
│  - Badge +1     │
└─────────────────┘
```

---

## Implementation Steps

### Phase 1: Backend Setup

#### 1. Create Appwrite Function: `create-midtrans-payment`

**Purpose:** Generate Midtrans Snap token for payment

**package.json:**
```json
{
  "name": "create-midtrans-payment",
  "version": "1.0.0",
  "dependencies": {
    "midtrans-client": "^1.3.1",
    "node-appwrite": "^11.0.0"
  }
}
```

**main.js:**
```javascript
const midtransClient = require('midtrans-client');
const { Client, Databases } = require('node-appwrite');

module.exports = async ({ req, res, log, error }) => {
  try {
    const { orderId } = JSON.parse(req.body);
    
    log(`Creating payment for order: ${orderId}`);
    
    // Initialize Appwrite
    const client = new Client()
      .setEndpoint(process.env.APPWRITE_ENDPOINT)
      .setProject(process.env.APPWRITE_PROJECT_ID)
      .setKey(process.env.APPWRITE_API_KEY);
    
    const databases = new Databases(client);
    
    // Get order from database
    const order = await databases.getDocument(
      process.env.DATABASE_ID,
      process.env.ORDERS_COLLECTION_ID,
      orderId
    );
    
    log(`Order found: ${order.order_number}, Amount: ${order.total_price}`);
    
    // Initialize Snap (PRODUCTION MODE)
    const snap = new midtransClient.Snap({
      isProduction: process.env.MIDTRANS_IS_PRODUCTION === 'true',
      serverKey: process.env.MIDTRANS_SERVER_KEY,
      clientKey: process.env.MIDTRANS_CLIENT_KEY,
    });
    
    log(`Midtrans mode: ${process.env.MIDTRANS_IS_PRODUCTION === 'true' ? 'PRODUCTION' : 'SANDBOX'}`);
    
    // Create transaction
    const parameter = {
      transaction_details: {
        order_id: order.order_number,
        gross_amount: order.total_price,
      },
      customer_details: {
        first_name: order.customer_name,
        phone: order.customer_phone,
        email: order.customer_email || null,
      },
      item_details: JSON.parse(order.items || '[]').map(item => ({
        id: item.productId,
        name: item.productName,
        price: item.price,
        quantity: item.quantity,
      })),
      callbacks: {
        finish: `myapp://payment/success?order_id=${orderId}`,
        error: `myapp://payment/error?order_id=${orderId}`,
        pending: `myapp://payment/pending?order_id=${orderId}`,
      },
    };
    
    const transaction = await snap.createTransaction(parameter);
    
    log(`✅ Snap token created: ${transaction.token}`);
    log(`Redirect URL: ${transaction.redirect_url}`);
    
    return res.json({
      success: true,
      snapToken: transaction.token,
      redirectUrl: transaction.redirect_url,
    });
  } catch (err) {
    error(`❌ Error creating payment: ${err.message}`);
    return res.json({ 
      success: false, 
      error: err.message 
    }, 500);
  }
};
```

**Environment Variables (Set in Appwrite Console):**
```
# Required - Appwrite
APPWRITE_ENDPOINT=https://cloud.appwrite.io/v1
APPWRITE_PROJECT_ID=your-project-id
APPWRITE_API_KEY=your-api-key
DATABASE_ID=your-database-id
ORDERS_COLLECTION_ID=your-orders-collection-id

# Required - Midtrans PRODUCTION
MIDTRANS_IS_PRODUCTION=true
MIDTRANS_SERVER_KEY=Mid-server-xxxxxxxxxxxxx
MIDTRANS_CLIENT_KEY=Mid-client-xxxxxxxxxxxxx

# For Sandbox Testing (comment out production keys above)
# MIDTRANS_IS_PRODUCTION=false
# MIDTRANS_SERVER_KEY=SB-Mid-server-xxxxxxxxxxxxx
# MIDTRANS_CLIENT_KEY=SB-Mid-client-xxxxxxxxxxxxx
```

#### 2. Create Appwrite Function: `midtrans-webhook-handler`

**Purpose:** Handle payment notifications from Midtrans (Production)

**package.json:**
```json
{
  "name": "midtrans-webhook-handler",
  "version": "1.0.0",
  "dependencies": {
    "node-appwrite": "^11.0.0"
  }
}
```

**main.js:**
```javascript
const crypto = require('crypto');
const { Client, Databases, Query } = require('node-appwrite');

module.exports = async ({ req, res, log, error }) => {
  try {
    const notification = JSON.parse(req.body);
    
    log('='.repeat(50));
    log(`📨 Webhook received from Midtrans`);
    log(`Order ID: ${notification.order_id}`);
    log(`Transaction Status: ${notification.transaction_status}`);
    log(`Fraud Status: ${notification.fraud_status || 'N/A'}`);
    log(`Payment Type: ${notification.payment_type}`);
    log('='.repeat(50));
    
    // CRITICAL: Verify webhook signature (PRODUCTION SECURITY)
    const isValid = verifySignature(notification, process.env.MIDTRANS_SERVER_KEY);
    if (!isValid) {
      error('❌ SECURITY: Invalid webhook signature!');
      return res.json({ error: 'Invalid signature' }, 401);
    }
    
    log('✅ Signature verified');
    
    // Initialize Appwrite
    const client = new Client()
      .setEndpoint(process.env.APPWRITE_ENDPOINT)
      .setProject(process.env.APPWRITE_PROJECT_ID)
      .setKey(process.env.APPWRITE_API_KEY);
    
    const databases = new Databases(client);
    
    // Determine order status based on Midtrans transaction status
    let orderStatus = 'pending_payment';
    let shouldNotify = false;
    
    const txStatus = notification.transaction_status;
    const fraudStatus = notification.fraud_status;
    
    if (txStatus === 'capture') {
      if (fraudStatus === 'accept') {
        orderStatus = 'confirmed';  // PAYMENT SUCCESS (Credit Card)
        shouldNotify = true;
        log('💰 Payment CAPTURED and ACCEPTED');
      } else if (fraudStatus === 'challenge') {
        orderStatus = 'pending_payment';  // Need manual review
        log('⚠️ Payment under FRAUD REVIEW');
      }
    } else if (txStatus === 'settlement') {
      orderStatus = 'confirmed';  // PAYMENT SUCCESS (Non-CC)
      shouldNotify = true;
      log('💰 Payment SETTLED');
    } else if (txStatus === 'pending') {
      orderStatus = 'pending_payment';
      log('⏳ Payment PENDING');
    } else if (txStatus === 'deny' || txStatus === 'expire' || txStatus === 'cancel') {
      orderStatus = 'cancelled';
      log(`❌ Payment ${txStatus.toUpperCase()}`);
    } else if (txStatus === 'refund') {
      orderStatus = 'cancelled';
      log('💸 Payment REFUNDED');
    }
    
    // Find order by order_number
    const orders = await databases.listDocuments(
      process.env.DATABASE_ID,
      process.env.ORDERS_COLLECTION_ID,
      [
        Query.equal('order_number', notification.order_id),
      ]
    );
    
    if (orders.total === 0) {
      error(`❌ Order not found: ${notification.order_id}`);
      return res.json({ error: 'Order not found' }, 404);
    }
    
    const order = orders.documents[0];
    
    // Validate amount (SECURITY: Prevent amount manipulation)
    const expectedAmount = parseInt(order.total_price);
    const paidAmount = parseInt(notification.gross_amount);
    
    if (expectedAmount !== paidAmount) {
      error(`❌ SECURITY: Amount mismatch! Expected: ${expectedAmount}, Paid: ${paidAmount}`);
      return res.json({ error: 'Amount mismatch' }, 400);
    }
    
    log(`✅ Amount validated: Rp ${paidAmount}`);
    
    // Update order status in database
    await databases.updateDocument(
      process.env.DATABASE_ID,
      process.env.ORDERS_COLLECTION_ID,
      order.$id,
      { 
        status: orderStatus,
        payment_type: notification.payment_type,
        payment_status: txStatus,
      }
    );
    
    log(`✅ Order ${notification.order_id} updated to: ${orderStatus}`);
    
    if (shouldNotify) {
      log(`🔔 Notification will be triggered via Appwrite Realtime`);
    }
    
    // Return success to Midtrans
    return res.json({ 
      success: true, 
      status: orderStatus,
      message: 'Webhook processed successfully'
    });
    
  } catch (err) {
    error(`❌ Webhook processing error: ${err.message}`);
    error(err.stack);
    return res.json({ 
      success: false, 
      error: err.message 
    }, 500);
  }
};

/**
 * Verify Midtrans webhook signature
 * CRITICAL for production security
 */
function verifySignature(notification, serverKey) {
  const orderId = notification.order_id;
  const statusCode = notification.status_code;
  const grossAmount = notification.gross_amount;
  const signatureKey = notification.signature_key;
  
  // Create signature hash
  const string = `${orderId}${statusCode}${grossAmount}${serverKey}`;
  const hash = crypto.createHash('sha512').update(string).digest('hex');
  
  return hash === signatureKey;
}
```

**Environment Variables:**
Same as `create-midtrans-payment` function above.

---

### Phase 2: Frontend Integration

#### 1. Add Midtrans Dependency

**pubspec.yaml:**
```yaml
dependencies:
  midtrans_sdk: ^0.2.0
  webview_flutter: ^4.4.2
```

#### 2. Create Payment Service

**lib/features/payment/services/midtrans_service.dart:**
```dart
class MidtransService {
  Future<String> createPayment(String orderId) async {
    // Call Appwrite function to get Snap token
    final functions = ref.read(appwriteFunctionsProvider);
    
    final execution = await functions.createExecution(
      functionId: 'create-midtrans-payment',
      body: jsonEncode({'orderId': orderId}),
    );
    
    final response = jsonDecode(execution.response);
    return response['snapToken'];
  }
  
  Future<void> openPayment(String snapToken) async {
    // Open Midtrans payment page
    // Options:
    // 1. Use WebView
    // 2. Use Midtrans SDK
    // 3. Deep link to app
  }
}
```

---

### Phase 3: Notification Integration

#### Update Badge Logic to Count Pending Orders

**Current:** Badge = unread notifications  
**New:** Badge = pending orders count

**lib/features/notifications/providers/notification_provider.dart:**
```dart
// Add method to fetch pending orders count
Future<int> fetchPendingOrdersCount(String tenantId) async {
  final databases = ref.read(appwriteDatabasesProvider);
  
  final documents = await databases.listDocuments(
    databaseId: AppwriteConfig.databaseId,
    collectionId: AppwriteConfig.ordersCollectionId,
    queries: [
      Query.equal('tenant_id', tenantId),
      Query.equal('status', ['pending', 'confirmed', 'preparing']),
    ],
  );
  
  return documents.total;
}
```

#### Subscribe to Order Status Updates

**Modification:** Listen for both `create` and `update` events

```dart
_subscription!.stream.listen((response) {
  final isCreateEvent = response.events.any((e) => e.contains('.create'));
  final isUpdateEvent = response.events.any((e) => e.contains('.update'));
  
  if (isCreateEvent || isUpdateEvent) {
    // Refresh pending orders count
    _updatePendingCount();
    
    // Show notification if new order or payment confirmed
    if (isCreateEvent || (isUpdateEvent && order.status == 'confirmed')) {
      _showNotification(order);
    }
  }
});
```

---

## Webhook Configuration

> [!IMPORTANT]
> **Production Webhooks MUST use HTTPS**
> 
> HTTP webhooks will be rejected by Midtrans in production mode.

### Setup Production Webhook URL

1. **Get your Appwrite function execution URL:**
   - Go to Appwrite Console → Functions
   - Select `midtrans-webhook-handler`
   - Copy the execution endpoint:
     ```
     https://cloud.appwrite.io/v1/functions/[FUNCTION_ID]/executions
     ```
   - Replace `[FUNCTION_ID]` with actual function ID

2. **Configure in Midtrans Production Dashboard:**
   - Login to https://dashboard.midtrans.com (Production)
   - Go to Settings → Configuration
   - Find "Payment Notification URL"
   - Paste your Appwrite function URL
   - Save changes

3. **Enable notification types:**
   - ✅ HTTP Notification (POST)
   - ✅ Email Notification (optional)

### Verify Webhook Setup

Test your webhook manually:
```bash
# Test webhook with curl (use Midtrans test notification)
curl -X POST https://cloud.appwrite.io/v1/functions/YOUR_FUNCTION_ID/executions \
  -H "Content-Type: application/json" \
  -d '{
    "order_id": "TEST-ORDER-001",
    "transaction_status": "settlement",
    "fraud_status": "accept",
    "status_code": "200",
    "gross_amount": "100000",
    "signature_key": "..."
  }'
```

Expected response: `{"success": true, "status": "confirmed"}`

---

## Order Status Flow

```
Customer Places Order
         ↓
    [pending_payment] ← Order created, waiting payment
         ↓
Customer Pays via Midtrans
         ↓
    [confirmed] ← Payment success, tenant gets notification
         ↓
Tenant Prepares Order
         ↓
    [preparing]
         ↓
    [ready]
         ↓
Customer Picks Up
         ↓
    [completed]
```

---

## Testing

> [!WARNING]
> **Always test in Sandbox FIRST before going to Production**
> 
> Use sandbox credentials to avoid accidental real charges during development.

### Phase 1: Sandbox Testing

**Setup Sandbox Environment:**
1. Set environment variables to Sandbox:
   ```
   MIDTRANS_IS_PRODUCTION=false
   MIDTRANS_SERVER_KEY=SB-Mid-server-xxxxx
   MIDTRANS_CLIENT_KEY=SB-Mid-client-xxxxx
   ```
2. Configure webhook URL in Sandbox dashboard
3. Deploy functions to Appwrite

**Test Cards (Sandbox):**
- ✅ Success: `4811 1111 1111 1114`
- ❌ Failure: `4911 1111 1111 1113`
- ⏳ Pending: `4711 1111 1111 1111`
- CVV: `123`
- Expiry: Any future date (e.g., `12/25`)

**Test E-Wallets (Sandbox):**
- GoPay: Open simulator in Midtrans Sandbox dashboard
- ShopeePay: Same as GoPay
- QRIS: Use simulator

**Test Bank Transfer:**
- Use virtual account simulator in dashboard
- Auto-approve after generation

### Phase 2: Production Testing

**After Sandbox testing is 100% working:**

1. **Update to Production Credentials:**
   ```
   MIDTRANS_IS_PRODUCTION=true
   MIDTRANS_SERVER_KEY=Mid-server-xxxxx  (Production)
   MIDTRANS_CLIENT_KEY=Mid-client-xxxxx  (Production)
   ```

2. **Update Webhook URL:**
   - Change from Sandbox dashboard to Production dashboard

3. **Test with Small Real Transaction:**
   - Create test order with minimum amount (e.g., Rp 10,000)
   - Use your own card/e-wallet
   - Verify payment, webhook, and notification flow
   - **IMPORTANT:** This will charge real money!

4. **Monitor Production Transactions:**
   - Check Midtrans Production dashboard
   - Verify settlements
   - Monitor for errors

### Testing Checklist

**Sandbox (Must complete ALL before production):**
- [ ] Create order with payment
- [ ] Generate Snap token successfully
- [ ] Open Midtrans payment page
- [ ] Complete payment with test card
- [ ] Webhook received and verified
- [ ] Order status updated to `confirmed`
- [ ] Tenant receives notification
- [ ] Badge count increases correctly
- [ ] Test payment failure scenarios
- [ ] Test expired payment
- [ ] Test cancelled payment

**Production (After sandbox passes):**
- [ ] Production credentials configured
- [ ] Webhook URL updated to production
- [ ] Small test transaction successful
- [ ] Real payment received in bank account
- [ ] Settlement working correctly
- [ ] All payment methods tested
- [ ] Error handling verified

---

## Environment Variables

### Appwrite Function Configuration

Set these in **Appwrite Console → Functions → Settings → Environment Variables**:

**Production Setup:**
```bash
# Appwrite
APPWRITE_ENDPOINT=https://cloud.appwrite.io/v1
APPWRITE_PROJECT_ID=your-project-id
APPWRITE_API_KEY=your-api-key
DATABASE_ID=your-database-id
ORDERS_COLLECTION_ID=your-orders-collection-id

# Midtrans PRODUCTION
MIDTRANS_IS_PRODUCTION=true
MIDTRANS_SERVER_KEY=Mid-server-xxxxxxxxxxxxx
MIDTRANS_CLIENT_KEY=Mid-client-xxxxxxxxxxxxx
```

**Sandbox Setup (for testing):**
```bash
# Same Appwrite config as above

# Midtrans SANDBOX
MIDTRANS_IS_PRODUCTION=false
MIDTRANS_SERVER_KEY=SB-Mid-server-xxxxxxxxxxxxx
MIDTRANS_CLIENT_KEY=SB-Mid-client-xxxxxxxxxxxxx
```

### Flutter App Configuration

**lib/core/config/midtrans_config.dart:**
```dart
class MidtransConfig {
  // Use PRODUCTION client key
  static const clientKey = 'Mid-client-xxxxxxxxxxxxx';
  
  // For sandbox testing, use:
  // static const clientKey = 'SB-Mid-client-xxxxxxxxxxxxx';
  
  static const isProduction = true;
}
```

> [!CAUTION]
> **NEVER commit Server Keys to Git!**
> 
> - Server keys give full access to your Midtrans account
> - Only store in Appwrite environment variables
> - Client keys are safe to use in frontend (read-only)

---

## Security Considerations

1. **Verify Webhook Signature** - Always validate Midtrans signature
2. **HTTPS Only** - Use HTTPS for webhook URL
3. **Server Key** - Never expose server key in frontend
4. **Client Key** - Safe to use in frontend (public)
5. **Order Validation** - Validate order amount matches payment amount

---

## Costs

### Midtrans Transaction Fees

**Standard:**
- Credit Card: 2.9% + Rp 2,000
- GoPay/ShopeePay: 2%
- QRIS: 0.7%
- Bank Transfer: Rp 4,000 flat

**Note:** Fees may vary, check Midtrans website for latest rates.

---

## Support

- Midtrans Docs: https://docs.midtrans.com
- Midtrans Support: support@midtrans.com
- API Reference: https://api-docs.midtrans.com
