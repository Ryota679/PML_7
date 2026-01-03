# ⚡ Quick Setup Guide

## ✅ Konfigurasi Sudah Diupdate

Kredensial Appwrite sudah tersimpan di `lib/core/config/appwrite_config.dart`:
- **Endpoint**: https://fra.cloud.appwrite.io/v1
- **Project ID**: perojek-pml
- **Database ID**: kantin-db

## 📋 Langkah Selanjutnya

### 1. Pastikan Koleksi Database Sudah Dibuat

Login ke Appwrite Console: https://cloud.appwrite.io

Buka **Databases** → **kantin-db** → Pastikan ada 5 koleksi:

#### ✅ Koleksi 1: `users`
Collection ID: **users**

| Atribut | Tipe | Size | Required | Array | Default |
|---------|------|------|----------|-------|---------|
| user_id | String | 255 | ✅ | ❌ | - |
| role | String | 50 | ✅ | ❌ | - |
| username | String | 255 | ✅ | ❌ | - |
| tenant_id | String | 255 | ❌ | ❌ | null |
| contract_end_date | DateTime | - | ❌ | ❌ | null |
| is_active | Boolean | - | ❌ | ❌ | true |

**Indexes:**
- user_id: UNIQUE
- role: KEY
- tenant_id: KEY

**Permissions:**
- Read: Users
- Create: None (hanya via Functions/Admin)
- Update: None
- Delete: None

---

#### ✅ Koleksi 2: `tenants`
Collection ID: **tenants**

| Atribut | Tipe | Size | Required | Array | Default |
|---------|------|------|----------|-------|---------|
| owner_user_id | String | 255 | ✅ | ❌ | - |
| name | String | 255 | ✅ | ❌ | - |
| type | String | 100 | ✅ | ❌ | - |
| description | String | 1000 | ✅ | ❌ | - |
| logoUrl | String | 500 | ❌ | ❌ | null |
| status | String | 50 | ❌ | ❌ | active |
| qrCodeUrl | String | 500 | ❌ | ❌ | null |

**Indexes:**
- owner_user_id: KEY

**Permissions:**
- Read: Any (untuk guest bisa lihat daftar tenant)
- Create: Users (hanya user login)
- Update: Users
- Delete: Users

---

#### ✅ Koleksi 3: `categories`
Collection ID: **categories**

| Atribut | Tipe | Size | Required | Array | Default |
|---------|------|------|----------|-------|---------|
| tenant_id | String | 255 | ✅ | ❌ | - |
| name | String | 255 | ✅ | ❌ | - |

**Indexes:**
- tenant_id: KEY

**Permissions:**
- Read: Any
- Create: Users
- Update: Users
- Delete: Users

---

#### ✅ Koleksi 4: `products`
Collection ID: **products**

| Atribut | Tipe | Size | Required | Array | Default |
|---------|------|------|----------|-------|---------|
| tenant_id | String | 255 | ✅ | ❌ | - |
| category_id | String | 255 | ✅ | ❌ | - |
| name | String | 255 | ✅ | ❌ | - |
| price | Double | - | ✅ | ❌ | - |
| image_url | String | 500 | ❌ | ❌ | null |
| is_available | Boolean | - | ❌ | ❌ | true |
| description | String | 1000 | ❌ | ❌ | null |

**Indexes:**
- tenant_id: KEY
- category_id: KEY
- is_available: KEY

**Permissions:**
- Read: Any
- Create: Users
- Update: Users
- Delete: Users

---

#### ✅ Koleksi 5: `orders`
Collection ID: **orders**

| Atribut | Tipe | Size | Required | Array | Default |
|---------|------|------|----------|-------|---------|
| tenant_id | String | 255 | ✅ | ❌ | - |
| customerName | String | 255 | ✅ | ❌ | - |
| items | String | 5000 | ✅ | ❌ | - |
| totalPrice | Double | - | ✅ | ❌ | - |
| status | String | 50 | ❌ | ❌ | pending |

**Indexes:**
- tenant_id: KEY
- status: KEY

**Permissions:**
- Read: Any
- Create: Any (guest bisa membuat pesanan)
- Update: Users
- Delete: Users

---

### 2. Enable Authentication

1. Buka **Auth** → **Settings**
2. Enable **Email/Password**
3. (Opsional) Disable **Email Verification** untuk testing

---

### 3. Buat Test User (Business Owner)

#### Di Appwrite Console:

1. **Buat User di Auth:**
   - Buka **Auth** → **Users** → **Create User**
   - Email: `owner@test.com`
   - Password: `password123`
   - Name: `Test Owner`
   - **CATAT USER ID** yang dibuat (misal: `6478abc123...`)

2. **Buat Dokumen di Koleksi users:**
   - Buka **Databases** → **kantin-db** → **users** → **Add Document**
   - Isi data:
     ```json
     {
       "user_id": "PASTE_USER_ID_DARI_AUTH_DISINI",
       "role": "owner_business",
       "username": "Test Owner",
       "tenant_id": null,
       "contract_end_date": null,
       "is_active": true
     }
     ```
   - Klik **Create**

---

### 4. Test Aplikasi

Sekarang jalankan aplikasi:

```bash
flutter run
```

**Login dengan:**
- Email: `owner@test.com`
- Password: `password123`

Jika berhasil, Anda akan masuk ke **Business Owner Dashboard**.

---

## ⚠️ Troubleshooting

### Error: "Collection not found"
- Pastikan Collection ID sama persis: `users`, `tenants`, `products`, `categories`, `orders`
- Collection ID case-sensitive

### Error: "Invalid credentials"
- Pastikan email dan password benar
- Pastikan user sudah dibuat di Auth

### Error: "User profile not found"
- Pastikan sudah membuat dokumen di koleksi `users`
- Pastikan `user_id` di dokumen sama dengan User ID di Auth

### Error: "Unauthorized"
- Periksa permissions di setiap koleksi
- Untuk testing, set Read: Any, Create/Update/Delete: Users

---

## 📞 Butuh Bantuan?

Jika ada error saat menjalankan, screenshot error dan saya akan bantu debug!

**Status Saat Ini:**
- ✅ Konfigurasi Appwrite sudah diupdate
- ⏳ Menunggu setup koleksi di Appwrite Console
- ⏳ Menunggu pembuatan test user
