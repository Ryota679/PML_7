# Appwrite Function Slots: Strategic Analysis & Recommendations

**Date:** 15 Desember 2025, 18:42 WIB  
**Status:** Strategic Planning Document  
**Purpose:** Analyze function slot usage and provide recommendations for efficient resource allocation

---

## 📊 Current Function Inventory

### **Deployed Functions (3/5 slots used):**

| Function | Purpose | Status | Priority |
|----------|---------|--------|----------|
| `delete-user` | Cascade delete users + related data | ✅ Active | Critical |
| `cleanup-expired-contracts` | Daily cleanup + trial/contract management | ✅ Active | Critical |
| `create-user` | Create Auth + DB user atomically | ✅ Active | High |

### **Reserved Functions (2/5 slots remaining):**

| Slot | Proposed Use | Status |
|------|-------------|--------|
| **Slot 4** | Payment Gateway Integration (Midtrans) | 🔒 **RESERVED** |
| **Slot 5** | Available for critical needs | 🟡 **OPEN** |

---

## 🎯 Function Consolidation Analysis

### **Option 1: Merge cleanup-expired-contracts + delete-user** ❌

**Reasoning AGAINST merger:**

```diff
cleanup-expired-contracts:
+ Scheduled daily (cron: 0 0 * * *)
+ Batch processing (multi-user)
+ No authorization checks needed
+ Handles: Trial downgrades, invitation codes, swap deadlines
+ Logic: Query-based automated cleanup

delete-user:
+ On-demand (HTTP trigger)
+ Single-user processing
+ REQUIRES authorization (BO, Tenant, Admin roles)
+ Handles: Manual deletion requests
+ Logic: Permission-based cascading delete
```

**Verdict:** ❌ **DO NOT MERGE**
- **Different triggers** (scheduled vs on-demand)
- **Different authorization logic** (none vs strict)
- **Different use cases** (automated cleanup vs manual admin action)
- **Maintenance complexity** increases if merged

---

## 💰 Withdrawal Distribution System Analysis

### **User's Proposed Use Case:**

```
Scenario:
- Tenant A: Total sales Rp 1,000,000
- Tenant B: Total sales Rp 500,000

Question: How to distribute withdrawal from Midtrans to correct users?
```

### **✅ Solution: FUNCTION NEEDED (Revised!)** 🔄

**User's Valid Concerns:**
1. **Auto withdrawal** - Tenant shouldn't wait for manual approval
2. **Holding period** - Midtrans holds funds for X days (chargeback protection)
3. **Notification** - Tenant needs to know when money is disbursed

**Revised Architecture:**

```
┌─────────────────────────────────────────────────────┐
│  MIDTRANS PAYMENT WEBHOOK (Slot 4)                 │
│  ├─ Webhook: Payment notification                  │
│  ├─ Action: Update `orders` status                 │
│  ├─ Store: transaction_id, amount, tenant_id       │
│  └─ Calculate: disbursement_date (payment + 7 days)│
└─────────────────────────────────────────────────────┘
           ↓
┌─────────────────────────────────────────────────────┐
│  NEW FUNCTION: auto-disburse-earnings (Scheduled)  │
│  ├─ Schedule: Daily at 02:00 WIB                   │
│  ├─ Query: Orders with disbursement_date <= today  │
│  ├─ Group: SUM(amount) per tenant_id              │
│  ├─ Call: Midtrans Disbursement API               │
│  ├─ Update: withdrawal_status = 'disbursed'       │
│  └─ Notify: Send notification to tenant            │
└─────────────────────────────────────────────────────┘
           ↓
┌─────────────────────────────────────────────────────┐
│  TENANT DASHBOARD: View Earnings                   │
│  ├─ Pending: Orders in holding period              │
│  ├─ Available: Ready for disbursement              │
│  ├─ Disbursed: Money transferred                   │
│  └─ History: All transactions                      │
└─────────────────────────────────────────────────────┘
```

**Database Schema Updates:**

```sql
orders:
  + disbursement_date (Date, indexed)
    - Calculated: payment_date + holding_period (7 days)
  + withdrawal_status (enum: pending/ready/disbursed)
  + disbursed_at (Date, nullable)
  + disbursement_id (String, Midtrans disbursement ID)

tenants:
  + bank_account_name (String, required for withdrawal)
  + bank_account_number (String, required)
  + bank_name (String, required)
  + total_earnings (Number, cache for quick display)
  + last_disbursed_at (Date)
```

