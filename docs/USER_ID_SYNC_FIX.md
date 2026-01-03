# User ID Synchronization Fix

## Problem

Ketika user baru dibuat (register), terjadi **mismatch** antara:
- **Auth User ID** (dari Appwrite Authentication)
- **Database Document ID** (dari Collection `users`)

### Contoh Kasus:
```
Auth ID:      69241145001332998ffa
Document ID:  6924114500204ea92d16  ❌ BERBEDA
```

Akibatnya:
- Tenant menyimpan `owner_id` = Auth ID
- Query `getDocument(owner_id)` akan **404** karena mencari Document ID yang salah
- Permission tidak berfungsi karena Document ID tidak cocok

---

## Root Cause

### File: `auth_repository.dart` (Line 119-122)

```dart
// ❌ SALAH: Auto-generate ID acak
final userDoc = await database.createDocument(
  databaseId: AppwriteConfig.databaseId,
  collectionId: AppwriteConfig.usersCollectionId,
  documentId: ID.unique(),  // Generate random ID
  data: {
    'user_id': user.$id,  // Auth ID disimpan di field, tapi Document ID berbeda
    // ...
  },
);
```

**Masalah:** `documentId: ID.unique()` membuat ID baru yang berbeda dari `user.$id`.

---

## Solution

### 1. Fix: registerCustomer() 

**File:** `lib/features/auth/data/auth_repository.dart`

**Before (Line 119-131):**
```dart
final userDoc = await database.createDocument(
  databaseId: AppwriteConfig.databaseId,
  collectionId: AppwriteConfig.usersCollectionId,
  documentId: ID.unique(),  // ❌
  data: {
    'user_id': user.$id,
    'username': name,
    'role': 'customer',
    //...
  },
);
```

**After:**
```dart
final userDoc = await database.createDocument(
  databaseId: AppwriteConfig.databaseId,
  collectionId: AppwriteConfig.usersCollectionId,
  documentId: user.$id,  // ✅ Use Auth ID directly
  data: {
    'user_id': user.$id,  // Redundant but kept for consistency
    'username': name,
    'role': 'customer',
    //...
  },
);
```

---

### 2. Fix: Business Owner Registration (Appwrite Function)

**File:** `functions/approve-registration/src/main.js`

**Before (Line 120-132):**
```javascript
await databases.createDocument(
  databaseId,
  usersCollectionId,
  ID.unique(),  // ❌
  {
    user_id: userId,
    role: 'owner_bussines',
    //...
  }
);
```

**After:**
```javascript
// ✅ BENAR
await databases.createDocument(
  databaseId,
  usersCollectionId,
  userId,  // Use Auth ID
  {
    user_id: userId,
    role: 'owner_bussines',
    //...
  }
);
```

---

### 3. Fix: Tenant User Creation (Appwrite Function)

**File:** `functions/create-user/src/main.js` (Line 302)

**Before:**
```javascript
documentId: ID.unique(),  // ❌
```

**After:**
```javascript
documentId: userId,  // ✅ Use Auth ID
```

---

### 4. Fix: Create Tenant User (Legacy Function)

**File:** `functions/create-tenant-user/src/main.js` (Line 113)

**Before:**
```javascript
documentId: ID.unique(),  // ❌
```

**After:**
```javascript
documentId: userId,  // ✅ Use Auth ID
```

---

### 3. Fix Existing Data (Manual untuk Testing)

**Untuk user Opoyo yang sudah terbuat:**

#### Step-by-Step Manual Fix di Appwrite Console:

##### A. Lihat & Copy Data Opoyo yang Lama

1. Buka **Appwrite Console** → **Database** → Collection **`users`** → Tab **Rows**
2. Cari & klik baris user **`opoyo`**
3. Di tab **Columns** atau view detail, **screenshot atau copy** semua field value:
   - `username`: `opoyo`
   - `role`: `owner_bussines`
   - `email`: `opoyo@gmail.com` 
   - `phone`: (jika ada)
   - `payment_status`: `trial` (jika ada)
   - `subscription_started_at`: (value-nya)
   - `subscription_expires_at`: (value-nya)
   - `selected_tenant_ids`: (jika ada)
   - `swap_used`: (true/false)
   - Dan semua field lain yang terisi

##### B. Hapus Dokumen Lama

4. Kembali ke list **Rows** → Cari baris `opoyo` lagi
5. Klik **titik 3** (menu) di baris tersebut
6. Pilih **Delete**
7. Konfirmasi penghapusan

