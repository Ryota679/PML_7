# Setup Appwrite untuk Tenant QR-Order

## 📋 Daftar Isi
1. [Konfigurasi Project](#konfigurasi-project)
2. [Setup Database](#setup-database)
3. [Setup Authentication](#setup-authentication)
4. [Testing](#testing)

---

## 🔧 Konfigurasi Project

### 1. Dapatkan Kredensial Appwrite

Anda sudah memiliki database Appwrite. Sekarang perlu mendapatkan:

1. **Project ID**: Dari dashboard Appwrite → Settings → Project ID
2. **Database ID**: Dari Databases → pilih database Anda → Settings → Database ID
3. **Collection IDs**: Dari setiap koleksi (users, tenants, products, categories, orders)

### 2. Update Konfigurasi di Aplikasi

Buka file `lib/core/config/appwrite_config.dart` dan update:

```dart
class AppwriteConfig {
  static const String endpoint = 'https://cloud.appwrite.io/v1';
  static const String projectId = 'YOUR_PROJECT_ID'; // Ganti dengan Project ID Anda
  static const String databaseId = 'YOUR_DATABASE_ID'; // Ganti dengan Database ID Anda
  
  // Collection IDs - Ganti dengan ID koleksi Anda
  static const String usersCollectionId = 'users';
  static const String tenantsCollectionId = 'tenants';
  static const String productsCollectionId = 'products';
  static const String categoriesCollectionId = 'categories';
  static const String ordersCollectionId = 'orders';
}
```

---

## 🗄️ Setup Database

Pastikan Anda sudah membuat koleksi-koleksi berikut sesuai dengan dokumen **erd.md** dan **data_collections.md**:

### 1. Koleksi `users`

| Atribut | Tipe | Required | Indeks |
|---------|------|----------|--------|
| user_id | String | ✅ | Unique |
| role | String (Enum) | ✅ | Key |
| username | String | ✅ | - |
| tenant_id | String | ❌ | Key |
| contract_end_date | DateTime | ❌ | Key |
| is_active | Boolean | ❌ (default: true) | - |

**Enum untuk `role`**: `owner_business`, `tenant`, `guest`

### 2. Koleksi `tenants`

| Atribut | Tipe | Required | Indeks |
|---------|------|----------|--------|
| owner_user_id | String | ✅ | Key |
| name | String | ✅ | - |
| type | String | ✅ | - |
| description | String | ✅ | - |
| logoUrl | String | ❌ | - |
| status | String (Enum) | ❌ (default: 'active') | - |
| qrCodeUrl | String | ❌ | - |

**Enum untuk `status`**: `active`, `inactive`

### 3. Koleksi `products`

| Atribut | Tipe | Required | Indeks |
|---------|------|----------|--------|
| tenant_id | String | ✅ | Key |
| category_id | String | ✅ | Key |
| name | String | ✅ | - |
| price | Double | ✅ | - |
| image_url | String | ❌ | - |
| is_available | Boolean | ❌ (default: true) | Key |
| description | String | ❌ | - |

### 4. Koleksi `categories`

| Atribut | Tipe | Required | Indeks |
|---------|------|----------|--------|
| tenant_id | String | ✅ | Key |
| name | String | ✅ | - |

### 5. Koleksi `orders`

| Atribut | Tipe | Required | Indeks |
|---------|------|----------|--------|
| tenant_id | String | ✅ | Key |
| customerName | String | ✅ | - |
| items | String (JSON) | ✅ | - |
| totalPrice | Double | ✅ | - |
| status | String (Enum) | ❌ (default: 'pending') | Key |

**Enum untuk `status`**: `pending`, `preparing`, `ready_for_pickup`, `completed`, `cancelled`

---

## 🔐 Setup Authentication

### 1. Enable Email/Password Authentication

Di Appwrite Dashboard:
1. Masuk ke **Auth** → **Settings**
2. Enable **Email/Password** authentication
3. (Opsional) Enable **Email Verification** untuk keamanan

### 2. Buat User Test (Business Owner)

Via Appwrite Console:

1. Masuk ke **Auth** → **Users** → **Create User**
2. Isi:
   - **Email**: `owner@test.com`
   - **Password**: `password123` (minimal 8 karakter)
   - **Name**: `Test Owner`

3. Catat **User ID** yang dihasilkan

### 3. Buat Dokumen di Koleksi `users`

Setelah user dibuat di Auth, buat dokumen di koleksi `users`:

1. Masuk ke **Databases** → pilih database → koleksi **users**
2. **Create Document** dengan data:
   ```json
   {
     "user_id": "USER_ID_DARI_AUTH",
     "role": "owner_business",
     "username": "Test Owner",
     "tenant_id": null,
     "contract_end_date": null,
     "is_active": true
   }
   ```

### 4. Setup Permissions

Untuk koleksi `users`:
- **Read**: Users (untuk user yang login bisa baca profil sendiri)
- **Write**: None (hanya via Functions/Admin)

Untuk koleksi `tenants`, `products`, `categories`:
- **Read**: Any (untuk guest bisa melihat menu)
- **Write**: Document owner atau Admin

Untuk koleksi `orders`:
- **Read**: Document owner
- **Write**: Any (untuk guest bisa membuat pesanan)

---

## 🧪 Testing

### 1. Test Login

Setelah setup selesai:

1. Run aplikasi:
   ```bash
   flutter run
   ```

2. Login dengan kredensial:
   - **Email**: `owner@test.com`
   - **Password**: `password123`

3. Anda seharusnya diarahkan ke **Business Owner Dashboard**

### 2. Buat User Tenant (Opsional untuk Testing)

Untuk testing role `tenant`:

1. Buat user baru di Appwrite Auth:
   - **Email**: `tenant@test.com`
   - **Password**: `password123`

2. Buat dokumen di koleksi `users`:
   ```json
   {
     "user_id": "USER_ID_TENANT",
     "role": "tenant",
     "username": "Test Tenant",
     "tenant_id": "ID_TENANT_DARI_KOLEKSI_TENANTS",
     "contract_end_date": "2025-12-31T23:59:59.000Z",
     "is_active": true
   }
   ```

3. Login dengan `tenant@test.com` → Anda akan diarahkan ke **Tenant Dashboard**

---

## ✅ Checklist Sprint 1

- [x] Setup proyek Flutter dengan dependencies
- [x] Struktur folder arsitektur (features, core, shared)
- [x] Konfigurasi Appwrite client
- [x] Model dan provider untuk authentication
- [x] UI halaman Login
- [x] Integrasi Appwrite Authentication
- [x] Routing berdasarkan role (GoRouter)
- [x] Business Owner Dashboard (placeholder)
- [x] Tenant Dashboard (placeholder)

## 🚀 Next Steps (Sprint 2)

Sprint 2 akan fokus pada:
- Manajemen Tenant (CRUD)
- Manajemen User Tenant
- Manajemen Products untuk Tenant
- Appwrite Functions untuk `createTenant` dan `createTenantUser`

---

## ❓ Troubleshooting

### Error: "Invalid credentials"
- Pastikan email dan password benar
- Cek apakah user sudah dibuat di Appwrite Auth

### Error: "User profile not found"
- Pastikan sudah membuat dokumen di koleksi `users` dengan `user_id` yang sama dengan Auth User ID

### Error: "Collection not found"
- Pastikan Collection ID di `appwrite_config.dart` sesuai dengan ID di Appwrite

### Error: "Unauthorized"
- Periksa permissions di setiap koleksi
- Pastikan user memiliki akses read/write yang sesuai

---

## 📞 Bantuan

Jika ada pertanyaan atau masalah, silakan check:
1. Dokumentasi Appwrite: https://appwrite.io/docs
2. Flutter Appwrite SDK: https://pub.dev/packages/appwrite
3. File dokumentasi di folder `Iterasi/`
