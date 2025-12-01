# 🚀 Langkah Selanjutnya: Sprint 4

**Status Saat Ini:** Sprint 3 complete (75% MVP done)  
**Target:** Complete Sprint 4 untuk launch MVP

---

## 📊 Progress Summary

✅ **Sprint 1:** Fondasi & Auth (100%)
✅ **Sprint 2:** Manajemen Konten (100%)
✅ **Sprint 3:** Guest Ordering Flow + QR Scanner (100%)
⏳ **Sprint 4:** Order Management ← **NEXT**

---

## 🎯 Sprint 4: Order Management & Stability

### **Tujuan:**
Memberikan tenant kemampuan untuk menerima dan mengelola pesanan dari customer

### **Core Features (Wajib):**

#### 1. Tenant Order Dashboard
**Priority:** HIGH  
**Estimasi:** 2-3 hari  

**Tasks:**
- [ ] Create `TenantOrderDashboardPage`
- [ ] Display incoming orders (real-time)
- [ ] Filter by status (Pending/Preparing/Ready/Completed)
- [ ] Order cards dengan detail lengkap:
  - Order number & queue number
  - Customer info (name, phone, table)
  - Items list dengan quantities
  - Total amount
  - Timestamp
  - Current status

**Technical:**
- Use Riverpod for state management
- Query orders: `where('tenant_id', '==', tenantId)`
- Sort by: `orderBy('created_at', 'desc')`
- Real-time options:
  - **Option A:** Polling every 10s (simple)
  - **Option B:** Appwrite Realtime (WebSocket - butuh setup)

---

#### 2. Order Status Management
**Priority:** HIGH  
**Estimasi:** 1-2 hari

**Tasks:**
- [ ] Create `updateOrderStatus` Appwrite Function
- [ ] Status transition logic:
  ```
  Pending → Confirmed → Preparing → Ready → Completed
  ```
- [ ] Status update UI (dropdown/buttons)
- [ ] Confirmation dialog before status change
- [ ] Timestamp tracking untuk setiap status
- [ ] Optimistic UI updates

**Technical:**
- Function scopes: `databases.write`
- Validate status transitions (no skip/reverse)
- Update `order.status` + `order.updated_at`
- Return updated order to client

---

#### 3. Guest Order Tracking (Real-time)
**Priority:** MEDIUM  
**Estimasi:** 1 hari

**Tasks:**
- [ ] Auto-refresh pada `OrderTrackingPage`
- [ ] Poll interval: 15 seconds
- [ ] Status indicator updates:
  - Pending: ⏳ Gray
  - Confirmed: 📋 Blue  
  - Preparing: 🍳 Orange
  - Ready: ✅ Green
  - Completed: ✓ Dark Green
- [ ] Estimated time display (optional)
- [ ] Push notification (bonus - butuh Firebase)

**Technical:**
- Polling dengan `Timer.periodic(Duration(seconds: 15))`
- Cancel timer on dispose
- Update UI berdasarkan status baru

---

### **Bonus Features (Optional):**

#### 4. Order Statistics Dashboard
**Priority:** LOW  
**Estimasi:** 1 hari

- [ ] Daily orders count
- [ ] Total revenue (today/week/month)
- [ ] Popular items chart
- [ ] Average order value

#### 5. Order History
**Priority:** LOW  
**Estimasi:** 0.5 hari

- [ ] Filter completed orders by date range
- [ ] Search by order number / customer name
- [ ] Export to CSV (optional)

#### 6. Sound Notifications
**Priority:** LOW  
**Estimasi:** 0.5 hari

- [ ] Play sound on new order (tenant side)
- [ ] Vibrate on status update (guest side)
- [ ] Package: `audioplayers` or `flutter_ringtone_player`

---

## 🔧 Technical Decisions

### Real-time Updates: Polling vs Realtime

**Recommended: Polling (Option A)**

**Why:**
- ✅ Simple implementation
- ✅ No additional Appwrite config
- ✅ Works dengan free tier
- ✅ Sufficient for kantin use case (not ultra high-frequency)

**Implementation:**
```dart
Timer.periodic(Duration(seconds: 10), (timer) {
  ref.refresh(ordersProvider);
});
```

**Alternative: Appwrite Realtime (Option B)**
- More complex setup
- Real-time for instant updates
- Higher resource usage
- Recommend only if needed for scale

---

## 📋 Implementation Plan

### Week 1 (3-4 days)
**Day 1-2:** Tenant Order Dashboard
- Setup UI structure
- Implement order fetching & display
- Add filtering by status

