# ✅ Deployment Checklist - Appwrite Functions

Print this or keep it open while deploying!

---

## 📋 Pre-Deployment

- [ ] Node.js installed (`node --version`)
- [ ] Access to Appwrite Console (https://fra.cloud.appwrite.io)
- [ ] Project `perojek-pml` accessible
- [ ] Text editor ready for copying Function ID

---

## 🚀 Deployment Steps

### **1. Install CLI** ⏱️ 2 min

```powershell
iwr -useb https://appwrite.io/cli/install.ps1 | iex
```

- [ ] Ran command
- [ ] Verified: `appwrite --version` works

---

### **2. Login** ⏱️ 1 min

```bash
appwrite login
```

- [ ] Endpoint: `https://fra.cloud.appwrite.io/v1`
- [ ] Entered email
- [ ] Entered password
- [ ] Saw "✓ Success"

---

### **3. Create Function** ⏱️ 3 min

URL: https://fra.cloud.appwrite.io/console/project-perojek-pml/functions

- [ ] Clicked "Create Function"
- [ ] Name: `approve-registration`
- [ ] Runtime: `Node.js (18.0)`
- [ ] Execute Access: `Server`
- [ ] Clicked "Create"
- [ ] **SAVED Function ID:** `________________`

---

### **4. Create API Key** ⏱️ 2 min

Settings → API Keys → Create API Key

- [ ] Name: `Function - Approve Registration`
- [ ] Expiration: `Never` (or custom)
- [ ] Scope: ✅ `users.read`
- [ ] Scope: ✅ `users.write`
- [ ] Clicked "Create"
- [ ] **SAVED API Key:** `________________`

---

### **5. Set Environment Variables** ⏱️ 2 min

In Function settings, add these 6 variables:

- [ ] `APPWRITE_FUNCTION_ENDPOINT` = `https://fra.cloud.appwrite.io/v1`
- [ ] `APPWRITE_FUNCTION_PROJECT_ID` = `perojek-pml`
- [ ] `APPWRITE_FUNCTION_API_KEY` = `[Your API Key]`
- [ ] `DATABASE_ID` = `kantin-db`
- [ ] `USERS_COLLECTION_ID` = `users`
- [ ] `REGISTRATION_REQUESTS_COLLECTION_ID` = `registration_requests`
- [ ] Clicked "Update"

---

### **6. Deploy Code** ⏱️ 3 min

```bash
cd "d:\Semester 6\Pml\PML_7\appwrite-functions\approve-registration"
npm install
appwrite deploy function
```

- [ ] Navigated to directory
- [ ] Ran `npm install` (wait ~30s)
- [ ] Created `appwrite.json` with Function ID
- [ ] Ran `appwrite deploy function`
- [ ] Selected `approve-registration`
- [ ] Deployment completed
- [ ] Went to Console → Deployments
- [ ] Clicked "Activate" on deployment

---

### **7. Update Flutter** ⏱️ 1 min

File: `lib/core/config/appwrite_config.dart`

```dart
static const String approveRegistrationFunctionId = 'PASTE_FUNCTION_ID_HERE';
```

- [ ] Opened file
- [ ] Replaced `YOUR_FUNCTION_ID_HERE`
- [ ] Pasted Function ID from Step 3
- [ ] Saved file

---

### **8. Restart App** ⏱️ 1 min

```bash
# In Flutter terminal:
R  # Capital R for hot restart
```

- [ ] Pressed `R` in terminal
- [ ] App restarted
- [ ] No errors shown

---

## 🧪 Testing

### **Quick Test:**

- [ ] Login as admin
- [ ] Go to "Registrasi" → "Pending"
- [ ] Click "Approve" on a request
- [ ] Enter temp password (min 8 chars)
- [ ] Clicked "Setujui"
- [ ] **RESULT:** Success message? ___
- [ ] Checked "Kelola Users" tab
- [ ] **RESULT:** User appears? ___
- [ ] Logged out
- [ ] Logged in as new user
- [ ] **RESULT:** Access dashboard? ___

---

### **Check Logs:**

Console → Functions → approve-registration → Executions

- [ ] Saw execution in list
- [ ] Status: `completed`
- [ ] Response: `{"success":true,...}`
- [ ] No errors in logs

---

## ✅ Verification

All of these should be TRUE:

- [ ] Function shows "Active" in Console
- [ ] Environment variables all set (6 total)
- [ ] Function ID updated in Flutter code
- [ ] Test approval succeeded
- [ ] User created in Auth → Users
- [ ] Document created in Database → users
- [ ] User can login with temp password
- [ ] User appears in "Kelola Users" tab
- [ ] No errors in function logs
- [ ] Process takes <10 seconds

---

## 🐛 If Something Fails

### **Error: "Function not configured"**
→ Check Step 7: Function ID in Flutter

### **Error: "Missing API Key"**
→ Check Step 5: Environment variables

### **Error: "User already exists"**
→ Email already in Auth → Delete and retry

### **Error: "Function execution failed"**
→ Check Step 6: Deployment is active

### **Function not in list**
→ Check Step 3: Created in Console

---

## 📊 Post-Deployment

- [ ] Documented Function ID for team
- [ ] Saved API key securely (password manager)
- [ ] Tested with 2-3 more registrations
- [ ] Monitored function executions
- [ ] All tests passed
- [ ] Ready for production use

---

## 📞 Resources

If stuck, check:
- ✅ `appwrite-functions/QUICK_START.md` - Detailed guide
- ✅ `appwrite-functions/approve-registration/README.md` - Full docs
- ✅ `IMPLEMENTATION_SUMMARY.md` - Overview
- ✅ Function logs in Console
- ✅ Appwrite Docs: https://appwrite.io/docs

---

## 🎉 Success!

If all checks are ✅, congratulations!

**You've deployed a production-ready Appwrite Function!**

**Time taken:** ___ minutes  
**Status:** ✅ Complete  
**Next:** Start approving registrations automatically!

---

**Date Deployed:** ___/___/_____  
**Deployed By:** ___________  
**Function ID:** ___________  
**Status:** ⬜ Pending / ✅ Complete
