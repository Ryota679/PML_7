# ⚠️ Manual User Creation Required - SDK Limitations

## 🔴 Important Notice

Karena **Appwrite SDK 13.x tidak mendukung Users API** di client-side, beberapa operasi harus dilakukan **manual** melalui Appwrite Console.

---

## 📋 Workflow Approve Registration (Manual Steps)

### **Step 1: Admin Approve Registration di App**

1. Login sebagai admin (`fuad@gmail.com`)
2. Tab "Registrasi" → Pending
3. Klik **"Approve"** pada registrasi
4. Masukkan **Temporary Password** (min 8 char)
5. Klik **"Setujui"**
6. ✅ Status berubah "approved"

**❗ IMPORTANT:** Password yang dimasukkan harus **disimpan** karena akan digunakan untuk create user manual!

---

### **Step 2: Create User di Appwrite Console (MANUAL)**

#### **A. Buka Appwrite Console:**
```
https://fra.cloud.appwrite.io
```

#### **B. Navigate ke Auth:**
```
Project: perojek-pml
→ Auth
→ Users
→ + Create User
```

#### **C. Fill User Form:**
```
Email:    [Email dari registration request]
Password: [Temporary password yang diset saat approve]
Name:     [Nama lengkap dari registration request]
```

#### **D. Save User ID:**
Setelah create, **copy User ID** (contoh: `691c3b7700180772f7d5`)

---

### **Step 3: Create Document di Collection users (MANUAL)**

#### **A. Navigate ke Database:**
```
Project: perojek-pml
→ Databases
→ kantin-db
→ users collection
→ + Create Document
```

#### **B. Fill Document Fields:**
```json
{
  "user_id": "691c3b7700180772f7d5",  // User ID dari Auth (Step 2D)
  "email": "test@business.com",        // Email user
  "full_name": "Test Business Owner",  // Nama lengkap
  "role": "owner_business",            // Role: owner_business
  "phone": "081234567890",             // Optional
  "is_active": true,
  "created_at": "2025-11-19T11:30:00.000Z"  // ISO 8601 format
}
```

#### **C. Save Document**
Klik **"Create"**

---

### **Step 4: Test Login**

1. Logout dari admin
2. Login dengan:
   - Email: [email yang didaftarkan]
   - Password: [temporary password]
3. ✅ Harus masuk ke Business Owner Dashboard

---

## 🎯 Fitur RUD Admin Dashboard

### **✅ Yang Bisa Dilakukan via App:**
- ✏️ **Edit User** - Update nama & telepon (database only)
- 🔍 **View Users** - List all business owners
- 📋 **Filter & Search** - (future)

### **❌ Yang Harus Manual:**
- 🔒 **Reset Password** - Harus di Appwrite Console > Auth > Users > Edit
- 🗑️ **Delete User** - Hapus dari database via app, then manual delete Auth
- ➕ **Create User** - Follow workflow di atas

---

## 📝 Manual Instructions for Each Operation

### **Reset Password (Manual):**

1. Buka: https://fra.cloud.appwrite.io
2. Auth → Users
3. Cari user by email
4. Klik **"Edit"**
5. Set new password
6. Save

**Note:** Admin Dashboard akan show dialog dengan instruksi ini saat klik "Reset Password"

---

### **Delete User (Semi-Manual):**

#### **Via App (Database Only):**
1. Admin Dashboard → Tab "Kelola Users"
2. Klik menu `⋮` → "Hapus"
3. Confirm
4. ✅ Document deleted from database

#### **Manual (Auth):**
1. Buka: https://fra.cloud.appwrite.io
2. Auth → Users
3. Find user by email/ID
4. Click `⋮` → "Delete"
5. Confirm

**⚠️ Warning:** User akan tetap bisa login jika tidak dihapus dari Auth!

---

## 🚀 Future Improvements (Production Ready)

### **Option 1: Appwrite Functions (Recommended)**

Create server-side functions untuk:
- ✅ Auto-create Auth user saat approve
- ✅ Auto-create database document
- ✅ Reset password via API
- ✅ Delete user completely (Auth + Database)

**Benefits:**
- ✅ Fully automated
- ✅ Secure (API key di server)
- ✅ Transaction-safe

**Implementation:**
```javascript
// Appwrite Function: approve-registration
import { Client, Users, Databases } from 'node-appwrite';

export default async ({ req, res }) => {
  const client = new Client()
    .setEndpoint(process.env.APPWRITE_ENDPOINT)
    .setProject(process.env.APPWRITE_PROJECT_ID)
    .setKey(process.env.APPWRITE_API_KEY);

  const users = new Users(client);
  const databases = new Databases(client);

  // Create user in Auth
  const user = await users.create(
    ID.unique(),
    req.body.email,
    req.body.password,
    req.body.fullName
  );

  // Create document in users collection
  await databases.createDocument(
    process.env.DATABASE_ID,
    'users',
    ID.unique(),
    {
      user_id: user.$id,
      email: req.body.email,
      full_name: req.body.fullName,
      role: 'owner_business',
      phone: req.body.phone,
      is_active: true,
    }
  );

  return res.json({ success: true, userId: user.$id });
};
```

---

### **Option 2: Backend API**

Create Node.js/Python backend:
- ✅ Store API key safely
- ✅ Handle user operations
- ✅ Call from Flutter app

---

### **Option 3: Upgrade SDK**

Upgrade ke Appwrite SDK yang support Users API:
- ⚠️ May require breaking changes
- ⚠️ Need to test compatibility

---

## 📊 Current Limitations Summary

| Operation | Status | Method |
|-----------|--------|---------|
| Approve Registration | ✅ Semi-Auto | App + Manual create user |
| View Users | ✅ Auto | App |
| Edit User (name/phone) | ✅ Auto | App (database only) |
| Reset Password | ❌ Manual | Appwrite Console |
| Delete User | ⚠️ Semi-Manual | App (DB) + Console (Auth) |
| Create User | ❌ Manual | Follow workflow above |

---

## ✅ Testing Checklist

- [ ] Admin approve registration with temp password
- [ ] Copy temp password & user data
- [ ] Create user in Appwrite Console > Auth
- [ ] Copy user ID from Auth
- [ ] Create document in users collection
- [ ] Test login with created user
- [ ] Verify redirect to Business Owner Dashboard
- [ ] Test edit user info from Admin Dashboard
- [ ] Test delete user (database deletion)
- [ ] Manually delete user from Auth

---

## 🐛 Troubleshooting

### **Error: "User not found"**
**Cause:** User ID di database tidak match dengan Auth  
**Solution:** 
1. Check user_id di collection users
2. Verify user exists di Auth dengan User ID yang sama
3. Pastikan tidak ada typo

### **Error: "Invalid credentials"**
**Cause:** Password salah atau user tidak ada di Auth  
**Solution:**
1. Verify user ada di Appwrite Console > Auth > Users
2. Reset password di Console
3. Test login dengan password baru

### **User can login but no dashboard access**
**Cause:** Document tidak ada di collection users  
**Solution:**
1. Check collection users untuk user_id tersebut
2. Create document jika belum ada
3. Verify role = "owner_business"

---

## 📞 Need Help?

Jika mengalami kesulitan:
1. Check logs di browser console
2. Check Appwrite Console logs
3. Verify all manual steps completed
4. Review this documentation

---

**Created:** 2025-11-19  
**Last Updated:** 2025-11-19  
**Version:** 1.0  
**Status:** MVP - Manual Steps Required