**Day 3:** Order Status Management  
- Create `updateOrderStatus` function
- Deploy to Appwrite
- Integrate with tenant dashboard

**Day 4:** Testing & Bug Fixes
- End-to-end flow testing
- Fix permission issues
- Polish UI/UX

### Week 2 (2-3 days)
**Day 5:** Guest Real-time Tracking
- Implement polling mechanism
- Update status indicators
- Test with multiple orders

**Day 6-7:** Bonus Features (if time permits)
- Statistics dashboard
- Order history
- Sound notifications

---

## 🧪 Testing Checklist

### End-to-End Flow:
- [ ] Customer creates order via guest flow
- [ ] Order appears on tenant dashboard instantly
- [ ] Tenant changes status: Pending → Confirmed
- [ ] Guest tracking page shows updated status
- [ ] Tenant continues: Confirmed → Preparing → Ready
- [ ] Guest sees real-time updates
- [ ] Tenant marks as Completed
- [ ] Order moves to "Completed" section

### Edge Cases:
- [ ] Multiple orders dari different customers
- [ ] Rapid status updates (no race conditions)
- [ ] Network offline → retry mechanism
- [ ] Permission errors (handle gracefully)

---

## 🚨 Critical Considerations

### 1. Appwrite Function Slots
**Current:** 3/5 used
- `approve-registration`
- `createTenantUser`  
- `activateBusinessOwner`

**Needed for Sprint 4:** 1 function
- `updateOrderStatus`

**Remaining:** 1 slot (save for future)

### 2. Database Permissions
Ensure `orders` collection has:
- Tenant: Read (own orders), Update (own orders)
- Guest/Any: Create (new orders), Read (own orders via order_number)

### 3. Performance
With polling every 10s untuk 10 tenants = 6 requests/minute = acceptable
Monitor Appwrite usage on free tier

---

## 🎯 Definition of Done (Sprint 4)

Sprint 4 dianggap **COMPLETE** jika:
- ✅ Tenant dapat melihat orders real-time
- ✅ Tenant dapat update status pesanan
- ✅ Guest melihat status updates tanpa refresh manual
- ✅ End-to-end flow tested & working
- ✅ Documentation updated
- ✅ No critical bugs

---

## 📊 After Sprint 4

**MVP Feature-Complete!** 🎉

Next priorities:
1. **User Testing:** Test dengan real users (owner, tenant, customer)
2. **Bug Fixes:** Address feedback
3. **Performance Tuning:** Optimize database queries
4. **Production Deploy:** Prepare for launch
   - Setup production Appwrite project
   - Configure custom domain
   - Enable analytics
   - Setup error monitoring (Sentry)
5. **Marketing:** Prepare landing page, docs, tutorials

---

## 💡 Recommendation untuk Anda

### Option 1: Full Sprint 4 (Recommended)
**Duration:** 5-7 days  
**Result:** Complete MVP ready for testing

**Benefits:**
- Complete end-to-end flow
- Real order management
- Professional UX
- Ready to demo/launch

### Option 2: MVP Minimum (Quick)
**Duration:** 3-4 days  
**Result:** Basic order management

**Scope:**
- Task 1 + Task 2 only (dashboard + status update)
- Skip real-time tracking (manual refresh)
- No bonus features

**Use when:** Tight deadline, need to launch fast

### Option 3: Pause & Polish (Alternative)
**Duration:** 2-3 days  
**Result:** Improve Sprints 1-3 before Sprint 4

**Activities:**
- UI/UX improvements
- Add missing validations
- Performance optimizations
- Documentation
- Testing existing features

**Use when:** Want to ensure high quality before adding more features

---

## 🤔 My Recommendation

**Go with Option 1: Full Sprint 4**

**Why:**
- You've completed 75% already, finish strong!
- Order management is CORE to the app value
- It's the missing piece for a functional MVP
- Real-time updates are customer-facing (important UX)

**Next Steps:**
1. ✅ Review this document
2. ✅ Decide timeline (how many days can you commit?)
3. ✅ Start with Task 1: Tenant Order Dashboard
4. ✅ Deploy `updateOrderStatus` function early
5. ✅ Test incrementally (don't wait until end)

---

**Ready to start Sprint 4?** 🚀

I can help you with:
- Creating the order dashboard UI
- Writing the `updateOrderStatus` Appwrite Function  
- Implementing real-time polling
- Testing the complete flow
- Deploying to production

Let me know when you want to begin!