**Holding Period Logic:**

```javascript
// In Midtrans webhook (Slot 4)
if (notification.transaction_status === 'settlement') {
    const holdingPeriod = 7; // days (standard e-commerce)
    const disbursementDate = new Date(
        paymentDate.getTime() + holdingPeriod * 24 * 60 * 60 * 1000
    );
    
    await databases.updateDocument(
        databaseId,
        ordersCollectionId,
        orderId,
        {
            payment_status: 'paid',
            disbursement_date: disbursementDate.toISOString(),
            withdrawal_status: 'pending' // In holding period
        }
    );
}
```

**Auto-Disbursement Function (NEW - NEEDS SLOT 5!):**

```javascript
// functions/auto-disburse-earnings/src/main.js

export default async ({ req, res, log, error }) => {
    const now = new Date();
    log('💰 Starting auto-disbursement process...');
    
    // 1. Query orders ready for disbursement
    const readyOrders = await databases.listDocuments(
        databaseId,
        ordersCollectionId,
        [
            Query.equal('withdrawal_status', 'pending'),
            Query.lessThanEqual('disbursement_date', now.toISOString()),
            Query.equal('payment_status', 'paid')
        ]
    );
    
    // 2. Group by tenant_id
    const tenantEarnings = {};
    readyOrders.documents.forEach(order => {
        const tenantId = order.tenant_id;
        if (!tenantEarnings[tenantId]) {
            tenantEarnings[tenantId] = {
                orders: [],
                total: 0,
                tenant: null
            };
        }
        tenantEarnings[tenantId].orders.push(order);
        tenantEarnings[tenantId].total += order.total_amount;
    });
    
    // 3. Process disbursement per tenant
    for (const [tenantId, data] of Object.entries(tenantEarnings)) {
        try {
            // Get tenant bank details
            const tenant = await databases.getDocument(
                databaseId,
                tenantsCollectionId,
                tenantId
            );
            
            // Call Midtrans Disbursement API
            const disbursement = await midtrans.disburse({
                payouts: [{
                    beneficiary_name: tenant.bank_account_name,
                    beneficiary_account: tenant.bank_account_number,
                    beneficiary_bank: tenant.bank_name,
                    amount: data.total,
                    notes: `Pencairan ${data.orders.length} pesanan`
                }]
            });
            
            // Update all orders
            for (const order of data.orders) {
                await databases.updateDocument(
                    databaseId,
                    ordersCollectionId,
                    order.$id,
                    {
                        withdrawal_status: 'disbursed',
                        disbursed_at: now.toISOString(),
                        disbursement_id: disbursement.id
                    }
                );
            }
            
            // Send notification to tenant
            await sendNotification(tenantId, {
                title: '💰 Pencairan Dana Berhasil',
                body: `Rp ${data.total.toLocaleString()} telah ditransfer ke rekening Anda`,
                type: 'disbursement'
            });
            
            log(`✅ Disbursed Rp ${data.total} to tenant ${tenantId}`);
            
        } catch (err) {
            error(`❌ Failed to disburse for tenant ${tenantId}: ${err.message}`);
        }
    }
    
    return res.json({ success: true });
};
```

**Tenant Notification Options:**

1. **In-App Notification** (Best UX):
   ```dart
   // Store in `notifications` collection
   // Display badge in tenant dashboard
   // Push notification via Appwrite Messaging
   ```

2. **Email** (Backup):
   ```javascript
   // Use Appwrite Messaging service
   await messaging.createEmail({
       to: tenant.email,
       subject: 'Pencairan Dana',
       body: `Rp ${amount} telah ditransfer`
   });
   ```

**Verdict:** ✅ **FUNCTION NEEDED (Slot 5!)**

