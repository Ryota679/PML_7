# Single Device Login - Security Feature

## Overview

Fitur **Single Device Login** memastikan bahwa satu akun hanya dapat aktif di satu device pada satu waktu. Ketika user login di device baru, session di device lama akan otomatis dilogout oleh Appwrite, dan user di kedua device akan menerima notifikasi yang jelas.

## Key Features

### 1. **Automatic Session Management**
- Maximum 1 active session per user
- Session lama otomatis expired saat login baru dibuat
- Berlaku untuk **semua authentication method** (Email/Password, Google OAuth)

### 2. **Dual Notification System**

#### Device Baru - Confirmation Dialog
User yang baru login akan melihat dialog informatif:
- Platform device sebelumnya (Web/Android/iOS)
- Timestamp login terakhir
- Konfirmasi bahwa hanya 1 device bisa aktif

#### Device Lama - Security Alert
User di device lama yang di-logout otomatis akan melihat:
- Alert bahwa session telah berakhir
- Info device baru yang login
- Warning untuk ganti password jika suspicious
- Single button untuk redirect ke login

### 3. **Session Monitoring**
- Background check setiap 30 detik untuk detect session mismatch
- Auto-trigger security alert saat session tidak valid
- Graceful handling untuk 401/403 errors

## User Experience Flow

### Scenario: User Login di Device Baru

**Step 1: User A login di Web**
```
✅ Session created: session_123
✅ Database updated: lastSessionId = session_123
```

**Step 2: User A login di Android**
```
🔄 Creating new session...
⚠️ Appwrite detects existing session
🗑️ Session session_123 EXPIRED (automatic)
✅ New session created: session_456
✅ Database updated: lastSessionId = session_456

📱 Android shows: "Login dari Device Baru"
   "Sesi sebelumnya di Web telah dilogout"
```

**Step 3: User returns to Web**
```
💻 User tries to access menu OR 30 seconds pass
❌ API request fails (401 Unauthorized)
🚨 Web shows: "Sesi Anda Telah Berakhir"
   "Akun login dari: Android (Baru saja)"
   [ Mengerti ] → Redirect to login
```

## Technical Implementation

### Appwrite Configuration

**Required Setup:**
1. Login to Appwrite Console
2. Navigate to **Settings > Auth**
3. Set **Maximum Sessions = 1**
4. Save configuration

This enforces single session limit at the server level.

### Database Schema

**New Fields in `users` Collection:**

| Field | Type | Description |
|-------|------|-------------|
| `last_session_id` | String | ID dari session terakhir |
| `last_login_at` | DateTime | Timestamp login terakhir |
| `last_login_device` | String | Platform: "web", "android", "ios" |
| `last_login_device_info` | String | Detail device (optional) |

### Code Components

**New Files:**
- `lib/shared/widgets/device_switch_dialog.dart` - New device notification
- `lib/shared/widgets/session_expired_dialog.dart` - Old device alert
- `lib/core/services/session_monitor_service.dart` - Background validator
- `lib/core/utils/device_info_helper.dart` - Platform detection

**Modified Files:**
- `lib/shared/models/user_model.dart` - Add session tracking fields
- `lib/features/auth/data/auth_repository.dart` - Session update method
- `lib/features/auth/providers/auth_provider.dart` - Device switch logic
- `lib/features/auth/presentation/login_page.dart` - Show dialog post-login
- `lib/core/router/app_router.dart` - Session validation guard

## Security Considerations

### 1. **Unauthorized Access Detection**
- Jika ada login dari device tidak dikenal → user lama dapat alert
- Warning message menyarankan ganti password
- Clear information untuk non-technical users

### 2. **Privacy-Friendly**
- Tidak menyimpan device fingerprint/unique ID
- Hanya track platform type (web/android/ios)
- Optional device info (browser name, OS version)

### 3. **Graceful Degradation**
- Session monitor handle network errors
- Fallback to login page jika session check fails
- No data loss risk

## Testing Requirements

### Manual Testing Checklist

**✅ Normal Login (Same Device)**
- Login → Logout → Login again
- Should NOT show device switch dialog

**✅ Device Switch (New Device)**
- Login di Web → Login di Android
- Android should show "Login dari Device Baru"
- Dialog shows previous device info

**✅ Device Switch (Old Device)**
- Login di Web → Keep open
- Login di Android
- Return to Web → Try action or wait 30s
- Web should show "Sesi Anda Telah Berakhir"
- Single button "Mengerti" redirects to login

**✅ All Authentication Methods**
- Test with Email/Password login
- Test with Google OAuth login
- Both should behave identically

**✅ All User Roles**
- Business Owner
- Tenant Owner
- Tenant Staff
- Guest (should not be affected)

**✅ Cross-Platform**
- Web ↔ Android
- Web ↔ iOS (if available)
- Android ↔ iOS

## Troubleshooting

### Issue: Dialog tidak muncul di device lama

**Possible Causes:**
1. Session monitor tidak berjalan
2. Background check interval terlalu lama
3. Network error mencegah API call

**Solution:**
- Check console logs untuk session monitor
- Verify background service started after login
- Try manual action (click menu) untuk trigger check

### Issue: User bisa login di multiple devices

**Possible Causes:**
1. Appwrite session limit tidak di-set
2. Session limit configuration tidak tersave

**Solution:**
- Verify Appwrite Console: Settings > Auth > Maximum Sessions = 1
- Check Appwrite version compatibility
- Review server logs

### Issue: Dialog muncul setiap kali login di device yang sama

**Possible Causes:**
1. Device detection tidak konsisten
2. Session tracking tidak update dengan benar

**Solution:**
- Check `DeviceInfoHelper.getPlatform()` output
- Verify database update untuk `last_session_id`
- Review login flow logs

## Rollback Plan

Jika terjadi critical issue:

1. **Disable Appwrite Session Limit**
   - Login to Appwrite Console
   - Set Maximum Sessions = unlimited
   - Users can login to multiple devices

2. **Disable Notifications**
   - Comment out dialog display logic
   - Keep session tracking for logging

3. **Remove Session Monitor**
   - Stop background service
   - Fallback to manual session check

**Note:** Tracking fields tetap aman di database, no data loss risk.

## Future Enhancements

### Potential Features:
- **Session Management Page**: User dapat melihat semua active sessions
- **Trusted Devices**: Option untuk whitelist specific devices
- **Push Notifications**: Real-time notification saat ada login baru
- **Login History**: Log semua login attempts dengan timestamp & location
- **2FA Integration**: Extra security layer untuk sensitive actions

## References

- **Implementation Plan**: `brain/implementation_plan.md`
- **Task Checklist**: `brain/task.md`
- **Appwrite Sessions Docs**: https://appwrite.io/docs/products/auth/sessions
- **Google OAuth Guide**: `docs/GOOGLE_OAUTH_COMPLETE_GUIDE.md`
