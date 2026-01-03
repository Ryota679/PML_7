### 5. Entity Relationship Diagram (ERD.md)
*(Peran di `users` diperbarui)*

```markdown:Entity Relationship Diagram:erd.md
erDiagram
    appwrite_auth {
        UUID $id PK "Primary Key (Internal Appwrite User ID)"
        String email "Unique"
        String password_hash
        String name
        STRING status "Verified/Unverified"
    }

    users {
        UUID $id PK "Primary Key (Detail Profil)"
        UUID user_id FK "Foreign Key ke appwrite_auth.$id"
        ENUM role "owner_business, tenant, guest"
        UUID tenant_id FK "Relasi ke tenants.$id (Hanya untuk peran Tenant)"
        String username
        DateTime contract_end_date "Durasi Kontrak Tenant"
    }

    tenants {
        UUID $id PK "Primary Key"
        UUID owner_user_id FK "Foreign Key ke users.$id (Peran owner_business)"
        String name
        String type "Jenis Tenant"
        String description
        ENUM status "active, inactive"
    }

    products {
        UUID $id PK "Primary Key"
        UUID tenant_id FK "Foreign Key ke tenants.$id"
        UUID category_id FK "Foreign Key ke categories.$id"
        String name
        DECIMAL price
        BOOLEAN is_available
    }

    categories {
        UUID $id PK "Primary Key"
        UUID tenant_id FK "Foreign Key ke tenants.$id"
        String name "Unique per tenant"
    }

    orders {
        UUID $id PK "Primary Key"
        UUID tenant_id FK "Foreign Key ke tenants.$id"
        DECIMAL total_amount
        ENUM status "pending, preparing, etc."
    }

    appwrite_auth ||--|{ users : "is_represented_by"
    users ||--o{ tenants : "owns (sebagai owner_business)"
    tenants ||--o{ products : "sells"
    tenants ||--o{ orders : "receives"
    categories ||--o{ products : "categorizes"
```eof

### 6. Dokumentasi Isian Database (data_collections.md)
*(Peran `role` di `users` dan deskripsi relasi diperbarui)*

