# 🔐 Admin Registration & Approval Feature

## 📋 Overview

Fitur ini memungkinkan Business Owner mendaftar secara mandiri melalui form registrasi publik, kemudian menunggu approval dari System Admin sebelum akun dibuat.

**Flow:**
```
Calon Business Owner → Isi Form Registrasi → Submit → Status: Pending
                                                          ↓
                                          Admin Review di Dashboard
                                                          ↓
                                                    Approve/Reject
                                                          ↓
                                    Akun Business Owner dibuat (jika approved)
```

---

## 🗄️ Database Structure

### **Koleksi Baru: `registration_requests`**

| Atribut | Tipe | Required | Default | Index |
|---------|------|----------|---------|-------|
| `full_name` | String (255) | ✅ | - | - |
| `email` | String (255) | ✅ | - | KEY |
| `password_hash` | String (500) | ✅ | - | - |
| `business_name` | String (255) | ✅ | - | - |
| `business_type` | String (100) | ✅ | - | - |
| `phone` | String (20) | ❌ | null | - |
| `status` | String (50) | ✅ | `pending` | KEY |
| `admin_notes` | String (1000) | ❌ | null | - |
| `reviewed_by` | String (255) | ❌ | null | - |
| `reviewed_at` | DateTime | ❌ | null | - |

**Status values:**
- `pending` - Menunggu review
- `approved` - Disetujui
- `rejected` - Ditolak

**Permissions:**
- Create: `Any` (siapa saja bisa daftar)
- Read: `Users` (hanya user login)
- Update: `Users` (hanya admin)
- Delete: `Users` (hanya admin)

---

### **Update Koleksi: `users`**

**Role enum updated:**
```
owner_business
tenant
guest
adminsystem  ← BARU
```

---

## 👤 System Admin User

**Kredensial Admin:**
- Email: `fuad@gmail.com`
- Role: `adminsystem`
- User ID: `691c3b7700180772f7d5`

**Setup:**
1. User sudah dibuat di **Auth**
2. Dokumen sudah dibuat di koleksi **users**

---

## 🏗️ Implementasi

### **1. Files Created**

#### **Models:**
- `lib/shared/models/registration_request_model.dart`
  - Model untuk registration request
  - Helper methods: `isPending`, `isApproved`, `isRejected`, `statusLabel`

#### **Repository:**
- `lib/features/admin/data/registration_repository.dart`
  - `getPendingRequests()` - Get semua pending requests
  - `getAllRequests()` - Get requests dengan filter
  - `approveRequest()` - Approve request
  - `rejectRequest()` - Reject request
  - `createRequest()` - Create new request (untuk form publik)

#### **Providers:**
- `lib/features/admin/providers/registration_provider.dart`
  - `registrationRepositoryProvider`
  - `registrationRequestsProvider` - State management
  - `pendingRequestsCountProvider` - Pending count badge

#### **UI:**
- `lib/features/admin/presentation/admin_dashboard.dart`
  - Dashboard admin dengan list requests
  - Filter tabs (Pending, Approved, Rejected, All)
  - Approve/Reject buttons dengan dialog notes
  - Refresh indicator
  - Empty state

---

### **2. Router Update**

**Updated:** `lib/core/router/app_router.dart`

**Added route:**
```dart
GoRoute(
  path: '/admin',
  builder: (context, state) => const AdminDashboard(),
),
```

**Redirect logic:**
- Role `adminsystem` → `/admin`
- Role `owner_business` → `/business-owner`
- Role `tenant` → `/tenant`

---

### **3. Config Update**

**Updated:** `lib/core/config/appwrite_config.dart`

```dart
static const String registrationRequestsCollectionId = 'registration_requests';
```

---

## 🎨 Admin Dashboard Features

### **Filter Tabs:**
- **Pending** (Orange) - Menunggu review
- **Approved** (Green) - Sudah disetujui
- **Rejected** (Red) - Ditolak
- **Semua** (Blue) - Semua status

### **Request Card:**
Menampilkan:
- ✅ Nama lengkap & email
- ✅ Status badge (color-coded)
- ✅ Business name & type
- ✅ Phone (jika ada)
- ✅ Tanggal pendaftaran
- ✅ Admin notes (jika ada)
- ✅ Action buttons (untuk pending):
  - **Tolak** (red outline) - Meminta alasan penolakan
  - **Setujui** (green filled) - Opsional catatan

### **Features:**
- ✅ Pull to refresh
- ✅ Empty state indicators
- ✅ Loading states
- ✅ Error handling
- ✅ Confirmation dialogs
- ✅ Snackbar notifications
- ✅ Pending count badge di AppBar
- ✅ Logout button

---

## 🚀 Testing Guide

### **1. Test Admin Login:**

**Steps:**
1. Run aplikasi: `flutter run -d windows`
2. Di halaman login, masukkan:
   - Email: `fuad@gmail.com`
   - Password: `[password yang Anda set]`
