# 🧪 APK Testing Guide - Pre-Midtrans Submission

**Objective:** Verify production APK is clean and ready for Midtrans review

---

## 📱 Installation

```bash
cd C:\kantin_app\build\app\outputs\flutter-apk
adb install app-release.apk
```

If error `INSTALL_FAILED`:
```bash
adb uninstall com.example.kantin_app
adb install app-release.apk
```

---

## 🔍 Verify Debug Logs Hidden

### Quick Test (5 minutes)

**Terminal 1 - Start Monitoring:**
```bash
# Clear old logs
adb logcat -c

# Monitor app logs
adb logcat | findstr "kantin DEBUG SWAP print"
```

**Actions:**
1. Open app
2. Login
3. Navigate dashboards
4. Create tenant/products
5. Test web ordering

**✅ PASS if:**
- Minimal output (< 5 lines)
- No `[DEBUG]` or `[SWAP]` messages
- No visible `print()` statements

**❌ FAIL if:**
- Debug spam visible
- Messages like "🔄 [SWAP DEBUG]" appear
- Many print statements shown

---

## 🎯 Functional Testing Checklist

### 1. Authentication (5 min)
- [ ] Google OAuth login
- [ ] Email/password login
- [ ] Correct post-login redirect
- [ ] No crashes

### 2. Business Owner (10 min)
- [ ] Dashboard loads
- [ ] Create tenant
- [ ] View tenant list
- [ ] Contract management
- [ ] No permission errors

### 3. Tenant Features (10 min)
- [ ] Tenant dashboard
- [ ] Add/edit/delete product
- [ ] Add category
- [ ] Add staff
- [ ] Generate QR code

### 4. Web Ordering (10 min)
- [ ] Scan QR (use 2nd device)
- [ ] Web page loads (https://kantin-web-ordering.vercel.app/)
- [ ] Products display
- [ ] Add to cart
- [ ] Checkout
- [ ] Order created

### 5. Order Management (5 min)
- [ ] Orders appear
- [ ] Real-time updates
- [ ] Update status
- [ ] No crashes

---

## 🚨 Error Checking

**Network Errors:**
```bash
adb logcat | findstr /I "error exception failed"
```

**Crashes:**
```bash
adb logcat | findstr /I "FATAL crash"
```

**Expected:** Minimal errors, only legitimate issues

---

## ✅ Final Checklist

- [ ] APK installed successfully
- [ ] Logcat shows MINIMAL debug logs
- [ ] No kDebugMode prints visible
- [ ] All features tested (30+ min)
- [ ] No crashes
- [ ] Network stable
- [ ] Web ordering works E2E
- [ ] Real-time updates working

---

## 🎯 Decision

**IF ALL ✅:** Safe to submit to Midtrans! 🚀

**IF ANY ❌:** Fix issues before submission

---

## 💡 Pro Tips

**Record Logcat:**
```bash
adb logcat > logcat_test.txt
# Test for 5 minutes
# Review logcat_test.txt
```

**Screenshot Features:**
- Working dashboards
- Successful orders
- QR code generation
- For Midtrans documentation

**Test Multiple Devices:**
- Different Android versions
- Different screen sizes

---

## 📦 APK Info

**Location:** `C:\kantin_app\build\app\outputs\flutter-apk\app-release.apk`  
**Size:** ~76.7 MB  
**Build:** Release (production)  
**Debug Logs:** Wrapped with `kDebugMode` (auto-removed in release)
