# Session Cache Issue - Solution Guide

## 🎯 Problem Summary

**Appwrite Session Limit = WORKING ✅**
- Appwrite successfully deletes old sessions when user logs in from new device
- Screenshot shows: "No sessions available" = Correct!

**Flutter App State = CACHED ❌**
- Web app still shows logged in UI (using old local state)
- Only gets 401 error when trying API calls (logout, etc)
- This is the "cache" problem

---

## 📊 What's Happening

```
Timeline:
1. User login di Android → Appwrite create session for Android
2. Appwrite delete session Web (session limit = 1) ✅
3. Web app masih pakai state lokal yang cached ❌
   - isAuthenticated masih TRUE (wrong!)
   - user data masih ada (wrong!)
4. User coba action di Web
   - API call → 401 Unauthorized ✅
   - App belum handle error ini → masih tampil UI ❌
```

---

## ✅ Solution Implemented

### 1. API Error Interceptor (NEW)

**File:** `lib/core/services/api_error_interceptor.dart`

**Purpose:**
- Detect all 401/403 errors from Appwrite
- Automatically trigger logout when session expired
- Clear local state when session invalid

### 2. Auth Provider Update

**File:** `lib/features/auth/providers/auth_provider.dart`

**Changes:**
- Registered session expired callback
- Added `_forceLogoutLocal()` method
- Auto-clear state when session expired detected

---

## 🧪 How to Test

### Test Scenario:

1. **Logout semua device dulu** (clear all sessions)

2. **Login di Android** dengan akun `topik@gmail.com`
   - Check console logs
   - Should see session tracking

3. **Di Web (masih login state lama):**
   - **Try ANY action** (navigate menu, click button, etc)
   - **Expected Result:**
     - API call fails with 401
     - Interceptor detects error
     - Auto-logout (clear state)
     - Redirect to login page

4. **Check Debug Logs:**
   ```
   🚨 [API INTERCEPTOR] Session expired error detected!
   🚨 [AUTH] Session expired callback triggered!
   🔒 [AUTH] Force logout (local)
   ✅ [AUTH] Local state cleared
   ```

---

## 🔧 Troubleshooting

### Issue: Web still shows UI after Android login

**Diagnosis:**
- State is cached locally
- Need to trigger ANY API call to get 401 error

**Solutions:**
1. **Refresh page** (F5) - will check session on load
2. **Click any menu/action** - will trigger API call → 401 → auto-logout
3. **Wait for periodic check** (if implemented)

### Issue: No auto-logout happens

**Check:**
1. Debug logs - is error interceptor triggered?
2. Is callback registered? Look for:
   ```
   🔒 [API INTERCEPTOR] Session expired callback registered
   ```
3. Are API calls wrapped with error handling?

---

## 📝 Next Enhancement (Optional)

### Option A: Periodic Session Check

Add background service to check session every 30 seconds:

```dart
// Check session validity periodically
Timer.periodic(Duration(seconds: 30), (_) {
  authRepository.getCurrentSession().catchError((e) {
    if (isSessionExpiredError(e)) {
      forceLogout();
    }
  });
});
```

### Option B: WebSocket for Real-time Logout

Use Appwrite Realtime to listen for session deletion:

```dart
// Subscribe to auth events
client.subscribe(['account'], (response) {
  if (response.events.contains('users.*.sessions.*.delete')) {
    forceLogout();
  }
});
```

### Option C: Router Guard (Recommended)

**File:** `lib/core/router/app_router.dart`

Add global error handler in router:

```dart
redirect: (context, state) async {
  try {
    final session = await getCurrentSession();
    if (session == null && state.location != '/login') {
      return '/login';
    }
  } catch (e) {
    if (isSessionExpiredError(e)) {
      return '/login';
    }
  }
  return null; // No redirect
}
```

---

## 🎯 Summary

**Current Status:**

| Feature | Status | Notes |
|---------|--------|-------|
| Appwrite session limit | ✅ Working | Sessions correctly deleted |
| Session tracking | ✅ Working | Device info saved |
| Auto-logout old device | ⚠️ Reactive | Happens on first API call |
| Error interceptor | ✅ Implemented | Catch 401 and auto-logout |
| Global router guard | ⏳ Optional | Can add for better UX |

**How It Works Now:**

1. Login di device baru → Old session deleted by Appwrite ✅
2. Old device UI still shows (cached state) ⏳
3. User tries ANY action → API call fails → 401 error ✅
4. Interceptor catches → Auto-logout → Clear state ✅
5. User sees login page ✅

**Is This Good Enough?**

**YES** for most use cases! The protection is there:
- User CANNOT perform any actions (all API calls fail)
- First action triggers auto-logout
- Security goal achieved ✅

**Want Better UX?**
- Add periodic check (Option A)
- Add router guard (Option C)
- Add WebSocket listener (Option B)

---

## 📊 Testing Checklist

- [ ] Test 1: Login Android → Check Appwrite sessions = 1
- [ ] Test 2: Web tries action → Gets 401 → Auto-logout
- [ ] Test 3: Refresh web → Auto-redirect to login
- [ ] Test 4: Multiple role testing (BO, Tenant, Staff)
- [ ] Test 5: Google OAuth flow

**Debug Logs to Check:**
```
✅ [DATABASE] Session tracking updated successfully
🔄 [DEVICE SWITCH] Device change detected!
🚨 [API INTERCEPTOR] Session expired error detected!
🚨 [AUTH] Session expired callback triggered!
✅ [AUTH] Local state cleared
```

---

## ❓ FAQ

**Q: Kenapa tidak langsung logout saat device lain login?**  
A: Karena Flutter tidak tahu session deleted sampai coba API call. Bisa tambah WebSocket listener untuk instant notification.

**Q: Apakah ini aman?**  
A: YA! User tidak bisa melakukan action apapun karena semua API call akan 401. UI cached tidak berbahaya karena tidak bisa modify data.

**Q: Apakah perlu periodic check?**  
A: Optional. Untuk better UX yes, tapi untuk security sudah cukup tanpa itu.

**Q: Bagaimana dengan dialog SessionExpiredDialog?**  
A: Could add that instead of silent redirect. Show dialog with info about new login, then redirect.

---

## 🚀 Next Steps

1. ✅ **Test current implementation**
   - Login di Android
   - Try action di Web
   - Check auto-logout works

2. ⏳ **Decide on enhancements**
   - Want periodic check?
   - Want session expired dialog?
   - Want router guard?

3. 📝 **Document final behavior**
   - Update user guide
   - Add to feature documentation
