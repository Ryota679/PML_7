# Appwrite Administration Scripts

Scripts untuk administrasi dan maintenance database Appwrite.

## ⚠️ KEAMANAN

**PENTING:** File-file berikut berisi API key dan TIDAK BOLEH di-commit ke Git:
- `.env` - File konfigurasi dengan API key
- `*_with_keys.js` - Script dengan hardcoded keys
- `node_modules/` - Dependencies

Semua file di atas sudah ada di `.gitignore`.

## 🚀 Setup

### 1. Install Dependencies

```bash
cd scripts
npm install
```

### 2. Konfigurasi API Key

```bash
# Copy template .env
cp .env.example .env

# Edit .env dan tambahkan API key Anda
notepad .env
```

### 3. Dapatkan API Key dari Appwrite Console

1. Buka [Appwrite Console](https://cloud.appwrite.io/console)
2. Pilih project **perojek-pml**
3. Masuk ke **Settings → API Keys**
4. Klik **Create API Key**
5. Berikan nama: `Scripts Admin Key`
6. Pilih scopes:
   - ✅ `databases.read`
   - ✅ `databases.write`
   - ✅ `storage.read`
   - ✅ `storage.write`
7. Copy API key yang dihasilkan
8. Paste ke file `.env`:
   ```
   APPWRITE_API_KEY=standard_xxxxxxxxxxxxx
   ```

## 📜 Available Scripts

### Clear Product Permissions

Menghapus semua document-level permissions dari products collection:

```bash
npm run clear-products
```

Atau:

```bash
node clear_product_permissions_secure.js
```

### Clear Storage Permissions

Menghapus semua file-level permissions dari storage bucket:

```bash
npm run clear-storage
```

### Fix Product Permissions

Update permissions untuk semua products:

```bash
npm run fix-permissions
```

## 🔒 Best Practices

1. **Jangan commit API key** - Selalu gunakan `.env` file
2. **Rotate API keys** - Ganti API key secara berkala
3. **Minimal permissions** - Berikan hanya scope yang diperlukan
4. **Review sebelum run** - Periksa script sebelum menjalankan di production

## 🐛 Troubleshooting

### Error: API key not found

```
❌ ERROR: API key not found!
```

**Solusi:**
1. Pastikan file `.env` sudah dibuat
2. Pastikan `APPWRITE_API_KEY` sudah diisi
3. Pastikan tidak ada spasi di sekitar `=`

### Error: Invalid API key

```
❌ Invalid API key
```

**Solusi:**
1. Periksa API key di Appwrite Console
2. Pastikan API key masih aktif (tidak expired/revoked)
3. Generate API key baru jika perlu

### Error: Permission denied

```
❌ Permission denied
```

**Solusi:**
1. Periksa scopes API key di Appwrite Console
2. Pastikan sudah include: `databases.read`, `databases.write`
3. Generate API key baru dengan scope yang benar

## 📝 Notes

- Script ini menggunakan `node-appwrite` SDK
- Semua script dibuat untuk server-side execution (Node.js)
- Jangan gunakan API key client-side (Flutter app)
- API key server hanya untuk scripts dan Appwrite Functions
