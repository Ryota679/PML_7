# Testing Guide: Delete User & Cleanup Functions

## 🎯 **Objective**

Verifikasi comprehensive cascading delete untuk:
1. **Delete Tenant** → Hapus tenant + staff + products + orders
2. **Delete Business Owner** → Hapus business owner + semua tenant + semua staff + products + orders
3. **Cleanup Expired Contracts** → Auto-delete expired users dengan cascading

---

##  **Test 1: Delete Tenant (Manual via UI)**

### **Setup:**
1. Login sebagai **Business Owner**
2. Buat 1 tenant test:
   - Nama: "Test Warung Delete"
   - Assign ke tenant ID tertentu
3. Login sebagai Tenant "Test Warung Delete"
4. Buat 2-3 staff
5. Buat 3-5 products
6. Guest create 2-3 orders

### **Database State BEFORE Delete:**
```
users collection:
├─ Tenant (Test Warung Delete)
├─ Staff 1
├─ Staff 2
├─ Staff 3

products collection:
├─ Product A (tenant_id = Test Warung Delete)
├─ Product B
├─ Product C

orders collection:
├─ Order 1 (tenant_id = Test Warung Delete)
├─ Order 2
```

### **Execute Delete:**
1. Login sebagai **Business Owner**
2. Go to **Kelola User Tenant**
3. Find tenant "Test Warung Delete"
4. Click **⋮ → Delete Permanent**
5. Dialog confirm:
   ```
   Delete User Permanently?
   
   This will PERMANENTLY delete "Test Warung Delete" and ALL related data:
   - All staff users (3)
   - All products (5)
   - All orders (3)
   
   This action CANNOT be undone!
   ```
6. Click **DELETE PERMANENT**

### **Expected Result:**
✅ **Success message**: "User deleted successfully"

### **Verification Checklist:**

**Via Appwrite Console:**
- [ ] Tenant "Test Warung Delete" **HILANG** dari users collection
- [ ] Staff 1, 2, 3 **HILANG** dari users collection
- [ ] Products A, B, C **HILANG** dari products collection
- [ ] Orders  1, 2 **HILANG** dari orders collection

**Via Flutter App:**
- [ ] Tenant tidak muncul di "Kelola User Tenant"
- [ ] Staff tidak bisa login (Auth account deleted)
- [ ] Tenant tidak bisa login

**Via Function Logs (Console → Functions → delete-user → Executions → Latest):**
```
✅ Deleted 3 staff
✅ Deleted 5 products
✅ Deleted 3 orders
✅ Tenant deleted completely
```

---

## 🧪 **Test 2: Delete Business Owner (Manual via Console)**

### **Setup:**
1. Login sebagai **Admin**
2. Buat 1 Business Owner test:
   - Email: `test-owner@delete.com`
   - Password: `Test123!`
3. Login sebagai Business Owner test
4. Buat 2 tenants:
   - Tenant A
   - Tenant B
5. Untuk masing-masing tenant:
   - Buat 2 staff
   - Buat 3 products
   - Create 2 orders

### **Database State BEFORE Delete:**
```
Business Owner: test-owner@delete.com
└─ Tenant A
    ├─ Staff A1, A2
    ├─ Products (3)
    └─ Orders (2)
└─ Tenant B
    ├─ Staff B1, B2
    ├─ Products (3)
    └─ Orders (2)

TOTAL:
- 1 Business Owner
- 2 Tenants
- 4 Staff
- 6 Products
- 4 Orders
```

### **Execute Delete:**
**Via Appwrite Console → Functions → delete-user → Execute:**

```json
{
  "userId": "DOCUMENT_ID_TEST_OWNER",
  "deletedBy": "ADMIN_USER_ID",
  "force": true
}
```

### **Expected Result:**
```json
{
  "success": true,
  "message": "User deleted successfully",
  "data": {
    "deletedData": {
      "tenants": 2,
      "staff": 4,
      "products": 6,
      "orders": 4
    }
  }
}
```

### **Verification Checklist:**

**Via Appwrite Console:**
- [ ] Business Owner **HILANG** dari users collection & Auth
- [ ] Tenant A & B **HILANG** dari users collection & Auth
- [ ] Staff A1, A2, B1, B2 **HILANG** dari users collection & Auth
- [ ] 6 Products **HILANG** dari products collection
- [ ] 4 Orders **HILANG** dari orders collection

**Logs Verification:**
```
Found 2 tenants to delete
  📦 Deleting tenant: Tenant A
    ✅ Deleted 2 staff
    ✅ Deleted 3 products
    ✅ Deleted 2 orders
  📦 Deleting tenant: Tenant B
    ✅ Deleted 2 staff
    ✅ Deleted 3 products
    ✅ Deleted 2 orders
  ✅ Deleted 2 tenants total
```