##### C. Buat Dokumen Baru dengan ID Benar

8. Klik tombol **"+ Create row"** (atau "+ Create document")  
9. **PENTING:** Scroll ke PALING BAWAH form, cari field **"Document ID"** atau **"$id"**, ketik manual: `69241145001332998ffa`
10. Isi field-field berikut (sesuai data yang di-copy dari Step A):

   **Required Fields:**
   - **`user_id`**: `69241145001332998ffa` (sama dengan Document ID)
   - **`role`**: Pilih dari dropdown → **`owner_bussines`**
   - **`username`**: `opoyo`

   **Optional Fields (Isi sesuai data lama):**
   - **`tenant_id`**: Biarkan **NULL** (centang checkbox NULL)
   - **`contract_end_date`**: Biarkan **NULL** 
   - **`is_active`**: Pilih **`true`** dari dropdown
   - **`full_name`**: (kosongkan atau isi "Opoyo")
   - **`email`**: `opoyo@gmail.com` (UNCHECK NULL, lalu isi)
   - **`phone`**: (copy dari data lama jika ada, atau biarkan NULL)
   - **`sub_role`**: Biarkan **NULL**
   - **`created_by`**: Biarkan **NULL**
   - **`subscription_tier`**: (jika ada di data lama, copy)
   - **`subscription_started_at`**: (copy tanggal dari data lama, format: dd/mm/yyyy, UNCHECK NULL)
   - **`subscription_expires_at`**: (copy tanggal dari data lama, format: dd/mm/yyyy, UNCHECK NULL)
   - **`payment_status`**: `trial` (UNCHECK NULL, lalu isi)
   - **`auth_provider`**: `email` (atau copy dari data lama)
   - **`google_id`**: Biarkan **NULL**
   - **`invited_by`**: Biarkan **NULL**
   - **`current_tenants_count`**: Biarkan **NULL** (atau isi `0`)
   - **`manual_tenant_selection`**: Pilih **`NULL`** (atau `false`)
   - **`swap_used`**: Pilih **`NULL`** (jika sudah swap pilih `true`)
   - **`disabled_reason`**: Biarkan **NULL**
   - **`selection_submitted_at`**: Biarkan **NULL**

11. **Scroll ke bawah**, pastikan **Document ID** sudah terisi `69241145001332998ffa`
12. Klik tombol **"Create"** (merah)

##### D. Update Tenant `owner_id`

11. Buka **Database** → Collection **`tenants`** → Tab **Rows**
12. **Untuk Kafe Testing:**
    - Klik baris "Kafe Testing"
    - Edit field **`owner_id`** → Ganti ke `69241145001332998ffa`
    - **Update**
13. **Ulangi untuk Joyo Mebel:**
    - Edit `owner_id` → `69241145001332998ffa`
14. **Ulangi untuk Bengkel Motor:**
    - Edit `owner_id` → `69241145001332998ffa`

##### E. Testing

15. **Restart aplikasi** (`R` di terminal flutter atau stop & `flutter run`)
16. **Login sebagai Tenant** (Joyo):
    - Banner trial BO harus **muncul** ✅
17. **Login sebagai BO** (Opoyo):
    - Data tenant/kontrak/user harus **ter-load** ✅

---

## Testing

Setelah fix:

1. **Register user baru** (Customer/BO)
2. **Cek Database:**
   - Auth ID = Document ID ✓
3. **Login sebagai Tenant:**
   - Banner trial harus muncul ✓
4. **Login sebagai BO:**
   - Data tenant/kontrak/user harus ter-load ✓

---

## Impact

- **User Baru:** Otomatis sinkron, tidak perlu manual
- **User Lama:** Perlu fix manual seperti langkah di atas (one-time)
- **Production:** Setelah deploy fix ini, tidak akan ada mismatch lagi

---

## Files Modified

1. ✅ `lib/features/auth/data/auth_repository.dart` (Customer registration)
2. ✅ `functions/approve-registration/src/main.js` (Business Owner approval)
3. ✅ `functions/create-user/src/main.js` (Tenant + Staff creation)
4. ✅ `functions/create-tenant-user/src/main.js` (Legacy tenant creation)
5. 🔧 Manual data fix di Appwrite Console (one-time untuk data Opoyo)

---

**Status:** CRITICAL - Harus di-fix sebelum production
**Estimasi:** 15 menit coding + 10 menit testing