```markdown:Spesifikasi Koleksi Data:data_collections.md
# 🗃️ Spesifikasi Koleksi Data (Appwrite Database)

Dokumen ini menjelaskan struktur data, atribut, strategi pengindeksan, dan **Nilai Default** yang direkomendasikan untuk koleksi utama aplikasi **Tenant QR-Order**.

**Catatan Khusus:**
1.  **Indeks Kunci (Key/Unique)** ditambahkan pada semua kolom relasi dan kolom filter untuk optimasi kecepatan kueri.
2.  Tipe data kompleks (seperti daftar item pesanan) disimpan sebagai **String** dan diolah sebagai JSON di sisi aplikasi.

---

## 1. Koleksi `users` (Detail Profil Pengguna)

Koleksi ini menyimpan detail profil dan relasi peran (`owner_business`, `tenant`, atau `guest`) ke data bisnis.

| Kolom | Tipe Data | Relasi / Indeks | Nilai Default | Deskripsi |
| :--- | :--- | :--- | :--- | :--- |
| **`$id`** | String (UUID) | - | N/A (Otomatis) | ID Dokumen Appwrite. |
| **`user_id`** | String (UUID) | **Index: Unique (Wajib)** | None (Wajib Diisi) | ID pengguna dari Appwrite Auth (kunci utama relasi). |
| **`role`** | String (Enum) | **Index: Key** | None (Wajib Diisi) | Peran: `owner_business`, `tenant`, atau `guest`. |
| **`username`** | String | - | None (Wajib Diisi) | Nama yang ditampilkan di dashboard. |
| **`tenant_id`** | String (UUID) | **Index: Key** | NULL | ID Tenant yang dikelola (wajib jika `role='tenant'`). |
| **`contract_end_date`** | DateTime | **Index: Key** | NULL | Tanggal berakhirnya kontrak sewa (hanya untuk `role='tenant'`). |
| **`is_active`** | Boolean | - | `true` | Status keaktifan akun user. |
| **`$createdAt`** | DateTime | - | N/A (Otomatis) | Waktu pembuatan dokumen. |
| **`$updatedAt`** | DateTime | - | N/A (Otomatis) | Waktu pembaruan terakhir dokumen. |

---

## 2. Koleksi `tenants` (Profil Penyewa/Warung)

Koleksi ini menyimpan data setiap warung atau penyewa yang dikelola oleh Business Owner.

| Kolom | Tipe Data | Relasi / Indeks | Nilai Default | Deskripsi |
| :--- | :--- | :--- | :--- | :--- |
| **`$id`** | String (UUID) | - | N/A (Otomatis) | ID Dokumen Appwrite. |
| **`owner_user_id`** | String (UUID) | **Index: Key (Wajib)** | None (Wajib Diisi) | ID Business Owner (kunci relasi, dari user dengan `role='owner_business'`). |
| **`name`** | String | - | None (Wajib Diisi) | Nama Tenant. |
| **`type`** | String | - | None (Wajib Diisi) | Jenis Tenant (e.g., Makanan Berat, Minuman Dingin). |
| **`description`** | String | - | None (Wajib Diisi) | Deskripsi singkat. |
| **`logoUrl`** | String | - | NULL | URL Logo Tenant (opsional). |
| **`status`** | String (Enum) | - | `'active'` | Status operasional tenant. |
| **`qrCodeUrl`** | String | - | NULL | URL QR Code (dibuat otomatis). |
| **`$createdAt`** | DateTime | - | N/A (Otomatis) | Waktu pembuatan dokumen. |
| **`$updatedAt`** | DateTime | - | N/A (Otomatis) | Waktu pembaruan terakhir dokumen. |

---

## 3. Koleksi `products` (Item Menu)

Koleksi ini menyimpan daftar menu yang ditawarkan oleh setiap tenant.

| Kolom | Tipe Data | Relasi / Indeks | Nilai Default | Deskripsi |
| :--- | :--- | :--- | :--- | :--- |
| **`$id`** | String (UUID) | - | N/A (Otomatis) | ID Dokumen Appwrite. |
| **`tenant_id`** | String (UUID) | **Index: Key (Wajib)** | None (Wajib Diisi) | ID Tenant pemilik produk. |
| **`category_id`** | String (UUID) | **Index: Key** | None (Wajib Diisi) | ID Kategori produk. |
| **`name`** | String | - | None (Wajib Diisi) | Nama menu. |
| **`price`** | Double | - | None (Wajib Diisi) | Harga produk. |
| **`image_url`** | String | - | NULL | URL gambar produk (opsional). |
| **`is_available`** | Boolean | **Index: Key** | `true` | Status ketersediaan (untuk filter pelanggan). |
| **`description`** | String | - | NULL | Deskripsi produk (opsional). |
| **`$createdAt`** | DateTime | - | N/A (Otomatis) | Waktu pembuatan dokumen. |
| **`$updatedAt`** | DateTime | - | N/A (Otomatis) | Waktu pembaruan terakhir dokumen. |

---

## 4. Koleksi `categories` (Kategori Menu)

Koleksi ini menyimpan kategori untuk mengelompokkan produk (e.g., Makanan, Minuman, Snack).

| Kolom | Tipe Data | Relasi / Indeks | Nilai Default | Deskripsi |
| :--- | :--- | :--- | :--- | :--- |
| **`$id`** | String (UUID) | - | N/A (Otomatis) | ID Dokumen Appwrite. |
| **`tenant_id`** | String (UUID) | **Index: Key (Wajib)** | None (Wajib Diisi) | ID Tenant pemilik kategori (kunci relasi). |
| **`name`** | String | - | None (Wajib Diisi) | Nama Kategori. |
| **`$createdAt`** | DateTime | - | N/A (Otomatis) | Waktu pembuatan dokumen. |
| **`$updatedAt`** | DateTime | - | N/A (Otomatis) | Waktu pembaruan terakhir dokumen. |

---

## 5. Koleksi `orders` (Transaksi Pesanan)

Koleksi ini menyimpan detail setiap transaksi dan status pesanan.

| Kolom | Tipe Data | Relasi / Indeks | Nilai Default | Deskripsi |
| :--- | :--- | :--- | :--- | :--- |
| **`$id`** | String (UUID) | - | N/A (Otomatis) | ID Dokumen Appwrite. |
| **`tenant_id`** | String (UUID) | **Index: Key (Wajib)** | None (Wajib Diisi) | ID Tenant yang menerima pesanan (kunci relasi). |
| **`customerName`** | String | - | None (Wajib Diisi) | Nama pelanggan saat checkout (jika anonim). |
| **`items`** | **String** | - | None (Wajib Diisi) | Daftar item pesanan (Disimpan sebagai objek JSON yang diserialisasi menjadi String). |
| **`totalPrice`** | Double | - | None (Wajib Diisi) | Total biaya pesanan. |
| **`status`** | String (Enum) | **Index: Key** | `'pending'` | Status pesanan awal adalah `pending`. |
| **`$createdAt`** | DateTime | **Index: Key** | N/A (Otomatis) | Waktu pesanan dibuat. |
| **`$updatedAt`** | DateTime | - | N/A (Otomatis) | Waktu pembaruan terakhir dokumen. |
```eof