---

## 🕐 **Test 3: Cleanup Expired Contracts (Automated)**

### **Setup:**
1. **Via Appwrite Console → Database → kantin-db → users collection**
2. Find 1 Tenant user
3. Edit document:
   - Set `contract_end_date` = `2025-12-03T00:00:00.000Z` (yesterday)
4. Note the tenant_id and check:
   - Berapa staff yang punya `tenant_id` ini
   - Berapa products
   - Berapa orders

### **Execute Cleanup:**
**Via Appwrite Console → Functions → cleanup-expired-contracts → Execute:**

```json
{}
```

(Empty payload - manual trigger)

### **Expected Result:**
```json
{
  "success": true,
  "message": "Cleanup completed. Deleted 1 expired users.",
  "summary": {
    "checked": 150,
    "expired": 1,
    "deleted": 1,
    "skipped": 0,
    "errors": 0,
    "deletedUsers": [
      {
        "userId": "xxx",
        "username": "tenant_test",
        "role": "tenant",
        "contractEndDate": "2025-12-03T00:00:00.000Z"
      }
    ]
  }
}
```

### **Verification Checklist:**

**Via Appwrite Console:**
- [ ] Expired tenant **HILANG** dari users
- [ ] Semua staff milik tenant **HILANG**
- [ ] Semua products **HILANG**
- [ ] Semua orders **HILANG**

**Logs Verification:**
```
Found 1 users with expired contracts
Processing tenant_test...
  ✅ Deleted 2 staff
  ✅ Deleted 5 products
  ✅ Deleted 3 orders
  ✅ User deleted successfully
```

---

## 🧪 **Test 4: Authorization Testing**

### **Test 4.1: Unauthorized Delete Attempt**

**Setup:** Login sebagai **Tenant A**, coba delete **Staff dari Tenant B**

**Execute:**
```json
{
  "userId": "STAFF_TENANT_B_DOC_ID",
  "deletedBy": "TENANT_A_USER_ID"
}
```

**Expected Result:**
```json
{
  "success": false,
  "error": "Unauthorized: You do not have permission to delete this user",
  "code": "UNAUTHORIZED"
}
```

✅ Staff B **TIDAK TERHAPUS**

### **Test 4.2: Tenant Delete Own Staff (Authorized)**

**Setup:** Login sebagai **Tenant A**, delete **Staff dari Tenant A sendiri**

**Execute:**
```json
{
  "userId": "STAFF_TENANT_A_DOC_ID",
  "deletedBy": "TENANT_A_USER_ID"
}
```

**Expected Result:**
```json
{
  "success": true,
  "message": "User deleted successfully"
}
```

✅ Staff A **TERHAPUS**

---

## 📊 **Test 5: Orphaned User Cleanup**

**Purpose:** Verify function can cleanup orphaned database records (Auth user sudah dihapus manual)

### **Setup:**
1. Create 1 test staff via Flutter
2. **Manual delete Auth account** via Appwrite Console → Auth → Users → Delete
3. Database record **masih ada** tapi Auth **sudah tidak ada**

### **Execute Delete:**
```json
{
  "userId": "ORPHANED_USER_DOC_ID",
  "deletedBy": "TENANT_USER_ID"
}
```

### **Expected Result:**
```json
{
 "success": true,
  "message": "User deleted successfully",
  "data": {
    "authDeleted": true
  }
}
```

**Logs:**
```
⚠️ Auth user not found (orphaned record) - continuing
✅ User deletion completed successfully
```

✅ Database record **TERHAPUS** (cleanup orphaned data)

---

## ✅ **Final Verification Checklist**

- [ ] **Test 1:** Tenant delete → staff/products/orders terhapus
- [ ] **Test 2:** Business Owner delete → semua tenant + staff + data terhapus
- [ ] **Test 3:** Cleanup expired → auto-cascade delete
- [ ] **Test 4.1:** Unauthorized delete → DITOLAK
- [ ] **Test 4.2:** Authorized delete → SUKSES
- [ ] **Test 5:** Orphaned cleanup → SUKSES

**Function Slots Used: 4/5** ✅
- delete-user
- cleanup-expired-contracts
- create-user
- approve-registration

**Slot tersedia untuk payment: 1** ✅

---

## 🎉 **Success Criteria**

Semua test PASSED jika:
1. ✅ Delete tenant → cascade ke staff/products/orders
2. ✅ Delete business owner → cascade ke semua tenant dan data mereka
3. ✅ Cleanup expired → auto-cascade sesuai role
4. ✅ Authorization berfungsi dengan benar
5. ✅ Orphaned records dibersihkan gracefully
6. ✅ Tidak ada error di function logs
7. ✅ Database tetap konsisten (tidak ada orphaned data)

**Jika semua passed → READY FOR PRODUCTION!** 🚀