**Why Function is Required:**
- ✅ Scheduled processing (daily check)
- ✅ External API call (Midtrans Disbursement)
- ✅ Batch processing (multiple tenants)
- ✅ Security (API keys for Midtrans)
- ✅ Reliable execution (can't depend on app being open)

**Trade-off:**
- Uses last available slot (Slot 5)
- Critical for business operations
- Worth the slot investment!

---

## 🗑️ 3-Month Data Retention Policy

### **User's Requirements:**

```
Auto-delete every 3 months (quarterly):
├─ Orders (completed, 3+ months old)
├─ Expired tenant contracts
└─ Deleted tenants + related data

Schedule: March, June, September, December
Purpose: Reduce database size
```

### **✅ Solution: EXTEND cleanup-expired-contracts**

**Why this works:**

Current `cleanup-expired-contracts` already handles:
- ✅ Expired contracts deletion
- ✅ Cascading deletes (tenants → staff → products → orders)
- ✅ Invitation code cleanup
- ✅ Trial subscription management

**Minor Modifications Needed:**

```javascript
// Add to cleanup-expired-contracts

// NEW: Cleanup old completed orders (3 months)
log('\n🗑️ Cleaning up old completed orders...');
const threeMonthsAgo = new Date(now.getTime() - 90 * 24 * 60 * 60 * 1000);

const oldOrdersResponse = await databases.listDocuments(
    databaseId,
    ordersCollectionId,
    [
        Query.equal('status', ['completed', 'cancelled']),
        Query.lessThan('$createdAt', threeMonthsAgo.toISOString())
    ]
);

for (const order of oldOrdersResponse.documents) {
    await databases.deleteDocument(databaseId, ordersCollectionId, order.$id);
    summary.archivedData.orders++;
}

log(`   ✅ Archived ${summary.archivedData.orders} old orders`);
```

**Schedule Update:**
```yaml
Current: 0 0 * * * (daily at 00:00 UTC)
Proposed: Keep daily (safer)

Logic: Date-based check (only deletes 3+ months old)
Benefit: Runs daily but only acts on old data
```

**Verdict:** ✅ **EXTEND EXISTING FUNCTION**
- No new slot needed
- ~20 lines of code addition
- Reuse existing infrastructure
- Same error handling & logging

---

## 🔄 Random Product Deactivation Analysis

### **Current Issue:**

```
Problem: Auto-deactivation fails with 401 (Unauthorized)
Cause: Appwrite permission complexity
Proposed: Function-based deactivation?
```

### **✅ Solution: HYBRID APPROACH**

**Why Function Won't Help Directly:**

```diff
- Function uses API key (bypasses permissions) ✅
- But function still calls Databases.updateDocument() ✅
- Document-level permissions STILL apply! ❌
- Same 401 error will occur! ❌
```

**Real Solution (Already Implemented):**

```
1. ✅ Disable Row Security (DONE)
2. ✅ Collection permissions: Users (CRUD) (DONE)
3. ✅ Clear document permissions (Script run successfully)
4. ✅ Remove permissions from createProduct() (Code updated)

Result: Should work NOW without function!
```

**For D-0 Automatic Enforcement:**

**User's Valid Concern:**
> "Bagaimana jika user tidak memilih sampai D-0?"

**✅ Solution: Add to cleanup-expired-contracts Function**

```javascript
// Add to cleanup-expired-contracts/src/main.js

// ========== AUTO-DEACTIVATE EXCESS PRODUCTS (D-0) ==========
log('\n📦 Checking product limits for free tier users...');
try {
    // Query free tier business owners
    const freeTierUsers = await databases.listDocuments(
        databaseId,
        usersCollectionId,
        [
            Query.equal('payment_status', ['free', 'expired']),
            Query.equal('role', ['owner_business', 'owner_bussines'])
        ]
    );
    
    summary.productLimits = { checked: 0, deactivated: 0, tenantsProcessed: 0 };
    
    for (const user of freeTierUsers.documents) {
        const PRODUCT_LIMIT = 15; // Free tier limit (10 for non-selected, 15 for selected)
        
        // Get user's selected tenants
        const selectedTenantIds = user.selected_tenant_ids || [];
        
        for (const tenantId of selectedTenantIds) {
            // Get all ACTIVE products for this tenant
            const productsResponse = await databases.listDocuments(
                databaseId,
                productsCollectionId,
                [
                    Query.equal('tenant_id', tenantId),
                    Query.equal('is_active', true),
                    Query.limit(100) // Safety limit
                ]
            );
            
            const activeCount = productsResponse.documents.length;
            summary.productLimits.checked++;
            
            if (activeCount > PRODUCT_LIMIT) {
                const excessCount = activeCount - PRODUCT_LIMIT;
                log(`\n   ⚠️  Tenant ${tenantId}: ${activeCount}/${PRODUCT_LIMIT} products (excess: ${excessCount})`);
                log(`   🎲 Random-selecting ${excessCount} products to deactivate...`);
                
                // ⭐ RANDOM SELECTION (user requested)
                // Shuffle array for random selection
                const shuffledProducts = productsResponse.documents
                    .sort(() => Math.random() - 0.5);
                
                // Deactivate random products
                for (let i = 0; i < excessCount; i++) {
                    const product = shuffledProducts[i];
                    
                    try {
                        await databases.updateDocument(
                            databaseId,
                            productsCollectionId,
                            product.$id,
                            {
                                is_available: false  // Use existing field only
                            }
                        );
                        
                        summary.productLimits.deactivated++;
                        log(`     ✅ Deactivated: ${product.name} (set is_available=false)`);
                    } catch (e) {
                        error(`     ❌ Failed to deactivate ${product.name}: ${e.message}`);
                    }
                }
                
                summary.productLimits.tenantsProcessed++;
            } else {
                log(`   ✅ Tenant ${tenantId}: ${activeCount}/${PRODUCT_LIMIT} products (OK)`);
            }
        }
    }
    
    log(`\n   📊 Product Limit Summary:`);
    log(`     Tenants checked: ${summary.productLimits.checked}`);
    log(`     Tenants processed: ${summary.productLimits.tenantsProcessed}`);
    log(`     Products deactivated: ${summary.productLimits.deactivated}`);
    
} catch (e) {
    error(`   ❌ Failed product limit check: ${e.message}`);
}
```


**How D-0 Enforcement Works:**

```
Timeline:
├─ D-7: Orange warning banner ("Pilih produk sebelum [date]")
├─ D-3: Red warning banner ("Segera pilih produk!")
├─ D-1: Critical banner ("Besok produk akan dideaktivasi otomatis!")
└─ D-0: cleanup-expired-contracts runs (00:00 UTC)
    ├─ Checks: Active products > limit?
    ├─ User selected manually? → Keep selection ✅
    ├─ User didn't select? → Auto-deactivate OLDEST products ❌
    └─ Notify: Tenant dashboard shows which products deactivated
```

**User Experience:**

**Scenario 1: User Selects Proactively (D-7 to D-1)**
```
✅ User taps "Pilih Produk Aktif"
✅ Selects 15 favorite products
✅ System: Deactivates remaining 5 immediately
✅ D-0: Function skips (already compliant)
```

**Scenario 2: User Ignores Warning (D-0)**
```
⚠️ User doesn't select anything
⚠️ D-0 arrives, function runs at 00:00
🤖 System: Auto-deactivates 5 RANDOM products
📱 Notification: "5 produk dinonaktifkan otomatis"
📋 Dashboard: Shows list of deactivated products
🔄 User can reactivate later (after upgrade or deactivating others)
```

**Deactivation Strategy (IMPLEMENTED):**

```
✅ SELECTED: Random Selection (User Requested)
Implementation: .sort(() => Math.random() - 0.5)
Reason: Fair, unbiased, allows tenant to swap any product later

Alternative strategies considered:
- By creation date (oldest first) - may remove valuable legacy items
- By price (lowest first) - biased against affordable options  
- By sales (least sold first) - data-driven but complex
- ✅ Random - MOST FAIR, neutral selection

Final Decision: RANDOM (deployed in cleanup-expired-contracts)
```

**Verdict:** ✅ **NO NEW FUNCTION, EXTEND cleanup-expired-contracts**

**Why This Works:**
- ✅ Runs daily (catches D-0 automatically)
- ✅ API key access (bypasses permission issues)
- ✅ Already handles grace periods & deadlines
- ✅ Same infrastructure, ~40 more LOC
- ✅ No additional slot needed!

**Trade-off:**
- User loses control if they don't select
- But: 7-day warning period is generous
- Fair: Oldest products deactivated (predictable)

---

## 🎯 Final Recommendations

### **Function Slot Allocation (REVISED):**

```
Slot 1: delete-user                    [KEEP] ✅
Slot 2: cleanup-expired-contracts      [EXTEND] ✅
        + 3-month data retention
        + D-0 product limit enforcement
Slot 3: create-user                    [KEEP] ✅
Slot 4: payment-gateway-webhook        [DEPLOY] 🚀
        Record payments + calculate disbursement dates
Slot 5: auto-disburse-earnings         [DEPLOY] 🚀
        Automatic withdrawal processing with Midtrans
```

**ALL 5 SLOTS ALLOCATED!** ⚠️

**Critical:** No more function slots available. Future features must use:
- Client-side logic
- Extend existing functions
- Appwrite built-in services (Messaging, Realtime, Storage)

### **Action Items:**

#### **1. Data Retention (3-month cleanup)**
- ✅ **Action:** Extend `cleanup-expired-contracts` 
- ✅ **Effort:** ~30 minutes
- ✅ **Lines of Code:** ~25 LOC
- ✅ **Function Slot:** None (reuse existing)

**Implementation:**
```javascript
// Add to cleanup-expired-contracts/src/main.js
// After line 562 (before final summary)

// ========== ARCHIVE OLD ORDERS (3 MONTHS) ==========
log('\n🗑️ Archiving old completed orders (3+ months)...');
try {
    const threeMonthsAgo = new Date(now.getTime() - 90 * 24 * 60 * 60 * 1000);
    
    const oldOrdersResponse = await databases.listDocuments(
        databaseId,
        ordersCollectionId,
        [
            Query.equal('status', ['completed', 'cancelled', 'rejected']),
            Query.lessThan('$createdAt', threeMonthsAgo.toISOString()),
            Query.limit(100) // Process in batches for safety
        ]
    );
    
    summary.archivedData = { orders: 0 };
    
    for (const order of oldOrdersResponse.documents) {
        try {
            await databases.deleteDocument(databaseId, ordersCollectionId, order.$id);
            summary.archivedData.orders++;
        } catch (e) {
            error(`   Failed to archive order ${order.$id}: ${e.message}`);
        }
    }
    
    log(`   ✅ Archived ${summary.archivedData.orders} old orders`);
} catch (e) {
    error(`   ❌ Failed to archive orders: ${e.message}`);
}
```

#### **2. Withdrawal Distribution**
- ✅ **Action:** Build Flutter UI for balance calculation
- ✅ **Effort:** ~2 hours
- ✅ **Function Slot:** None (app-side logic)
- ✅ **Database:** No schema changes needed

**Key Features:**
```dart
// Tenant Dashboard: "Saldo Tersedia" card
- Query paid orders
- Calculate SUM(total_amount)
- Display balance
- Button: "Ajukan Penarikan"

// BO Dashboard: "Permintaan Penarikan" page
- View all tenant withdrawal requests
- Verify bank details
- Approve/Reject
- Process via Midtrans Disbursement API (optional)
```

#### **3. Product Auto-Deactivation**
- ✅ **Action:** Test current fix (permissions cleared)
- ✅ **Backup:** Implement manual selection UI
- ✅ **Effort:** 1-3 hours (depending on approach)
- ✅ **Function Slot:** None

---

## 📈 Function Slot Future Planning

### **Potential Future Needs:**

| Priority | Use Case | Function Needed? |
|----------|----------|------------------|
| 🔴 High | Payment gateway webhook | ✅ YES (Slot 4 reserved) |
| 🟡 Medium | Email notifications | ❌ NO (use Appwrite Messaging) |
| 🟡 Medium | QR code generation | ❌ NO (client-side with `qr_flutter`) |
| 🟡 Medium | Analytics/Reports | ❌ NO (client-side aggregation) |
| 🟢 Low | Image compression | ❌ NO (already client-side) |
| 🟢 Low | Backup/Export data | 🤔 MAYBE (if large datasets) |

### **Slot 5 Reserve Criteria:**

Only use Slot 5 if feature requires:
1. ✅ Server-side processing (can't be done client-side)
2. ✅ API key privileges (bypass permissions)
3. ✅ Scheduled execution (cron job)
4. ✅ External API integration (webhooks)
5. ✅ Heavy computation (timeout > 30s)

**Most features DON'T need functions!** Client-side code is:
- Faster to develop
- Easier to debug
- No deployment overhead
- Free (no function execution costs)

---

## 💡 Key Insights

### **1. Function Conservation is Smart** ✅

User's approach to reserve function slots is **excellent planning**. Many developers over-use functions for things that can be done client-side.

### **2. Consolidation ≠ Always Better** ⚠️

Merging `cleanup-expired-contracts` + `delete-user` would:
- ❌ Increase complexity
- ❌ Mix scheduled vs on-demand logic
- ❌ Harder to debug
- ❌ Violate single responsibility principle

**Better:** Keep separate, extend `cleanup` for data retention

### **3. Database > Functions for Calculations** 📊

Aggregations (SUM, COUNT, GROUP BY) should be:
- ✅ Queried client-side
- ✅ Cached if needed (Riverpod state)
- ✅ Real-time via Appwrite Realtime subscriptions

**Only use functions if:**
- Data too large for client query
- Complex multi-step calculations
- Need server-side validation

### **4. Midtrans Function Scope** 🔒

**Slot 4 (payment-gateway-webhook) should ONLY:**
```javascript
1. Receive Midtrans webhook
2. Validate signature (security)
3. Update order status in database
4. Send notification (optional)
```

**Should NOT:**
- Calculate balances (client-side)
- Process withdrawals (manual/admin action)
- Handle refunds directly (Midtrans API)

**Keep it simple!** Webhook = Record payment, that's it.

---

## 🎓 Recommendations Summary

### **DO:**
1. ✅ Extend `cleanup-expired-contracts` with:
   - 3-month data retention (~25 LOC)
   - D-0 product limit enforcement (~40 LOC)
2. ✅ Deploy `payment-gateway-webhook` (Slot 4) for Midtrans
3. ✅ Deploy `auto-disburse-earnings` (Slot 5) for automated withdrawals
4. ✅ Keep `delete-user` separate (don't merge)
5. ✅ Add holding period logic to orders schema
6. ✅ Build tenant earnings dashboard (client-side)

### **DON'T:**
1. ❌ Merge `cleanup` + `delete-user` functions (different purposes)
2. ❌ Manual withdrawal approval (defeats holding period purpose)
3. ❌ Skip holding period (Midtrans requires for chargeback protection)
4. ❌ Create additional functions (all 5 slots now allocated!)

### **CRITICAL - All Slots Used:**

⚠️ **Function limit reached!** Future development must:
- Prioritize client-side solutions
- Extend existing functions carefully
- Use Appwrite services (Messaging, Realtime, Storage)
- Consider upgrading plan if more functions needed

---

## 📌 Conclusion (REVISED)

**Current function usage: ALL SLOTS ALLOCATED** ⚠️

You have:
- 3 existing functions (stable & deployed) ✅
- 2 new functions needed (critical for business) 🚀
  - **Slot 4:** Payment webhook (record transactions)
  - **Slot 5:** Auto-disbursement (automatic withdrawals)

**Functions needed** for discussed features:
- ✅ Withdrawal distribution → **Slot 5 (auto-disburse-earnings)**
- ✅ Data retention → Extend cleanup-expired-contracts
- ✅ Product D-0 enforcement → Extend cleanup-expired-contracts

**Resource efficiency: 100%** 🎯

Your planning approach is **excellent**, and you've identified **critical gaps**:
1. Holding periods require automation (can't be manual)
2. Tenant notifications essential for trust
3. D-0 enforcement prevents user confusion

**All 5 slots now justified and allocated!**

---

## ⚠️ IMPORTANT: Function Limit Reached

**Future Development Strategy:**

With all function slots used, prioritize:

1. **Client-Side Solutions First**
   - Query optimization
   - Caching strategies
   - Local state management

2. **Extend Existing Functions**
   - `cleanup-expired-contracts` is flexible
   - Add new cleanup tasks as needed
   - Keep single responsibility per function

3. **Appwrite Built-in Services**
   - Messaging (notifications)
   - Realtime (live updates)
   - Storage (file handling)

4. **Consider Upgrade** (if needed)
   - Appwrite Pro: 15 functions
   - Evaluate cost vs development time

**Your functions are now:**
```
✅ 100% utilized
✅ All business-critical
✅ Well-architected
✅ Scalable foundation
```

Excellent resource management! 🎉

---

## 📝 FINAL IMPLEMENTATION DECISIONS (15 Dec 2025, 19:10 WIB)

### **Decision 1: Withdrawal System - Manual Approval** ✅

**User Choice:** Manual approval (NOT auto-approve)

**Requirements:**
1. **Dedicated BO Page:** "Kelola Pencairan Dana"
   - List all withdrawal requests
   - Show: Tenant name, amount, bank details, request date, status
   - Sort by: Date (newest first)
   
2. **Batch Actions:**
   - Button: "Approve All" (approve all pending requests at once)
   - Individual approve/reject buttons per request
   
3. **Search Functionality:**
   - Search by: Request ID
   - Search by: Sequential number (e.g., #001, #002)
   - Search by: Tenant name
   - Real-time filtering

4. **Workflow:**
   ```
   Tenant submits → Status: 'pending'
     ↓
   BO reviews in dashboard
     ↓
   BO clicks: "Approve" OR "Approve All"
     ↓
   Process via Midtrans Disbursement API
     ↓
   Status: 'processing' → 'completed'
     ↓
   Tenant notification: "Dana sudah ditransfer"
   ```

**Database Schema:**
```sql
withdrawal_requests:
  - id (auto-increment for sequential number)
  - tenant_id (foreign key)
  - amount (decimal)
  - bank_name (string)
  - bank_account_number (string)
  - bank_account_name (string)
  - status (enum: pending/approved/rejected/completed)
  - requested_at (datetime)
  - processed_at (datetime, nullable)
  - processed_by (user_id, nullable)
  - disbursement_id (Midtrans disbursement ID)
  - notes (string, nullable)
```

**Implementation:** Client-side UI + extend Slot 4 webhook (no new function needed)

---

### **Decision 2: Product Deactivation - PRIORITY FIX** 🔴

**User Priority:** Fix random pick product deactivation FIRST (before withdrawal)

**Solution:** Extend `cleanup-expired-contracts` function

**Implementation Plan:**
1. Add product limit check logic (~40 LOC)
2. Deactivate OLDEST products (fair & predictable)
3. Send notification to tenant
4. Test with current permission setup

**Code Location:** `functions/cleanup-expired-contracts/src/main.js`

**Test Plan:**
1. Wait for rate limit to reset (10 minutes)
2. Login as tenant with 19+ products
3. Function runs or manual trigger
4. Verify: Excess products deactivated (NOT deleted)
5. Verify: No 401 permission errors

---

## 🎯 IMPLEMENTATION ORDER

### **Phase 1: Fix Product Deactivation** (IMMEDIATE) 🔴
- [ ] Extend `cleanup-expired-contracts` with product limit logic
- [ ] Test permission fix (row security OFF, collection: Users)
- [ ] Verify deactivation works without errors
- [ ] Deploy function update

### **Phase 2: Withdrawal System** (NEXT) 🟡
- [ ] Create `withdrawal_requests` collection
- [ ] Build Tenant withdrawal request UI
- [ ] Build BO withdrawal management page
  - [ ] List view with pagination
  - [ ] "Approve All" button
  - [ ] Search functionality
  - [ ] Individual approve/reject
- [ ] Integrate Midtrans Disbursement API
- [ ] Add notification system

### **Phase 3: Data Retention** (LATER) 🟢
- [ ] Extend `cleanup-expired-contracts` with 3-month order cleanup
- [ ] Test quarterly cleanup logic
- [ ] Monitor database size reduction

---

## 🎯 CRITICAL: Deletion Policy Clarification (15 Dec 2025, 19:55 WIB)

### **Business Model Understanding**

After thorough discussion, here is the **FINAL** and **DEFINITIVE** deletion policy:

---

### **Business Owner (Master Account)**

**Revenue Model:**
```
Income source: Tenant contracts (NOT BO subscription)
Subscription: Premium features vs Free tier features
Business value: Multiple tenants, historical data, central hub
```

**Deletion Policy:**
```
✅ NEVER auto-delete Business Owner accounts
✅ Subscription expires → Downgrade to free tier
✅ Free tier: Stay forever (no time limit)
✅ Account preservation: Permanent
```

**Rationale:**
1. **Revenue Source:** BO doesn't pay directly, tenants do
2. **Business Hub:** Central account for multiple tenants
3. **Data Value:** Historical business intelligence
4. **Re-engagement:** Can upgrade subscription anytime
5. **Low Cost:** Free tier exists, minimal database impact

**Example:**
```
Business Owner "Opoyo":
├─ Premium subscription expires Dec 2025
├─ Auto-downgrade to free tier ✅
├─ Keeps account forever ✅
├─ Has 5 tenant contracts (revenue source)
├─ Can upgrade to premium anytime
└─ NEVER deleted ✅
```

---

### **Tenant (Subordinate Account)**

**Revenue Model:**
```
Contract-based: Monthly/yearly agreement with BO
Payment: Tenant pays BO for operational access
Duration: Fixed contract period (contract_end_date)
```

**Deletion Policy:**
```
✅ Contract expires + 3 months grace → AUTO-DELETE
✅ Login activity: IRRELEVANT
✅ Payment status: Determines deletion
✅ Grace period: 90 days post-contract expiry
```

**Logic:**
```javascript
const threeMonthsAgo = new Date(now - 90 * 24 * 60 * 60 * 1000);

if (user.role === 'tenant' && 
    user.contract_end_date < threeMonthsAgo) {
    // CASCADE DELETE:
    // - Tenant account
    // - All staff
    // - All products
    // - All orders (completed only, preserve pending)
}
```

**Rationale:**
1. **Contract Model:** Tenant pays for service period
2. **Operational Unit:** Single business, can be recreated
3. **Data Cleanup:** Reduces database bloat
4. **Grace Period:** 3 months is generous for renewal
5. **Business Decision:** Contract not renewed = customer left

**Example:**
```
Tenant "Kafe Testing":
├─ Contract: Jan 1, 2025 - Dec 31, 2025
├─ Dec 31, 2025: Contract expires
├─ Jan-March 2026: Grace period (NO deletion)
│   └─ Tenant can still login (read-only or limited)
├─ April 1, 2026: 3 months passed
└─ AUTO-DELETE (tenant + staff + products + orders) ✅

Login activity during grace:
- Logged in 50 times: Still deleted (contract expired)
- Never logged in: Still deleted (contract expired)
→ Login is IRRELEVANT, only contract_end_date matters!
```

---

### **Key Differences Summary**

| Aspect | Business Owner | Tenant |
|--------|----------------|--------|
| **Account Type** | Master/Hub | Subordinate/Operational |
| **Revenue** | From tenant contracts | Pays contract to BO |
| **Subscription** | Premium/Free tiers | Contract period |
| **Expiry Action** | Downgrade to free | 3-month grace period |
| **After Grace** | Stay on free tier | AUTO-DELETE |
| **Deletion** | NEVER | After 3 months dormant |
| **Data Retention** | Permanent | 3 months grace only |
| **Reactivation** | Upgrade subscription | Cannot (deleted) |
| **Login Tracking** | Not relevant | Not relevant |

---

### **Implementation Impact on automated-cleanup-tasks**

**OLD Understanding (WRONG):**
```javascript
❌ Delete BO after 12 months dormancy
❌ Check login activity for deletion criteria
❌ Treat BO and Tenant similarly
```

**NEW Understanding (CORRECT):**
```javascript
✅ SKIP Business Owners entirely (never delete)
✅ DELETE Tenants (contract_end_date + 90 days)
✅ Login activity irrelevant for both
✅ Different models: Subscription vs Contract
```

**Code Logic:**
```javascript
// automated-cleanup-tasks function

// 1. BUSINESS OWNERS: NO DELETION LOGIC
// Just handle subscription downgrades (already done in trial logic)

// 2. TENANTS: 3-month contract grace period
const threeMonthsAgo = new Date(now.getTime() - 90 * 24 * 60 * 60 * 1000);

const expiredTenants = await databases.listDocuments(
    databaseId,
    usersCollectionId,
    [
        Query.equal('role', 'tenant'),
        Query.lessThan('contract_end_date', threeMonthsAgo.toISOString()),
        Query.isNotNull('contract_end_date')
    ]
);

for (const tenant of expiredTenants.documents) {
    log(`Deleting tenant: ${tenant.username}`);
    log(`Contract expired: ${tenant.contract_end_date}`);
    log(`Grace period ended: 3 months passed`);
    
    // CASCADE DELETE (using existing logic)
    // - Staff
    // - Products  
    // - Orders (completed)
    // - Tenant account
}

// 3. PRODUCT LIMITS: Already implemented ✅
```

---

### **Why This Matters**

**Business Continuity:**
```
✅ BO accounts preserved = business relationships intact
✅ Can reactivate premium anytime = revenue opportunity
✅ Historical data available = business intelligence
✅ Tenant cleanup = database efficiency
```

**User Experience:**
```
✅ BO: Can downgrade/upgrade freely, no data loss fear
✅ Tenant: Clear contract terms, 3-month grace generous
✅ Predictable: Contract-based deletion, not activity-based
```

**Technical Benefits:**
```
✅ Simpler logic: One deletion rule (contract expiry)
✅ No login tracking needed: Reduces complexity
✅ Clear separation: Master account vs operational unit
```

---

**This is the DEFINITIVE policy going forward. Do not deviate without explicit user approval.**

---

**Last Updated:** 15 Desember 2025, 19:57 WIB  
**Status:** Documented & Finalized  
**Priority:** Implement in automated-cleanup-tasks function

