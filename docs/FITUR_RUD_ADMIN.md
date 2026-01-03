# ✅ Fitur RUD (Read, Update, Delete) - Admin Dashboard

## 📋 Overview

Admin sekarang bisa mengelola **Business Owners** yang sudah terdaftar melalui tab **"Kelola Users"** di Admin Dashboard.

---

## 🎯 Fitur yang Tersedia

### **1. Read (Lihat Daftar Users)**
- Melihat semua Business Owner yang sudah approved
- Informasi yang ditampilkan:
  - ✅ Nama Lengkap
  - ✅ Email
  - ✅ Nomor Telepon (jika ada)
  - ✅ Role
  - ✅ Tanggal Terdaftar

### **2. Update (Edit User)**
- Edit nama lengkap
- Edit nomor telepon
- Auto-refresh list setelah update

### **3. Reset Password**
- Admin bisa set password baru untuk user
- Password baru ditampilkan di SnackBar (harus disimpan!)
- Gunakan ini jika user lupa password

### **4. Delete (Hapus User)**
- Hapus user dari Appwrite Auth
- Hapus document dari collection `users`
- Konfirmasi sebelum delete (permanent!)

---

## 🗂️ Struktur File Baru

### **Repository:**
```
lib/features/admin/data/user_management_repository.dart
```
**Methods:**
- `getAllBusinessOwners()` - Get list business owners
- `getUserById()` - Get single user
- `updateUser()` - Update user info
- `deleteUser()` - Delete user (hard delete)
- `resetUserPassword()` - Reset password
- `toggleUserStatus()` - Enable/disable account (future)

### **Provider:**
```
lib/features/admin/providers/user_management_provider.dart
```
**State Management untuk User Management**

### **UI Update:**
```
lib/features/admin/presentation/admin_dashboard.dart
```
**Fitur Baru:**
- Tab "Kelola Users"
- User list dengan PopupMenu
- Edit dialog
- Reset password dialog
- Delete confirmation

---

## 🎨 UI/UX

### **Main Tabs:**
```
┌─────────────────────────────────────────┐
│  [ Registrasi ]  [ Kelola Users ]       │
└─────────────────────────────────────────┘
```

### **User Card:**
```
┌─────────────────────────────────────────┐
│  [A]  Andi Pratama          [⋮ Menu]    │
│       andi@business.com                 │
│                                         │
│  📞 081234567890                        │
│  👤 Role: owner_business                │
│  📅 Terdaftar: 19/11/2025 10:30        │
└─────────────────────────────────────────┘
```

### **PopupMenu Options:**
```
┌──────────────────┐
│ ✏️  Edit          │
│ 🔒 Reset Password │
│ 🗑️  Hapus         │
└──────────────────┘
```

---

## 🧪 Cara Test

### **Step 1: Approve Registration**
1. Login sebagai admin (`fuad@gmail.com`)
2. Tab "Registrasi" → Approve test user
3. Set temporary password (min 8 karakter)

### **Step 2: View Users**
1. Klik tab **"Kelola Users"**
2. List business owners yang sudah approved akan muncul

### **Step 3: Edit User**
1. Klik menu `⋮` di user card
2. Pilih **"Edit"**
3. Update nama/telepon
4. Klik **"Simpan"**
5. ✅ User updated!

### **Step 4: Reset Password**
1. Klik menu `⋮` di user card
2. Pilih **"Reset Password"**
3. Input password baru (min 8 karakter)
4. Klik **"Reset"**
5. **PENTING:** Copy password dari SnackBar (ditampilkan 10 detik)
6. Berikan password baru ke Business Owner

### **Step 5: Delete User**
1. Klik menu `⋮` di user card
2. Pilih **"Hapus"**
3. Confirm di dialog
4. ✅ User deleted (permanent!)

---

## ⚠️ Important Notes

### **Reset Password:**
- Password baru ditampilkan di SnackBar selama **10 detik**
- **WAJIB dicatat** karena tidak bisa dilihat lagi
- Berikan password ke Business Owner via email/WA

### **Delete User:**
- **PERMANENT ACTION!**
- Akan menghapus:
  - User dari Appwrite Authentication
  - Document dari collection `users`
- **TIDAK BISA dibatalkan**
- Pastikan konfirmasi dulu sebelum delete

