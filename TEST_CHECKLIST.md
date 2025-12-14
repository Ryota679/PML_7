# ✅ Testing Checklist - Sprint 1

## 🔧 Pre-Testing Setup

### ✅ Konfigurasi (SUDAH SELESAI)
- [x] Endpoint: `https://fra.cloud.appwrite.io/v1`
- [x] Project ID: `perojek-pml`
- [x] Database ID: `kantin-db`

### ✅ Database (SUDAH ADA)
- [x] Koleksi `users` sudah dibuat
- [x] Koleksi `tenants` sudah dibuat
- [x] Koleksi `products` sudah dibuat
- [x] Koleksi `categories` sudah dibuat
- [x] Koleksi `orders` sudah dibuat

### ✅ Test User (SUDAH ADA)
- [x] User di Auth sudah dibuat
- [x] Dokumen di koleksi `users` sudah dibuat

---

## 🚀 Cara Test Aplikasi

### 1. Run Aplikasi

Buka terminal di folder `kantin_app` dan jalankan:

```bash
flutter run
```

**Pilih device:**
- Windows: Pilih `Windows (desktop)`
- Chrome: Pilih `Chrome (web-javascript)`
- Android Emulator: Pilih emulator yang running

### 2. Test Login Flow

#### Test Case 1: Login Business Owner ✅

**Langkah:**
1. Aplikasi terbuka, akan muncul halaman Login
2. Masukkan credentials test user:
   - Email: `owner@test.com`
   - Password: `password123`
3. Klik tombol **"Masuk"**

**Expected Result:**
- ✅ Loading indicator muncul
- ✅ Redirect ke **Business Owner Dashboard**
- ✅ Muncul nama user di dashboard
- ✅ Muncul chip dengan label `owner_business`
- ✅ Muncul 4 menu card (Kelola Tenant, Kelola User, Laporan, Kategori)

**Jika Error:**
- Screenshot error message
- Check console log
- Verifikasi user_id di koleksi `users` sama dengan User ID di Auth

---

#### Test Case 2: Auto Session Check ✅

**Langkah:**
1. Setelah berhasil login, **tutup aplikasi** (jangan logout)
2. **Jalankan ulang** aplikasi: `flutter run`

**Expected Result:**
- ✅ Langsung masuk ke dashboard (tidak perlu login lagi)
- ✅ Session tersimpan

---

#### Test Case 3: Logout ✅

**Langkah:**
1. Di dashboard, klik icon **Logout** di app bar (pojok kanan atas)
2. Dialog konfirmasi muncul
3. Klik **"Logout"**

**Expected Result:**
- ✅ Redirect ke halaman Login
- ✅ Session dihapus

---

#### Test Case 4: Login dengan Kredensial Salah ❌

**Langkah:**
1. Di halaman login, masukkan:
   - Email: `wrong@test.com`
   - Password: `wrongpass`
2. Klik **"Masuk"**

**Expected Result:**
- ✅ Muncul SnackBar dengan pesan error
- ✅ Tetap di halaman login
- ✅ Tidak crash

---

#### Test Case 5: Validasi Form ✅

**Langkah:**
1. Di halaman login, coba submit form kosong
2. Coba masukkan email tanpa @ (misal: `testemail`)
3. Coba password kurang dari 8 karakter

**Expected Result:**
- ✅ Muncul error message di bawah field
- ✅ Tombol tidak bisa diklik hingga valid
- ✅ Validasi bekerja

---

#### Test Case 6: Forgot Password ✅

**Langkah:**
1. Klik **"Lupa Password?"**
2. Masukkan email yang terdaftar
3. Klik **"Kirim"**

**Expected Result:**
- ✅ Dialog tertutup
- ✅ Muncul SnackBar "Email reset password telah dikirim"
- ✅ (Check email untuk link reset - opsional)

---

## 🎯 Test Results Summary

| Test Case | Status | Notes |
|-----------|--------|-------|
| Login Business Owner | ⏳ | Menunggu test manual |
| Auto Session Check | ⏳ | Menunggu test manual |
| Logout | ⏳ | Menunggu test manual |
| Login Kredensial Salah | ⏳ | Menunggu test manual |
| Validasi Form | ⏳ | Menunggu test manual |
| Forgot Password | ⏳ | Menunggu test manual |

---

## 🐛 Common Issues & Solutions

### Issue 1: "Collection not found"
**Penyebab:** Collection ID tidak cocok
**Solusi:** 
- Pastikan Collection ID di Appwrite Console sama persis: `users`, `tenants`, dll
- Case-sensitive!

### Issue 2: "User profile not found"
**Penyebab:** Dokumen user belum dibuat di koleksi `users`
**Solusi:**
- Buat dokumen di koleksi `users` dengan:
  - `user_id` = User ID dari Auth
  - `role` = `owner_business`
  - `username` = nama apapun

### Issue 3: "Invalid credentials"
**Penyebab:** Email atau password salah
**Solusi:**
- Verifikasi email dan password di Appwrite Auth
- Reset password jika perlu

### Issue 4: App tidak bisa compile
**Penyebab:** Dependencies belum terinstall
**Solusi:**
```bash
flutter clean
flutter pub get
flutter run
```

### Issue 5: "Unauthorized" atau "Permission denied"
**Penyebab:** Permissions koleksi belum diset
**Solusi:**
- Koleksi `users`: Read = Users
- Koleksi lain: Read = Any, Create/Update/Delete = Users

---

## 📸 Screenshot Checklist

Untuk dokumentasi, ambil screenshot:

1. ✅ Halaman Login
2. ✅ Business Owner Dashboard setelah login
3. ✅ Dialog Logout
4. ✅ Error message saat kredensial salah
5. ✅ Validasi form

---

## ✅ Sprint 1 Completion Criteria

Sprint 1 dianggap selesai jika:

- [x] Aplikasi bisa di-run tanpa error
- [ ] Login berhasil dengan user yang valid
- [ ] Redirect ke dashboard sesuai role
- [ ] Session tersimpan (auto-login)
- [ ] Logout berhasil
- [ ] Error handling bekerja
- [ ] UI responsive dan sesuai design

---

## 🎉 Next Steps

Setelah semua test case ✅:

1. **Update dokumentasi** dengan screenshot
2. **Commit code** ke repository
3. **Siap lanjut Sprint 2**: Manajemen Tenant & Products

---

## 💬 Feedback

Jika ada error atau masalah saat testing:
1. Screenshot error message
2. Check console log (red text)
3. Catat langkah yang menyebabkan error
4. Laporkan untuk debugging

**Good luck testing! 🚀**
