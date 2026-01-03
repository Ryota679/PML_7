# Deployment Guide: Delete User & Cleanup Expired Contracts

## 🎯 Overview

Panduan untuk deploy 2 Appwrite functions baru:
1. **delete-user** - Delete user dengan cascading cleanup
2. **cleanup-expired-contracts** - Scheduled cleanup expired users

---

## ⚠️ PENTING: Hapus Function Lama Dulu!

Sebelum deploy function baru, **WAJIB hapus 3 function lama** untuk free up space (limit 5 functions):

### Cara Hapus Function di Appwrite Console:

1. Buka: https://cloud.appwrite.io/console
2. Login → Pilih project: **perojek-pml**
3. Menu sidebar → **Functions**
4. Hapus function berikut (satu per satu):

#### Function 1: createStaffUser
- Klik function "Create Staff User" atau ID: `createStaffUser`
- Tab **Settings** (paling kanan)
- Scroll ke bawah → **Delete Function** → Confirm

#### Function 2: createTenantUser  
- Klik function "Create Tenant User" atau ID: `createTenantUser`
- Tab **Settings** → **Delete Function** → Confirm

#### Function 3: activateBusinessOwner
- Klik function "Activate Business Owner" atau ID: `activateBusinessOwner`
- Tab **Settings** → **Delete Function** → Confirm

### Verifikasi:
Setelah dihapus, Anda harus punya **2 functions tersisa**:
- ✅ approve-registration (ID: 691d57860017535b860c)
- ✅ create-user

**Status: 2/5 functions** (ready untuk tambah 3 function baru!)

---

## 📦 Step 1: Deploy Function delete-user

### A. Install Dependencies

```powershell
cd d:\projek_mobile\PML_7\kantin_app\functions\delete-user
npm install
```

### B. Create Function di Appwrite Console

1. Console → Functions → **Create function**
2. Settings:
   - **Function ID:** `delete-user`
   - **Name:** Delete User
   - **Runtime:** Node.js (18.0)
   - **Entrypoint:** `src/main.js`
   - **Execute Access:** `any` (authenticated users can call)
   - **Timeout:** 30 seconds

3. **Environment Variables** (tab Variables):
   - `DATABASE_ID` = `kantin-db`
   - `USERS_COLLECTION_ID` = `users`
   - `PRODUCTS_COLLECTION_ID` = `products`
   - `ORDERS_COLLECTION_ID` = `orders`
   - `TENANTS_COLLECTION_ID` = `tenants`

4. **Permissions** (tab Settings):
   - API Key: Use existing or create new with scopes:
     - `users.write`
     - `documents.write`
     - `documents.delete`

### C. Deploy Function

#### Opsi 1: Via Appwrite CLI (Recommended)

```powershell
# Pastikan sudah login
appwrite login

# Deploy function
appwrite deploy function --functionId delete-user
```

#### Opsi 2: Manual Upload

1. Zip folder `delete-user` (include node_modules)
2. Console → Functions → delete-user → Deployments
3. **Create deployment** → Upload ZIP
4. Wait for build to complete

### D. Test Function

Test via Console → Functions → delete-user → Execute:

```json
{
  "userId": "TEST_USER_DOC_ID",
  "force": false
}
```

Expected response:
```json
{
  "success": true,
  "message": "User deleted successfully",
  "data": {
    "deletedData": {
      "products": 0,
      "orders": 0,
      "tenants": 0
    }
  }
}
```

---

## 📦 Step 2: Deploy Function cleanup-expired-contracts

### A. Install Dependencies

```powershell
cd d:\projek_mobile\PML_7\kantin_app\functions\cleanup-expired-contracts
npm install
```

### B. Create Function di Appwrite Console

1. Console → Functions → **Create function**
2. Settings:
   - **Function ID:** `cleanup-expired-contracts`
   - **Name:** Cleanup Expired Contracts
   - **Runtime:** Node.js (18.0)
   - **Entrypoint:** `src/main.js`
   - **Execute Access:** `any`
   - **Timeout:** 60 seconds

3. **Environment Variables** (same as delete-user):
   - `DATABASE_ID` = `kantin-db`
   - `USERS_COLLECTION_ID` = `users`
   - `ORDERS_COLLECTION_ID` = `orders`

### C. Deploy Function

```powershell
appwrite deploy function --functionId cleanup-expired-contracts
```

### D. Setup Schedule

1. Console → Functions → cleanup-expired-contracts
2. Tab **Settings**
3. **Schedule** section:
   - **Cron Expression:** `0 0 * * *`
     (Daily at 00:00 UTC = 07:00 WIB pagi)
   - **Enable Schedule:** ON

4. Save changes

### E. Test Manual Execution

Tab **Execute** → Run empty payload `{}`

Expected response:
```json
{
  "success": true,
  "message": "Cleanup completed. Deleted 0 expired users.",
  "summary": {
    "checked": 5,
    "expired": 2,
    "deleted": 1,
    "skipped": 1,
    "errors": 0
  }
}
```

---

## ✅ Verification Checklist

### Functions Status:
- [ ] Function lama **dihapus** (createStaffUser, createTenantUser, activateBusinessOwner)
- [ ] Function `delete-user` **deployed & active**
- [ ] Function `cleanup-expired-contracts` **deployed & active**
- [ ] Schedule enabled untuk cleanup function
- [ ] Total functions: **4/5** (approve-registration, create-user, delete-user, cleanup-expired-contracts)

### Testing:
- [ ] Test delete-user via Console (berhasil delete test user)
- [ ] Test cleanup manual execution (response success)
- [ ] Verify schedule dijalankan sesuai cron (check Executions tab besok pagi)

---

## 🔧 Troubleshooting

### Error: "Missing required field: userId"
**Fix:** Pastikan payload berisi `{"userId": "DOCUMENT_ID"}`

### Error: "User not found in database"
**Fix:** userId adalah Document ID di collection `users`, bukan Auth user_id

### Error: "Cannot delete business owner with active tenants"
**Fix:** Gunakan `{"userId": "xxx", "force": true}` untuk force delete

### Schedule tidak jalan
**Fix:** 
1. Verify cron expression benar: `0 0 * * *`
2. Check tab Executions untuk error logs
3. Pastikan schedule enabled

### Build failed saat deploy
**Fix:**
1. Pastikan `npm install` sudah dijalankan
2. Check `package.json` sudah benar
3. Verify node_modules folder ada

---

## 📊 Monitoring

### Check Cleanup Results:
1. Console → Functions → cleanup-expired-contracts
2. Tab **Executions**
3. Klik execution terakhir → Lihat LOGS
4. Summary akan menampilkan:
   - Berapa user checked
   - Berapa deleted
   - Berapa skipped (ada active orders)

### Check Delete User Logs:
Same steps, tapi untuk function `delete-user`

---

## 🚀 Next Steps (Setelah Deploy)

1. **Update Flutter App:**
   - Build & test delete user dari UI
   - Verify cascading delete works

2. **Monitor for 1 week:**
   - Check cleanup execution logs
   - Verify tidak ada false positive deletions

3. **Future Enhancements:**
   - Add email notification sebelum delete
   - Grace period (warning 7 hari sebelum delete)
   - Soft delete option

---

**Deployment Complete!** 🎉

Total Functions: **4/5**
1. approve-registration ✅
2. create-user ✅
3. delete-user ✅ (NEW)
4. cleanup-expired-contracts ✅ (NEW)
5. (Reserved for payment integration)
