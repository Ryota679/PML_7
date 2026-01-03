# 🌐 Web + Mobile Full Ordering System - Implementation Guide

**Project:** Kantin QR-Order App  
**Version:** 2.0 - Web Ordering Integration  
**Status:** Ready for Implementation  
**Timeline:** Tier 1: 1 week | Tier 2: 2 weeks (after Midtrans approval)  
**Last Updated:** 21 December 2025

---

## ⚠️ DEPLOYMENT STRATEGY - 2 TIERS

> [!IMPORTANT]
> **This guide supports STAGED DEPLOYMENT for Midtrans verification process**

### **🎯 Tier 1: STAGING (Without Payment) - CURRENT PHASE**

**Purpose:** Deploy for Midtrans verification/demo

**Timeline:** 1 week

**Features Included:**
- ✅ Web version (browsing menu)
- ✅ QR Code with URLs
- ✅ Cart system with persistence
- ✅ Mock checkout (no real payment)
- ✅ Order creation (manual payment confirmation)
- ✅ Order tracking

**Features EXCLUDED (Marked with 🔒 TIER 2):**
- ❌ Midtrans payment integration
- ❌ Payment webhook function
- ❌ Automatic payment status updates

**Deployment:** Vercel (staging URL for Midtrans review)

---

### **🚀 Tier 2: PRODUCTION (With Payment) - AFTER MIDTRANS APPROVAL**

**Purpose:** Full production deployment

**Prerequisites:**
- ✅ Midtrans account verified
- ✅ Midtrans API keys obtained

**Additional Features:**
- ✅ Real Midtrans payment integration
- ✅ Payment webhook function (Appwrite Slot 4)
- ✅ Automatic payment confirmation
- ✅ Email notifications

---

## 📋 Overview

This guide implements a hybrid ordering system where customers can order via **web browser OR mobile app** using QR codes. No app download required for guests.

### Key Features

- ✅ Smart QR codes (works with phone camera)
- ✅ Full web ordering (no app required)
- ✅ Cart persistence (survives refresh)
- ✅ Dual invoice tracking (ours + Midtrans)
- ✅ Midtrans payment integration
- ✅ Order tracking (web + mobile)
- ✅ Deep linking (QR → app if installed)

### Architecture

```
Customer scans QR → Smart URL detected
                           ↓
              ┌────────────┴────────────┐
              │                         │
         Has app?                  No app?
              │                         │
              ▼                         ▼
      Deep link to app          Open in browser
      (instant menu)            (web ordering)
              │                         │
              └────────────┬────────────┘
                           ▼
                   Add to cart
                   Checkout
                   Payment (Midtrans)
                   Track order
```

---

## 📅 Implementation Schedule

### **TIER 1: STAGING** - ✅ **COMPLETE!**

| Day | Focus | Status |
|-----|-------|--------|
| **Day 1** | Database schema | ✅ **DONE** |
| **Day 2** | Invoice + Cart services | ✅ **DONE** |
| **Day 3-4** | Mobile app updates (QR) | ✅ **DONE** |
| **Day 5-6** | Web version (all pages) | ✅ **DONE** |
| **Day 7** | Deploy to Vercel + Testing | ✅ **DONE** |

**🎉 Result:** https://kantin-web-ordering.vercel.app/ LIVE!

**Completed Features:**
- ✅ 5 web pages (landing, menu, cart, checkout, tracking)
- ✅ Dark theme with category filter
- ✅ Product detail modal with quantity selector
- ✅ Cart persistence with localStorage
- ✅ Invoice generation with retry mechanism
- ✅ QR code integration
- ✅ Stock tracking (null = no limit, 0 = sold out)
- ✅ Mobile responsive
- ✅ Appwrite security configured

### **TIER 2: PRODUCTION (After Midtrans Approval)** - 2 Weeks

| Phase | Duration | Focus |
|-------|----------|-------|
| **Phase 1** | 2 days | Payment webhook function |
| **Phase 2** | 2 days | Midtrans integration (mobile + web) |
| **Phase 3** | 2 days | Payment testing (sandbox) |
| **Phase 4** | 1 day | Production deployment |

> [!NOTE]
> Phases below are marked with **🔒 TIER 2** for payment-related steps that should be skipped in staging deployment.

---

## ⚙️ Prerequisites

Before starting, ensure you have:

- [ ] Midtrans account (sandbox + production)
- [ ] Vercel account (for web hosting)
- [ ] Domain name (optional, can use free `.vercel.app`)
- [ ] Access to Appwrite console
- [ ] Flutter 3.9+ installed
- [ ] Git for version control

---

# PHASE 1: Database Setup

## 🎯 TIER 1 VERSION (STAGING)

**Duration:** 1 day  
**Goal:** Setup database for orders WITHOUT payment integration

