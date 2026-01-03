# Create Tenant User Function

Appwrite Function untuk membuat user tenant yang otomatis masuk ke **Appwrite Auth** dan **collection users**.

## 🎯 Fungsi

Function ini mengatasi masalah dimana tenant user hanya dibuat di collection `users` tapi tidak di Auth, sehingga tidak bisa login.

Saat dipanggil, function akan:
1. ✅ Membuat user di **Appwrite Auth** dengan credentials yang diberikan
2. ✅ Menambahkan label `tenant` ke user
3. ✅ Membuat document di **collection users** dengan role `tenant`
4. ✅ Rollback otomatis jika ada error

## 📥 Input (Request Body)

```json
{
  "email": "tenant@example.com",
  "password": "password123",
  "fullName": "Nama Tenant",
  "username": "tenant_username",
  "tenantId": "692688d4cf0e90d8...",
  "contractEndDate": "2025-12-31T23:59:59.000Z",
  "phone": "081234567890"
}
```

### Required Fields
- `email` - Email tenant user
- `password` - Password (minimal 8 karakter)
- `fullName` - Nama lengkap
- `username` - Username
- `tenantId` - ID tenant yang akan di-assign

### Optional Fields
- `contractEndDate` - Tanggal akhir kontrak (default: 30 hari dari sekarang)
- `phone` - Nomor telepon

## 📤 Output

### Success Response
```json
{
  "success": true,
  "message": "Tenant user created successfully",
  "data": {
    "userId": "user_id_generated",
    "email": "tenant@example.com",
    "fullName": "Nama Tenant",
    "username": "tenant_username",
    "role": "tenant",
    "tenantId": "692688d4cf0e90d8..."
  }
}
```

### Error Response
```json
{
  "success": false,
  "error": "Error message",
  "code": "ERROR_CODE"
}
```

## ⚙️ Environment Variables

Di Appwrite Console > Functions > Create Tenant User > Settings > Variables:

```
DATABASE_ID=kantin-db
USERS_COLLECTION_ID=users
```

> **Note**: `APPWRITE_FUNCTION_API_KEY` harus memiliki scope `users.write`

## 🚀 Deployment

Dari root project:

```bash
# Deploy all functions
appwrite deploy function

# Atau deploy function tertentu
appwrite deploy function --functionId createTenantUser
```

## 🧪 Testing

### Via Appwrite Console

1. Buka: Appwrite Console > Functions > Create Tenant User
2. Klik **Execute**
3. Paste JSON body (lihat contoh di atas)
4. Klik **Execute**
5. Verifikasi:
   - User ada di **Auth > Users** dengan email yang benar
   - Document ada di **Database > users** dengan role `tenant`

### Via Flutter App

Function ini akan dipanggil otomatis dari Flutter app saat Business Owner membuat tenant user baru.

## ⚠️ Rollback

Jika pembuatan document di database gagal, function akan otomatis menghapus user yang sudah dibuat di Auth untuk menjaga konsistensi data.

## 📋 Checklist Deployment

- [ ] Function di-deploy ke Appwrite
- [ ] Environment variables sudah di-set
- [ ] API key memiliki scope `users.write`
- [ ] Test via Console berhasil
- [ ] User muncul di Auth
- [ ] Document muncul di database
- [ ] User bisa login dengan credentials yang dibuat
