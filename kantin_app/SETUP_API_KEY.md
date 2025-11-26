# Setup Appwrite API Key untuk Admin Operations

## ⚠️ Penting!

API Key diperlukan agar Admin dapat membuat user baru saat **approve** registrasi Business Owner.

---

## 📝 Langkah-Langkah Setup:

### **Step 1: Buka Appwrite Console**

1. Buka browser dan masuk ke: https://fra.cloud.appwrite.io
2. Login dengan akun Anda
3. Pilih Project: **`perojek-pml`**

---

### **Step 2: Create API Key**

1. Di sidebar kiri, klik **"Settings"** (icon ⚙️)
2. Klik tab **"API Keys"**
3. Klik tombol **"Create API Key"**
4. Isi form:
   - **Name**: `Admin User Creation` (atau nama lain yang jelas)
   - **Expiration**: Pilih **"Never"** atau set tanggal sesuai kebutuhan
   - **Scopes**: 
     - ✅ **users.read** (optional, untuk debug)
     - ✅ **users.write** (**REQUIRED!**)
5. Klik **"Create"**

---

### **Step 3: Copy API Key**

1. Setelah dibuat, Appwrite akan menampilkan **API Key Secret**
2. **COPY API KEY** segera (hanya ditampilkan 1 kali!)
   ```
   Example: standard_1234567890abcdef...
   ```
3. **Simpan** di tempat aman (password manager, dll)

---

### **Step 4: Update Konfigurasi App**

1. Buka file:
   ```
   d:\Semester 6\Pml\PML_7\kantin_app\lib\core\config\appwrite_config.dart
   ```

2. Replace `YOUR_API_KEY_HERE` dengan API Key yang sudah di-copy:
   ```dart
   // Sebelum:
   static const String serverApiKey = 'YOUR_API_KEY_HERE';
   
   // Sesudah:
   static const String serverApiKey = 'standard_1234567890abcdef...';  // API Key Anda
   ```

3. **Save** file

---

### **Step 5: Restart App**

1. **Stop** aplikasi yang sedang berjalan (tekan `q` di terminal)
2. **Run** ulang:
   ```bash
   flutter run -d chrome
   ```

---

## ✅ Test Approve Functionality

### **1. Create Test Registration**
- Buka halaman `/register`
- Isi form registrasi dengan data test
- Klik **"Daftar"**

### **2. Login as Admin**
- Logout jika masih login
- Login dengan: `fuad@gmail.com`
- Masuk ke **Admin Dashboard**

### **3. Approve Registration**
- Klik tab **"Pending"**
- Klik tombol **"Approve"** pada test registration
- Dialog akan muncul:
  - **Temporary Password**: Isi password (min 8 karakter), contoh: `password123`
  - **Catatan**: Opsional
- Klik **"Setujui"**
- Temporary password akan ditampilkan di SnackBar (simpan!)

### **4. Test Business Owner Login**
- **Logout** dari admin
- **Login** dengan:
  - Email: email yang didaftarkan (test@business.com)
  - Password: temporary password yang tadi dibuat (password123)
- Jika berhasil, akan masuk ke **Business Owner Dashboard** ✅

---

## 🐛 Troubleshooting

### **Error: "Invalid API Key"**
- ✅ Check apakah API Key sudah di-copy dengan benar (tidak ada space/typo)
- ✅ Check scope `users.write` sudah dicentang saat create API key
- ✅ Check API Key belum expired

### **Error: "User already exists"**
- User dengan email tersebut sudah ada di Appwrite Auth
- Solusi: Hapus user di Appwrite Console → Auth → Users, lalu approve ulang

### **Error: "Unauthorized"**
- API Key tidak memiliki permission yang cukup
- Solusi: Delete API key lama, buat baru dengan scope `users.write`

---

## 🔒 Security Note

**⚠️ IMPORTANT FOR PRODUCTION:**

API Key yang disimpan di `appwrite_config.dart` akan **ter-expose** di client-side code!

**Solusi Production:**
1. ✅ **Appwrite Functions** (Recommended)
   - Create Appwrite Function untuk handle user creation
   - Call function dari Admin Dashboard
   
2. ✅ **Backend API**
   - Create Node.js/Python backend
   - Store API Key di environment variables
   - Call backend API dari Flutter app

3. ✅ **Environment Variables** (Flutter)
   - Use `--dart-define` untuk inject API Key saat build
   - API Key tidak akan hard-coded di source code

**Untuk MVP/Development**, current approach is acceptable.

---

## 📚 Dokumentasi Terkait

- [Appwrite API Keys](https://appwrite.io/docs/keys)
- [Appwrite Users API](https://appwrite.io/docs/server/users)
- [Appwrite Functions](https://appwrite.io/docs/functions)

---

**Created:** 2025-11-19  
**Last Updated:** 2025-11-19