### **API Key Required:**
- Fitur ini menggunakan **Users API** dari Appwrite
- Memerlukan **API Key** dengan scope `users.write`
- API Key sudah diset di: `lib/core/config/appwrite_config.dart`

---

## 🔐 Security Considerations

### **Current Implementation (MVP):**
- ✅ API Key hardcoded di config (for development)
- ✅ Admin only access (role check)
- ✅ Confirmation dialogs untuk destructive actions

### **Production Recommendations:**
1. **Appwrite Functions**
   - Move user management logic ke server-side
   - API Key tidak ter-expose di client
   
2. **Backend API**
   - Create Node.js/Python backend
   - Store API Key di environment variables
   
3. **Audit Log**
   - Log semua admin actions (who, what, when)
   - Track user changes
   
4. **Soft Delete**
   - Instead of hard delete, mark as "deleted"
   - Keep data for audit purposes

---

## 🚀 Future Enhancements

### **Planned Features:**
- [ ] **Search & Filter** - Cari user by name/email
- [ ] **Bulk Actions** - Delete/reset multiple users
- [ ] **User Details Page** - Detailed view dengan activity history
- [ ] **Suspend Account** - Temporary disable tanpa delete
- [ ] **Change Role** - Promote/demote users
- [ ] **Export Data** - Export user list ke CSV/Excel
- [ ] **Email Notification** - Auto-send email setelah password reset

---

## 📊 Data Flow

### **Read Users:**
```
Admin Dashboard
    ↓
userManagementProvider.loadBusinessOwners()
    ↓
UserManagementRepository.getAllBusinessOwners()
    ↓
Query collection 'users' where role = 'owner_business'
    ↓
Return List<UserModel>
```

### **Update User:**
```
Admin clicks Edit
    ↓
_showEditUserDialog() - Input new data
    ↓
userManagementProvider.updateUser()
    ↓
UserManagementRepository.updateUser()
    ↓
Update document in 'users' collection
    ↓
Reload users list
```

### **Delete User:**
```
Admin clicks Delete
    ↓
Confirmation Dialog
    ↓
userManagementProvider.deleteUser()
    ↓
UserManagementRepository.deleteUser()
    ├─ Delete from Appwrite Auth (Users API)
    └─ Delete document from 'users' collection
    ↓
Reload users list
```

---

## 🐛 Troubleshooting

### **Error: "Invalid API Key"**
**Cause:** API Key tidak valid atau expired  
**Solution:** 
1. Check `lib/core/config/appwrite_config.dart`
2. Verify API Key di Appwrite Console
3. Re-create API key dengan scope `users.write`

### **Error: "User not found"**
**Cause:** Document ID atau User ID tidak match  
**Solution:**
1. Refresh halaman
2. Check data di Appwrite Console
3. Verify user_id di collection `users`

### **Error: "Unauthorized"**
**Cause:** API Key tidak punya permission  
**Solution:**
1. Delete API key di Appwrite Console
2. Create new API key
3. **Centang scope:** `users.read` & `users.write`

---

## 📚 Code Examples

### **Load Users:**
```dart
// In widget initState
ref.read(userManagementProvider.notifier).loadBusinessOwners();
```

### **Watch Users State:**
```dart
final userManagementState = ref.watch(userManagementProvider);

if (userManagementState.isLoading) {
  return LoadingWidget();
}

if (userManagementState.users.isNotEmpty) {
  return UsersList(userManagementState.users);
}
```

### **Delete User:**
```dart
final success = await ref
    .read(userManagementProvider.notifier)
    .deleteUser(
      authUserId: user.userId,
      documentId: user.id!,
    );
```

---

## ✅ Testing Checklist

- [ ] API Key sudah diset
- [ ] Login sebagai admin
- [ ] Tab "Kelola Users" terlihat
- [ ] List users muncul (setelah ada approved registration)
- [ ] Edit user berhasil
- [ ] Reset password berhasil & ditampilkan
- [ ] Delete user berhasil dengan confirmation
- [ ] Refresh (pull down) works
- [ ] Empty state muncul jika belum ada user

---

**Created:** 2025-11-19  
**Last Updated:** 2025-11-19  
**Version:** 1.0
