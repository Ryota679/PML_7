# Single Device Login - Debug Guide

## 🐛 Troubleshooting: Both Devices Still Active

Jika setelah implementasi masih bisa login di 2 device bersamaan, ikuti langkah debugging ini:

### Step 1: Verify Appwrite Session Limit

**CRITICAL CHECK:**

1. Login to [Appwrite Console](https://cloud.appwrite.io)
2. Select your project
3. **Settings** → **Auth** tab
4. Scroll to **"Sessions limit"**
5. **MUST BE: 1** (not 10, not unlimited!)
6. Click **Update** jika belum

**Screenshot check:**
```
Sessions limit: [__1__] ← MUST BE 1!
```

---

### Step 2: Read Debug Console Logs

Saat login, cari output di console:

```
═══════════════════════════════════════════════════════
🔐 [SINGLE DEVICE LOGIN] Step 3.7: Session Tracking
═══════════════════════════════════════════════════════
✅ [SESSION] Session retrieved successfully
   ├─ Session ID: 67a1b2c3d4e5f6
   ├─ User ID: user_123
   ├─ Provider: email
   └─ Expires: 2026-12-22T14:00:00.000Z

📱 [DEVICE] Device detection:
   ├─ Platform: android
   └─ Info: Android Device

📊 [PREVIOUS] Previous session data:
   ├─ Previous Session ID: 67a0b1c2d3e4f5
   ├─ Previous Device: web
   └─ Previous Login: 2025-12-22T13:00:00.000Z

💾 [DATABASE] Updating session tracking...
   ├─ Document ID: doc_456
   ├─ New Session ID: 67a1b2c3d4e5f6
   ├─ New Device: android
   └─ Timestamp: 2025-12-22 14:00:00

✅ [DATABASE] Session tracking updated successfully

🔄 [DEVICE SWITCH] Device change detected!
   ├─ From: web
   ├─ To: android
   └─ Action: Setting dialog flag

⚠️  [SESSION LIMIT] IMPORTANT CHECK:
   └─ Appwrite should have AUTOMATICALLY deleted old session
   └─ If both devices still active, session limit NOT working!
   └─ Verify: Appwrite Console → Settings → Auth → Sessions limit = 1
```

---

### Step 3: Verify Old Session is Expired

**On OLD device (Web):**

1. After login di device baru
2. Try to click any menu
3. Watch the console/network tab
4. **Expected:** API call returns `401 Unauthorized`

**Check Appwrite Console:**

1. **Auth** → **Sessions** tab
2. Filter by user email
3. **Should show:** ONLY 1 active session
4. **If shows 2+:** Session limit NOT working!

---

### Step 4: Common Issues

#### Issue 1: Session Limit Not Set

**Symptom:**
```
📊 [PREVIOUS] Previous session data:
   ├─ Previous Session ID: null (first login)
```

**Solution:**
- Appwrite Console → Settings → Auth → Sessions limit = 1
- Save and try again

---

#### Issue 2: Different User Accounts

**Symptom:**
Both devices work but dengan akun berbeda

**Check:**
```
📊 [PREVIOUS] Previous session data:
   ├─ Previous Session ID: null (first login)
```

**Solution:**
Login dengan **EXACT SAME** email/password di kedua device

---

#### Issue 3: Database Update Failed

**Symptom:**
```
❌ [AUTH REPO] Update failed:
   ├─ Error: AppwriteException: ...
```

**Solution:**
- Check Appwrite database permissions
- Field `last_session_id`, `last_login_at`, dll harus exists
- Collection permissions allow user to update own document

---

#### Issue 4: Session Limit = Unlimited

**Symptom:**
Console shows session created but old still active

**Check Appwrite Console:**
```
Settings → Auth → Sessions limit
If: "unlimited" or number > 1
Then: NOT ENFORCING SINGLE SESSION!
```

**Fix:**
Set to **1** and save!

---

### Step 5: Manual Test Script

Run this test:

1. **Device 1 (Web):**
   ```
   Login → Success
   Check console: Session ID = xyz123
   ```

2. **Device 2 (Android):**
   ```
   Login (same account) → Success
   Check console: Session ID = abc456
   ```

3. **Back to Device 1:**
   ```
   Click any menu
   Expected: 401 Error
   Actual: ??? (check console)
   ```

4. **Appwrite Console:**
   ```
   Auth → Sessions
   Expected: 1 session (abc456)
   Actual: ??? (check console)
   ```

---

### Step 6: Verify Field Names

**CRITICAL:** Field names must EXACT match:

Database fields:
- `last_session_id` (NOT lastSessionId, NOT session_id)
- `last_login_at` (NOT lastLoginAt, NOT login_at)
- `last_login_device` (NOT lastLoginDevice)
- `last_login_device_info` (NOT lastLoginDeviceInfo)

Code references (camelCase in Dart):
- `lastSessionId`
- `lastLoginAt`
- `lastLoginDevice`
- `lastLoginDeviceInfo`

---

### Expected Debug Output

**First Login (No previous session):**
```
📊 [PREVIOUS] Previous session data:
   ├─ Previous Session ID: null (first login)
   ├─ Previous Device: null
   └─ Previous Login: null

ℹ️  [FIRST LOGIN] This is the first login for this user
```

**Second Login (Same device):**
```
📊 [PREVIOUS] Previous session data:
   ├─ Previous Session ID: 67a1b2c3d4e5f6
   ├─ Previous Device: android
   └─ Previous Login: 2025-12-22T14:00:00.000Z

ℹ️  [SAME DEVICE] User logged in from same device: android
```

**Second Login (Different device):**
```
📊 [PREVIOUS] Previous session data:
   ├─ Previous Session ID: 67a1b2c3d4e5f6
   ├─ Previous Device: web
   └─ Previous Login: 2025-12-22T13:00:00.000Z

🔄 [DEVICE SWITCH] Device change detected!
   ├─ From: web
   ├─ To: android
   └─ Action: Setting dialog flag
```

---

## 🎯 Quick Diagnosis

| Symptom | Cause | Fix |
|---------|-------|-----|
| No debug logs appear | kDebugMode = false | Run in Debug mode |
| Previous session = null always | Database not updating | Check field names & permissions |
| Both devices active | Session limit not set | Appwrite Console: limit = 1 |
| 401 error not shown | Session valid on both | Session limit NOT working |
| Dialog doesn't show | Flag not set | Check device detection logs |

---

## 📞 Next Steps

1. ✅ Enable debug mode: `flutter run` (not release)
2. ✅ Login di device 1
3. ✅ Copy semua debug logs
4. ✅ Login di device 2
5. ✅ Copy semua debug logs
6. ✅ Check Appwrite Console → Sessions
7. ✅ Share logs untuk analysis

**Logs yang dibutuhkan:**
- [ ] Device 1 login logs
- [ ] Device 2 login logs
- [ ] Appwrite Console screenshot (Sessions tab)
- [ ] Appwrite Console screenshot (Settings → Auth → Sessions limit)