**Skip to:** [Tier 1 Database Setup](#tier-1-database-setup)

---

## 🔒 TIER 2 VERSION (PRODUCTION)

**Duration:** 2 days  
**Goal:** Add payment webhook function (AFTER Midtrans approval)

**⚠️ SKIP THIS SECTION FOR STAGING DEPLOYMENT**

---

## 🔒 TIER 2: Payment Webhook Function

> [!CAUTION]
> **SKIP THIS SECTION** if deploying Tier 1 (staging). Jump to [Tier 1 Database Setup](#tier-1-database-setup)

### Prerequisites
- Midtrans account verified ✅
- Midtrans API keys obtained ✅
- Ready to use Appwrite Function Slot 4 ✅

*(Full payment webhook implementation code remains here for Tier 2 - collapsed for brevity)*

<details>
<summary>Click to expand Tier 2: Payment Webhook Function Code</summary>

### Step 2.1: Create Function Structure

**Command:**
```bash
mkdir -p functions/payment-webhook/src
cd functions/payment-webhook
```

**Create files:**

1. `functions/payment-webhook/package.json`
2. `functions/payment-webhook/src/main.js`
3. Deploy to Appwrite
4. Configure Midtrans webhook URL

*(Refer to original section for full code)*

</details>

---

## 🎯 TIER 1: Database Setup

### Day 1: Database Schema Updates (Simplified)

### Step 1.1: Update `orders` Collection (Tier 1 - Simplified)

**Action:** Add new fields via Appwrite Console

1. Navigate to: **Appwrite Console → Databases → Your Database → `orders` collection → Attributes**

2. Click **"Add Attribute"** for each field below:

#### **Required for Tier 1 (Staging):**

| Field Name | Type | Size | Required | Default | Indexed |
|------------|------|------|----------|---------|---------|
| `invoice_number` | String | 50 | Yes | - | ✅ Unique |
| `tenant_code` | String | 10 | No | - | ✅ |
| `table_number` | String | 10 | Yes | - | ❌ |
| `customer_notes` | String | 500 | No | null | ❌ |
| `total_amount` | Integer | - | Yes | - | ❌ |
| `order_status` | String | 20 | No | "pending" | ❌ |

**Valid `order_status` values for Tier 1:**
- `pending` - Order created, awaiting payment confirmation (manual)
- `paid` - Payment confirmed by tenant/admin (manual)
- `preparing` - Kitchen is preparing
- `ready` - Ready to serve
- `completed` - Customer received order

#### **🔒 Optional - Add in Tier 2 (After Midtrans Approval):**

| Field Name | Type | Size | Required | Default | Note |
|------------|------|------|----------|---------|------|
| `midtrans_order_id` | String | 100 | No | null | 🔒 Tier 2 |
| `payment_method` | String | 50 | No | "cash" | 🔒 Tier 2 |
| `payment_status` | String | 20 | No | "pending" | 🔒 Tier 2 |

> [!NOTE]
> For Tier 1, skip payment-specific fields. Orders will be created with manual payment confirmation by tenant.

3. **Create Indexes:**
   - Navigate to **Indexes** tab
   - Click **"Add Index"**
   - Create indexes:
     - `idx_invoice`: Field = `invoice_number`, Type = ASC, Unique = Yes
     - `idx_tenant_code`: Field = `tenant_code`, Type = ASC
     - 🔒 `idx_midtrans`: (Skip in Tier 1, add in Tier 2)

4. **Update Permissions:**
   - Navigate to **Settings → Permissions**
   - Ensure these permissions exist:
     ```
     Create: Users (customers can create orders)
     Read: Users (customers can read their orders)
     Update: Any (tenant can update order status)
     ```

---

### Step 1.2: Test Database Changes

**Verify via Appwrite Console:**

1. Go to **Documents** tab in `orders` collection
2. Click **"Add Document"**
3. Fill in Tier 1 fields:
   ```json
   {
     "invoice_number": "INV-20251221-TEST123",
     "tenant_code": "Q8L2PH",
     "table_number": "5",
     "customer_notes": "Pedas sedang",
     "total_amount": 50000,
     "order_status": "pending"
   }
   ```
4. Ensure no errors

✅ **Checkpoint:** Essential fields created, indexes working

---

## 🔒 TIER 2: Midtrans Payment Webhook Function

> [!CAUTION]
> **SKIP THIS ENTIRE SECTION FOR TIER 1 (STAGING)**
> 
> This section is only needed AFTER Midtrans approval. For staging, orders will use manual payment confirmation by tenant.

<details>
<summary>🔒 Click to expand Tier 2: Payment Webhook Implementation</summary>

### Step 2.1: Create Function Structure

**Command:**
```bash
mkdir -p functions/payment-webhook/src
cd functions/payment-webhook
```

**Create files:**

1. `functions/payment-webhook/package.json`:
```json
{
  "name": "payment-webhook",
  "version": "1.0.0",
  "type": "module",
  "scripts": {
    "start": "node src/main.js"
  },
  "dependencies": {
    "node-appwrite": "^12.0.0",
    "crypto": "^1.0.1"
  }
}
```

2. `functions/payment-webhook/src/main.js`:
```javascript
import { Client, Databases, Query } from 'node-appwrite';
import crypto from 'crypto';

export default async ({ req, res, log, error }) => {
  log('🔔 Payment webhook triggered');
  
  try {
    // Parse Midtrans notification
    const notification = JSON.parse(req.bodyRaw);
    
    log('Notification data:', JSON.stringify(notification, null, 2));
    
    // Validate signature
    const serverKey = process.env.MIDTRANS_SERVER_KEY;
    const signatureKey = crypto.createHash('sha512')
      .update(`${notification.order_id}${notification.status_code}${notification.gross_amount}${serverKey}`)
      .digest('hex');
    
    if (signatureKey !== notification.signature_key) {
      error('Invalid signature');
      return res.json({ success: false, message: 'Invalid signature' }, 403);
    }
    
    log('✅ Signature validated');
    
    // Initialize Appwrite
    const client = new Client()
      .setEndpoint(process.env.APPWRITE_ENDPOINT)
      .setProject(process.env.APPWRITE_PROJECT_ID)
      .setKey(process.env.APPWRITE_API_KEY);
    
    const databases = new Databases(client);
    
    // Find order by invoice number
    const ordersResponse = await databases.listDocuments(
      process.env.APPWRITE_DATABASE_ID,
      process.env.APPWRITE_ORDERS_COLLECTION_ID,
      [
        Query.equal('invoice_number', notification.order_id),
        Query.limit(1)
      ]
    );
    
    if (ordersResponse.documents.length === 0) {
      error(`Order not found: ${notification.order_id}`);
      return res.json({ success: false, message: 'Order not found' }, 404);
    }
    
    const order = ordersResponse.documents[0];
    log(`Found order: ${order.$id}`);
    
    // Determine payment status
    let paymentStatus = 'pending';
    
    if (notification.transaction_status === 'capture' || 
        notification.transaction_status === 'settlement') {
      paymentStatus = 'paid';
      log('✅ Payment successful');
    } else if (notification.transaction_status === 'pending') {
      paymentStatus = 'pending';
      log('⏳ Payment pending');
    } else if (notification.transaction_status === 'deny' || 
               notification.transaction_status === 'expire' || 
               notification.transaction_status === 'cancel') {
      paymentStatus = 'failed';
      log('❌ Payment failed');
    }
    
    // Update order in database
    await databases.updateDocument(
      process.env.APPWRITE_DATABASE_ID,
      process.env.APPWRITE_ORDERS_COLLECTION_ID,
      order.$id,
      {
        payment_status: paymentStatus,
        midtrans_order_id: notification.transaction_id || notification.order_id,
        payment_method: notification.payment_type || 'midtrans',
      }
    );
    
    log(`✅ Order updated: ${order.$id} → ${paymentStatus}`);
    
    // TODO: Send email notification to customer
    // (implement using Appwrite Messaging in future iteration)
    
    return res.json({ 
      success: true, 
      message: 'Payment notification processed',
      order_id: order.$id,
      status: paymentStatus
    });
    
  } catch (err) {
    error('Error processing webhook:', err.message);
    return res.json({ success: false, message: err.message }, 500);
  }
};
```

3. `functions/payment-webhook/.env.example`:
```bash
MIDTRANS_SERVER_KEY=your_server_key_here
APPWRITE_ENDPOINT=https://cloud.appwrite.io/v1
APPWRITE_PROJECT_ID=your_project_id
APPWRITE_API_KEY=your_api_key
APPWRITE_DATABASE_ID=your_database_id
APPWRITE_ORDERS_COLLECTION_ID=orders
```

---

### Step 2.2: Deploy Function to Appwrite

**Via Appwrite Console:**

1. Go to **Functions** → **Create Function**
2. Settings:
   - Name: `payment-webhook`
   - Runtime: `Node.js 18.x`
   - Entrypoint: `src/main.js`
   - Execute Access: `Anyone` (webhook must be public)

3. **Upload code:**
   ```bash
   cd functions/payment-webhook
   npm install
   tar -czf function.tar.gz .
   ```
   
4. Upload `function.tar.gz` in Appwrite Console → Functions → payment-webhook → Deployments

5. **Set Environment Variables:**
   - Navigate to **Settings → Variables**
   - Add all vars from `.env.example`
   - Get values from:
     - Midtrans Dashboard
     - Appwrite Console → Settings

6. **Get Webhook URL:**
   - Copy from: Functions → payment-webhook → **Execute URL**
   - Format: `https://cloud.appwrite.io/v1/functions/{functionId}/executions`

---

### Step 2.3: Configure Midtrans Webhook

1. **Midtrans Dashboard → Settings → Configuration**

2. **Payment Notification URL:** 
   - Paste Appwrite function execute URL
   - Example: `https://cloud.appwrite.io/v1/functions/abc123/executions`

3. **Finish Redirect URL:**
   - `https://kantin.app/payment-success` (or your domain)

4. **Error/Pending URLs:**
   - Error: `https://kantin.app/payment-failed`
   - Pending: `https://kantin.app/payment-pending`

5. **Save configuration**

---

### Step 2.4: Test Payment Webhook

**Manual Test:**

1. **Trigger test in Appwrite Console:**
   - Functions → payment-webhook → **Execute**
   - Body (JSON):
   ```json
   {
     "order_id": "INV-20251221-TEST123",
     "transaction_status": "settlement",
     "transaction_id": "MT-TEST-789",
     "gross_amount": "100000",
     "status_code": "200",
     "signature_key": "calculated_hash_here",
     "payment_type": "gopay"
   }
   ```

2. **Check Logs:**
   - View execution logs
   - Verify no errors
   - Check if order updated in database

✅ **Checkpoint:** Function deployed, webhook configured, test successful

---

# PHASE 2: Invoice System + Core Services

**Duration:** 3 days  
**Goal:** Build invoice generation and cart persistence services

---

## Day 3: Invoice Service

### Step 3.1: Create Invoice Generator

**File:** `lib/core/services/invoice_service.dart`

```dart
import 'dart:math';
import 'package:intl/intl.dart';

class InvoiceService {
  /// Generate unique invoice number
  /// Format: INV-YYYYMMDD-XXXXXXX
  static String generateInvoiceNumber() {
    final now = DateTime.now();
    final dateStr = DateFormat('yyyyMMdd').format(now);
    final random = _generateRandomCode(7);
    
    return 'INV-$dateStr-$random';
  }
  
  /// Generate random alphanumeric code
  static String _generateRandomCode(int length) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random.secure();
    return List.generate(
      length, 
      (_) => chars[random.nextInt(chars.length)]
    ).join();
  }
  
  /// Validate invoice format
  static bool isValidInvoice(String invoice) {
    final regex = RegExp(r'^INV-\d{8}-[A-Z0-9]{7}$');
    return regex.hasMatch(invoice);
  }
  
  /// Check if invoice is ours or Midtrans reference
  static bool isOurInvoice(String query) {
    return query.startsWith('INV-');
  }
}
```

---

### Step 3.2: Test Invoice Service

**Create test file:** `test/services/invoice_service_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:kantin_app/core/services/invoice_service.dart';

void main() {
  group('InvoiceService', () {
    test('generates valid invoice number', () {
      final invoice = InvoiceService.generateInvoiceNumber();
      
      expect(invoice, startsWith('INV-'));
      expect(InvoiceService.isValidInvoice(invoice), true);
    });
    
    test('validates invoice format correctly', () {
      expect(InvoiceService.isValidInvoice('INV-20251221-ABCD123'), true);
      expect(InvoiceService.isValidInvoice('INVALID'), false);
      expect(InvoiceService.isValidInvoice('INV-123'), false);
    });
    
    test('distinguishes our invoice from Midtrans', () {
      expect(InvoiceService.isOurInvoice('INV-20251221-ABC123'), true);
      expect(InvoiceService.isOurInvoice('MT-987654321'), false);
    });
  });
}
```

**Run tests:**
```bash
flutter test test/services/invoice_service_test.dart
```

✅ **Checkpoint:** Invoice service working, tests passing

---

## Day 4: Cart Persistence Service

### Step 4.1: Create Cart Service

**File:** `lib/core/services/cart_persistence_service.dart`

```dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../shared/models/cart_item_model.dart';

class CartPersistenceService {
  static const String _cartKeyPrefix = 'cart_';
  
  /// Save cart to local storage
  Future<void> saveCart(String tenantCode, List<CartItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_cartKeyPrefix$tenantCode';
    
    final json = jsonEncode(
      items.map((item) => item.toJson()).toList()
    );
    
    await prefs.setString(key, json);
  }
  
  /// Load cart from local storage
  Future<List<CartItem>> loadCart(String tenantCode) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_cartKeyPrefix$tenantCode';
    
    final json = prefs.getString(key);
    if (json == null) return [];
    
    final List<dynamic> decoded = jsonDecode(json);
    return decoded.map((e) => CartItem.fromJson(e)).toList();
  }
  
  /// Clear cart after successful order
  Future<void> clearCart(String tenantCode) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_cartKeyPrefix$tenantCode';
    await prefs.remove(key);
  }
  
  /// Get cart count without loading full cart
  Future<int> getCartCount(String tenantCode) async {
    final items = await loadCart(tenantCode);
    return items.fold(0, (sum, item) => sum + item.quantity);
  }
}
```

---

### Step 4.2: Create Cart Item Model (if not exists)

**File:** `lib/shared/models/cart_item_model.dart`

```dart
class CartItem {
  final String productId;
  final String productName;
  final int price;
  final int quantity;
  final String? imageUrl;
  final String? notes;
  
  CartItem({
    required this.productId,
    required this.productName,
    required this.price,
    required this.quantity,
    this.imageUrl,
    this.notes,
  });
  
  Map<String, dynamic> toJson() => {
    'product_id': productId,
    'product_name': productName,
    'price': price,
    'quantity': quantity,
    'image_url': imageUrl,
    'notes': notes,
  };
  
  factory CartItem.fromJson(Map<String, dynamic> json) => CartItem(
    productId: json['product_id'],
    productName: json['product_name'],
    price: json['price'],
    quantity: json['quantity'],
    imageUrl: json['image_url'],
    notes: json['notes'],
  );
  
  CartItem copyWith({
    String? productId,
    String? productName,
    int? price,
    int? quantity,
    String? imageUrl,
    String? notes,
  }) => CartItem(
    productId: productId ?? this.productId,
    productName: productName ?? this.productName,
    price: price ?? this.price,
    quantity: quantity ?? this.quantity,
    imageUrl: imageUrl ?? this.imageUrl,
    notes: notes ?? this.notes,
  );
}
```

✅ **Checkpoint:** Cart persistence service ready

---

## Day 5: Order Tracking Service

### Step 5.1: Create Tracking Service

**File:** `lib/features/guest/services/order_tracking_service.dart`

```dart
import 'package:appwrite/appwrite.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/appwrite_config.dart';
import '../../../core/providers/appwrite_provider.dart';
import '../../../shared/models/order_model.dart';

final orderTrackingServiceProvider = Provider((ref) {
  final databases = ref.read(appwriteDatabasesProvider);
  return OrderTrackingService(databases);
});

class OrderTrackingService {
  final Databases _databases;
  
  OrderTrackingService(this._databases);
  
  /// Search order by invoice (ours OR Midtrans)
  Future<OrderModel?> searchOrder(String query) async {
    try {
      final cleanQuery = query.trim().toUpperCase();
      
      // Try searching by our invoice OR Midtrans order ID
      final results = await _databases.listDocuments(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.ordersCollectionId,
        queries: [
          Query.or([
            Query.equal('invoice_number', cleanQuery),
            Query.equal('midtrans_order_id', cleanQuery),
          ]),
          Query.limit(1),
        ],
      );
      
      if (results.documents.isEmpty) return null;
      
      return OrderModel.fromJson(results.documents.first.data);
    } catch (e) {
      print('Error searching order: $e');
      return null;
    }
  }
  
  /// Watch order for real-time updates
  Stream<OrderModel> watchOrder(String invoiceNumber) {
    // TODO: Implement Appwrite Realtime subscription
    // Return stream that emits updates when order status changes
    throw UnimplementedError('Real-time tracking - future iteration');
  }
}
```

✅ **Checkpoint:** Core services completed

---

# PHASE 3: Mobile App Updates

**Duration:** 4 days  
**Goal:** Update mobile app for QR codes, deep linking, and ordering

---

## Day 6: QR Code Updates

### Step 6.1: Update QR Code Generator

**File:** `lib/features/tenant/presentation/pages/qr_code_display_page.dart`

**Find these lines (around line 35):**
```dart
String get qrCodeData {
  return tenantCode; // "Q8L2PH"
}
```

**Replace with:**
```dart
String get qrCodeData {
  // TODO: Replace with your actual domain
  const webDomain = 'kantin-app.vercel.app'; // Or 'kantin.app'
  return 'https://$webDomain/t/$tenantCode';
  // Output example: https://kantin-app.vercel.app/t/Q8L2PH
}
```

### Step 6.2: Test QR Code

1. Run app: `flutter run`
2. Login as tenant
3. Navigate to "QR Code" page
4. **Verify:** QR displays URL (not just code)
5. Screenshot QR for later testing

✅ **Checkpoint:** QR generates URLs

---

## Day 7: Android Deep Linking

### Step 7.1: Update AndroidManifest.xml

**File:** `android/app/src/main/AndroidManifest.xml`

**Find the `<activity>` tag with `android:name=".MainActivity"`**

**Add inside `<activity>` (after existing intent-filters):**

```xml
<!-- Deep link for tenant menu -->
<intent-filter android:autoVerify="true">
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    
    <data
        android:scheme="https"
        android:host="kantin-app.vercel.app"
        android:pathPrefix="/t" />
    
    <!-- Add your custom domain too if you have one -->
    <!-- 
    <data
        android:scheme="https"
        android:host="kantin.app"
        android:pathPrefix="/t" />
    -->
</intent-filter>
```

### Step 7.2: Handle Deep Links in Router

**File:** `lib/core/router/app_router.dart`

**Add this route:**

```dart
GoRoute(
  path: '/t/:code',
  builder: (context, state) {
    final code = state.pathParameters['code']!;
    
    // Return a loader widget that:
    // 1. Looks up tenant by code
    // 2. Navigates to menu page
    return TenantMenuLoader(tenantCode: code);
  },
),
```

### Step 7.3: Create Tenant Menu Loader

**File:** `lib/features/guest/presentation/pages/tenant_menu_loader.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/tenant_detail_provider.dart';

class TenantMenuLoader extends ConsumerWidget {
  final String tenantCode;
  
  const TenantMenuLoader({
    super.key,
    required this.tenantCode,
  });
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Look up tenant by code
    final tenantAsync = ref.watch(tenantByCodeProvider(tenantCode));
    
    return Scaffold(
      body: tenantAsync.when(
        data: (tenant) {
          if (tenant == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Kode tenant $tenantCode tidak ditemukan'),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => context.go('/'),
                    child: const Text('Kembali'),
                  ),
                ],
              ),
            );
          }
          
          // Tenant found! Redirect to menu
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.go('/menu/${tenant.id}');
          });
          
          return const Center(child: CircularProgressIndicator());
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Error: $error'),
        ),
      ),
    );
  }
}
```

### Step 7.4: Test Deep Linking

1. **Build APK:**
   ```bash
   flutter build apk --debug
   ```

2. **Install on device:**
   ```bash
   flutter install
   ```

3. **Test:**
   - Open Chrome on phone
   - Navigate to: `https://kantin-app.vercel.app/t/Q8L2PH` (use actual code)
   - **Expected:** Dialog shows "Open with Kantin App?"
   - Tap app → Menu loads

✅ **Checkpoint:** Deep linking working

---

## Day 8-9: Checkout Flow Updates

### Step 8.1: Create Checkout Page

**File:** `lib/features/guest/presentation/pages/checkout_page.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/invoice_service.dart';
import '../../../../shared/models/cart_item_model.dart';

class CheckoutPage extends ConsumerStatefulWidget {
  final String tenantId;
  final String tenantCode;
  final List<CartItem> cartItems;
  
  const CheckoutPage({
    super.key,
    required this.tenantId,
    required this.tenantCode,
    required this.cartItems,
  });
  
  @override
  ConsumerState<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends ConsumerState<CheckoutPage> {
  final _tableController = TextEditingController();
  final _notesController = TextEditingController();
  late final String _invoiceNumber;
  
  @override
  void initState() {
    super.initState();
    // Generate invoice IMMEDIATELY on page load
    _invoiceNumber = InvoiceService.generateInvoiceNumber();
  }
  
  int get _totalAmount {
    return widget.cartItems.fold(
      0,
      (sum, item) => sum + (item.price * item.quantity),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Order summary
            _buildOrderSummary(),
            
            const SizedBox(height: 24),
            
            // Invoice display (BEFORE payment)
            _buildInvoiceDisplay(),
            
            const SizedBox(height: 24),
            
            // Table number input
            TextField(
              controller: _tableController,
              decoration: const InputDecoration(
                labelText: 'Nomor Meja *',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            
            const SizedBox(height: 16),
            
            // Notes
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Catatan (opsional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            
            const SizedBox(height: 32),
            
            // Payment button
            FilledButton(
              onPressed: _handleCheckout,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
              child: const Text('Bayar Sekarang'),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildOrderSummary() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ringkasan Pesanan',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            
            ...widget.cartItems.map((item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${item.productName} x${item.quantity}'),
                  Text('Rp ${(item.price * item.quantity).toString()}'),
                ],
              ),
            )),
            
            const Divider(),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'TOTAL',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Rp $_totalAmount',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildInvoiceDisplay() {
    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.receipt, color: Colors.blue.shade700),
                const SizedBox(width: 8),
                const Text(
                  'Nomor Invoice Anda',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _invoiceNumber,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: _invoiceNumber));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Invoice disalin!')),
                      );
                    },
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 12),
            
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber, color: Colors.orange.shade700),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      '💾 PENTING: Simpan nomor invoice ini! '
                      'Gunakan untuk tracking pesanan Anda.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Future<void> _handleCheckout() async {
    // Validate table number
    if (_tableController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mohon isi nomor meja')),
      );
      return;
    }
    
    // TODO: Implement Midtrans payment
    // For now, show coming soon
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Pembayaran'),
        content: Text(
          'Invoice: $_invoiceNumber\n'
          'Total: Rp $_totalAmount\n\n'
          'Integrasi Midtrans akan ditambahkan di Phase 5.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
```

✅ **Checkpoint:** Checkout flow with invoice preview ready

---

# PHASE 4: Web Version Development

**Duration:** 4 days  
**Goal:** Build web ordering experience

---

## Day 10-11: Web Pages

### Step 10.1: Create Web Landing Page

**File:** `lib/features/web/presentation/pages/web_landing_page.dart`

```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class WebLandingPage extends StatelessWidget {
  const WebLandingPage({super.key});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Hero section
            _buildHeroSection(context),
            
            // Features
            _buildFeaturesSection(),
            
            // How it works
            _buildHowItWorksSection(),
            
            // Footer
            _buildFooter(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildHeroSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(64),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade700, Colors.blue.shade900],
        ),
      ),
      child: Center(
        child: Column(
          children: [
            const Icon(Icons.qr_code_scanner, size: 80, color: Colors.white),
            const SizedBox(height: 24),
            
            const Text(
              'Pesan Makanan dengan Scan QR',
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 16),
            
            const Text(
              'Tanpa download app • Cepat • Mudah',
              style: TextStyle(fontSize: 24, color: Colors.white70),
            ),
            
            const SizedBox(height: 32),
            
            // Code entry
            SizedBox(
              width: 400,
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Masukkan kode tenant',
                  filled: true,
                  fillColor: Colors.white,
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.arrow_forward),
                    onPressed: () {
                      // TODO: Navigate to menu
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildFeaturesSection() {
    return Padding(
      padding: const EdgeInsets.all(64),
      child: Column(
        children: [
          const Text(
            'Kenapa Kantin App?',
            style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 48),
          
          Wrap(
            spacing: 32,
            runSpacing: 32,
            children: [
              _buildFeatureCard(
                Icons.qr_code,
                'Scan & Order',
                'Scan QR code di meja, langsung pesan',
              ),
              _buildFeatureCard(
                Icons.payment,
                'Bayar Online',
                'Berbagai metode pembayaran tersedia',
              ),
              _buildFeatureCard(
                Icons.track_changes,
                'Track Pesanan',
                'Pantau status pesanan real-time',
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildFeatureCard(IconData icon, String title, String desc) {
    return SizedBox(
      width: 300,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(icon, size: 64, color: Colors.blue),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(desc, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildHowItWorksSection() {
    return Container(
      padding: const EdgeInsets.all(64),
      color: Colors.grey.shade100,
      child: Column(
        children: [
          const Text(
            'Cara Menggunakan',
            style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 48),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStep('1', 'Scan QR', 'Di meja atau masukkan kode'),
              const Icon(Icons.arrow_forward, size: 32),
              _buildStep('2', 'Pilih Menu', 'Tambah ke keranjang'),
              const Icon(Icons.arrow_forward, size: 32),
              _buildStep('3', 'Bayar', 'Online atau di kasir'),
              const Icon(Icons.arrow_forward, size: 32),
              _buildStep('4', 'Selesai', 'Track pesanan Anda'),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildStep(String number, String title, String desc) {
    return Column(
      children: [
        CircleAvatar(
          radius: 40,
          child: Text(number, style: const TextStyle(fontSize: 32)),
        ),
        const SizedBox(height: 8),
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        Text(desc, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
  
  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(32),
      color: Colors.grey.shade800,
      child: const Text(
        '© 2025 Kantin App. All rights reserved.',
        style: TextStyle(color: Colors.white),
        textAlign: TextAlign.center,
      ),
    );
  }
}
```

### Step 10.2: Create Order Tracking Page

**File:** `lib/features/guest/presentation/pages/order_tracking_page.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/order_tracking_service.dart';
import '../../../../shared/models/order_model.dart';

class OrderTrackingPage extends ConsumerStatefulWidget {
  const OrderTrackingPage({super.key});
  
  @override
  ConsumerState<OrderTrackingPage> createState() => _OrderTrackingPageState();
}

class _OrderTrackingPageState extends ConsumerState<OrderTrackingPage> {
  final _searchController = TextEditingController();
  OrderModel? _foundOrder;
  bool _isSearching = false;
  String? _errorMessage;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lacak Pesanan')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Search section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Masukkan Nomor Invoice',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'INV-20251221-ABC123 atau MT-987654',
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: _isSearching
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.search),
                          onPressed: _searchOrder,
                        ),
                      ),
                      onSubmitted: (_) => _searchOrder(),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    const Text(
                      '💡 Anda bisa gunakan nomor invoice dari kami (INV-xxx) '
                      'atau dari Midtrans (MT-xxx)',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Results
            if (_errorMessage != null)
              Card(
                color: Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red),
                      const SizedBox(width: 12),
                      Expanded(child: Text(_errorMessage!)),
                    ],
                  ),
                ),
              ),
            
            if (_foundOrder != null)
              Expanded(
                child: _buildOrderDetails(_foundOrder!),
              ),
          ],
        ),
      ),
    );
  }
  
  Future<void> _searchOrder() async {
    setState(() {
      _isSearching = true;
      _errorMessage = null;
      _foundOrder = null;
    });
    
    final query = _searchController.text.trim();
    
    if (query.isEmpty) {
      setState(() {
        _errorMessage = 'Mohon masukkan nomor invoice';
        _isSearching = false;
      });
      return;
    }
    
    final trackingService = ref.read(orderTrackingServiceProvider);
    final order = await trackingService.searchOrder(query);
    
    setState(() {
      _isSearching = false;
      
      if (order == null) {
        _errorMessage = 'Pesanan tidak ditemukan dengan nomor: $query';
      } else {
        _foundOrder = order;
      }
    });
  }
  
  Widget _buildOrderDetails(OrderModel order) {
    return SingleChildScrollView(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 32),
                  SizedBox(width: 12),
                  Text(
                    'Pesanan Ditemukan',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              
              const Divider(height: 32),
              
              // Invoice info
              _buildInfoRow('Invoice', order.invoiceNumber),
              if (order.midtransOrderId != null)
                _buildInfoRow('Midtrans Ref', order.midtransOrderId!),
              _buildInfoRow('Meja', order.tableNumber),
              _buildInfoRow('Total', 'Rp ${order.totalAmount}'),
              
              const Divider(height: 32),
              
              // Status
              const Text(
                'Status Pesanan',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              
              _buildStatusTimeline(order),
              
              const Divider(height: 32),
              
              // Items
              const Text(
                'Detail Pesanan',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              
              ...order.items.map((item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('• ${item.productName} x${item.quantity}'),
                    Text('Rp ${item.price * item.quantity}'),
                  ],
                ),
              )),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
  
  Widget _buildStatusTimeline(OrderModel order) {
    final statuses = [
      {'status': 'pending', 'label': 'Pesanan Diterima'},
      {'status': 'paid', 'label': 'Pembayaran Berhasil'},
      {'status': 'preparing', 'label': 'Sedang Diproses'},
      {'status': 'ready', 'label': 'Siap Disajikan'},
      {'status': 'completed', 'label': 'Selesai'},
    ];
    
    final currentIndex = statuses.indexWhere(
      (s) => s['status'] == order.status
    );
    
    return Column(
      children: statuses.asMap().entries.map((entry) {
        final index = entry.key;
        final status = entry.value;
        final isCompleted = index <= currentIndex;
        final isCurrent = index == currentIndex;
        
        return Row(
          children: [
            Icon(
              isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
              color: isCompleted ? Colors.green : Colors.grey,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                status['label']!,
                style: TextStyle(
                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                  color: isCompleted ? Colors.black : Colors.grey,
                ),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}
```

✅ **Checkpoint:** Web pages created

---

## Day 12-13: Midtrans Integration

### Step 12.1: Add Midtrans Package

**File:** `pubspec.yaml`

```yaml
dependencies:
  # Existing...
  
  # Payment
  midtrans_sdk: ^0.3.0  # For mobile
  url_strategy: ^0.2.0  # For web URL handling
```

**Install:**
```bash
flutter pub get
```

### Step 12.2: Create Payment Service (Mobile)

**File:** `lib/core/services/payment_service_mobile.dart`

```dart
import 'package:midtrans_sdk/midtrans_sdk.dart';

class PaymentServiceMobile {
  static final MidtransSDK _midtrans = MidtransSDK();
  
  static Future<void> init() async {
    _midtrans.init(
      clientKey: 'YOUR_CLIENT_KEY', // TODO: Move to env
      environment: MidtransEnvironment.sandbox, // Change to production later
      colorTheme: ColorTheme(
        colorPrimary: Colors.blue,
        colorPrimaryDark: Colors.blue.shade700,
        colorSecondary: Colors.green,
      ),
    );
  }
  
  Future<void> initiatePayment({
    required String invoiceNumber,
    required int amount,
    required List<OrderItem> items,
    required String tableNumber,
  }) async {
    try {
      // Create transaction details
      final transactionDetails = TransactionDetails(
        orderId: invoiceNumber,
        grossAmount: amount,
      );
      
      // Create item details
      final itemDetails = items.map((item) => ItemDetails(
        id: item.productId,
        price: item.price,
        quantity: item.quantity,
        name: item.productName,
      )).toList();
      
      // Create customer details
      final customerDetails = CustomerDetails(
        firstName: 'Customer',
        email: 'customer@example.com',
        phone: '08123456789',
      );
      
      // Start payment
      await _midtrans.startPaymentUiFlow(
        transactionDetails: transactionDetails,
        itemDetails: itemDetails,
        customerDetails: customerDetails,
      );
      
      // Result will be in callback
    } catch (e) {
      print('Payment error: $e');
      rethrow;
    }
  }
}
```

---

# PHASE 5: Integration Testing

**Duration:** 1 day

### Test Scenarios

1. **QR Code Flow:**
   - [ ] Generate QR in app
   - [ ] Scan with phone camera
   - [ ] Verify deep link or web opens
   - [ ] Menu loads correctly

2. **Cart Persistence:**
   - [ ] Add items to cart
   - [ ] Refresh browser/close app
   - [ ] Cart still has items

3. **Dual Invoice Search:**
   - [ ] Complete order to get both invoices
   - [ ] Search by our invoice → Found
   - [ ] Search by Midtrans ID → Same order found

4. **Payment Integration:**
   - [ ] Complete checkout
   - [ ] Pay via Midtrans sandbox
   - [ ] Webhook updates order
   - [ ] Payment status reflects in tracking

---

# PHASE 6: Deployment

**Duration:** 1 day

### Step 1: Build Web

```bash
flutter build web --release --base-href "/"
```

### Step 2: Deploy to Vercel

```bash
cd build/web
vercel --prod
```

### Step 3: Configure Domain (Optional)

If using custom domain, update in:
- Vercel settings
- `qr_code_display_page.dart` (webDomain constant)
- `AndroidManifest.xml` (deep link host)

### Step 4: Update Mobile App

```bash
# Update version
# pubspec.yaml: version: 1.1.0+2

flutter build apk --release
```

Upload to Play Store.

---

## 🎉 Completion Checklist

- [ ] All phases completed
- [ ] Payment webhook deployed
- [ ] Web version live on Vercel
- [ ] Mobile app uploaded to Play Store
- [ ] QR codes tested end-to-end
- [ ] Documentation updated

---

## 📞 Support

For issues during implementation:
1. Check Appwrite Console logs
2. Check Midtrans Dashboard logs
3. Review this guide step-by-step
4. Contact team lead for assistance

---

**Good luck with implementation!** 🚀