3. Klik "Masuk"

**Expected:**
- ✅ Redirect ke **Admin Dashboard**
- ✅ Tampil "Admin Dashboard" di AppBar
- ✅ Filter tabs tampil (Pending, Approved, Rejected, All)
- ✅ Jika belum ada data: Empty state "Tidak ada pendaftaran"

---

### **2. Test with Mock Data:**

**Create mock registration request di Appwrite Console:**

1. Buka Databases → kantin-db → registration_requests
2. Klik "Create row"
3. Isi data:
   ```json
   {
     "full_name": "John Doe",
     "email": "john@example.com",
     "password_hash": "password123",
     "business_name": "Warung John",
     "business_type": "Ruko Kuliner",
     "phone": "081234567890",
     "status": "pending"
   }
   ```
4. Klik "Create"

**Back to app:**
- Pull down to refresh
- Request card should appear
- Test "Approve" and "Reject" buttons

---

### **3. Test Filter Tabs:**

1. Create multiple requests dengan status berbeda:
   - 2 pending
   - 1 approved (manual update status di Console)
   - 1 rejected (manual update status di Console)

2. Test setiap filter tab:
   - **Pending** → Should show 2 requests
   - **Approved** → Should show 1 request
   - **Rejected** → Should show 1 request
   - **Semua** → Should show all 4 requests

---

### **4. Test Approve Flow:**

1. Pilih request dengan status pending
2. Klik "Setujui"
3. Dialog muncul "Catatan (opsional)"
4. Isi catatan atau kosongkan
5. Klik "Simpan"

**Expected:**
- ✅ Request hilang dari Pending tab
- ✅ Snackbar hijau: "Pendaftaran [nama] disetujui"
- ✅ Request muncul di Approved tab dengan catatan admin

---

### **5. Test Reject Flow:**

1. Pilih request dengan status pending
2. Klik "Tolak"
3. Dialog muncul "Alasan penolakan (wajib)"
4. Coba klik "Simpan" tanpa isi → Error "Catatan tidak boleh kosong"
5. Isi alasan penolakan
6. Klik "Simpan"

**Expected:**
- ✅ Request hilang dari Pending tab
- ✅ Snackbar orange: "Pendaftaran [nama] ditolak"
- ✅ Request muncul di Rejected tab dengan alasan penolakan

---

## ⚠️ Known Limitations

### **1. User Creation Not Implemented Yet**

Saat ini fungsi `approveRequest()` hanya **update status** menjadi `approved`, tetapi **tidak membuat user** di Appwrite Auth.

**Why:**
- Creating user requires **admin privileges**
- Cannot be done from client side
- Need **Appwrite Function** (server-side)

**Next Steps:**
- Create Appwrite Function `approveBusinessOwner`
- Function akan:
  1. Create user di Auth dengan `createUser()`
  2. Create dokumen di koleksi `users`
  3. Update status registration request
  4. Send email notification (optional)

---

### **2. Password Hashing**

Saat ini password disimpan **plain text** di `password_hash`.

**Production:**
- Implement proper password hashing (bcrypt/argon2)
- Hash di server side (Appwrite Function)

---

## 📅 Future Features (Public Registration Form)

**Belum diimplementasi:**
- Halaman `/register` untuk public
- Form registrasi Business Owner
- Email verification
- Recaptcha
- Email notifications

**Estimation:** Sprint 2 Extended

---

## ✅ Checklist Setup

Pastikan sebelum testing:

- [x] Koleksi `registration_requests` sudah dibuat
- [x] User admin `fuad` sudah dibuat di Auth
- [x] Dokumen user admin sudah dibuat di koleksi `users`
- [x] Role enum `adminsystem` sudah ditambahkan di koleksi `users`
- [x] App sudah di-restart untuk pickup perubahan code
- [ ] Test login admin berhasil
- [ ] Test tampilan dashboard
- [ ] Test filter tabs berfungsi
- [ ] Test approve/reject flow

---

## 🐛 Troubleshooting

### **Error: "Collection registration_requests not found"**
**Fix:** Pastikan nama collection ID persis `registration_requests` (lowercase, underscore)

### **Error: "User profile not found" saat login admin**
**Fix:** Pastikan dokumen user admin sudah dibuat di koleksi `users` dengan `user_id` yang match

### **Admin tidak redirect ke dashboard**
**Fix:** 
1. Check role di dokumen users = `adminsystem` (exact match, lowercase)
2. Restart app dengan `flutter run`
3. Clear session dan login ulang

### **Empty state terus muncul padahal ada data**
**Fix:**
1. Check permissions koleksi `registration_requests`: Read = Users
2. Pull down to refresh
3. Check console log untuk error

---

## 📞 Contact & Support

Jika ada issue saat implementation atau testing, screenshot error dan console log! 🚀
