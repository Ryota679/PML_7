# 🚀 Quick Start: Deploy Appwrite Function

Complete guide untuk deploy function dalam 10 menit.

---

## ✅ Prerequisites Check

Before starting, make sure you have:
- [ ] Appwrite Cloud account (https://cloud.appwrite.io)
- [ ] Project: `perojek-pml` accessible
- [ ] Node.js installed (`node --version`)

---

## 📋 Step-by-Step Deployment

### **STEP 1: Install Appwrite CLI (5 minutes)**

#### **Windows:**
```powershell
# Run PowerShell as Administrator
iwr -useb https://appwrite.io/cli/install.ps1 | iex
```

#### **Verify Installation:**
```bash
appwrite --version
# Should show: 5.x.x or higher
```

---

### **STEP 2: Login to Appwrite (1 minute)**

```bash
appwrite login
```

**Enter:**
- Endpoint: `https://fra.cloud.appwrite.io/v1`
- Email: [Your Appwrite email]
- Password: [Your password]

✅ You should see: "✓ Success"

---

### **STEP 3: Create Function in Console (3 minutes)**

1. **Open Console:**
   ```
   https://fra.cloud.appwrite.io/console/project-perojek-pml/functions
   ```

2. **Click:** "Create Function"

3. **Fill Form:**
   ```
   Name: approve-registration
   Runtime: Node.js (18.0)
   Execute Access: Server (keep default)
   Events: (leave empty)
   Schedule: (leave empty)
   Timeout: 15 seconds
   ```

4. **Click:** "Create"

5. **Copy Function ID:**
   After creation, you'll see Function ID (e.g., `6734abc123...`)
   **SAVE THIS!** You'll need it later.

---

### **STEP 4: Create API Key (2 minutes)**

1. **In Console, go to:**
   ```
   Settings → API Keys → Create API Key
   ```

2. **Fill:**
   ```
   Name: Function - Approve Registration
   Expiration: Never (or set as needed)
   Scopes:
     ✅ users.read
     ✅ users.write
   ```

3. **Click:** "Create"

4. **IMPORTANT:** Copy the API Key immediately!
   It will only be shown once.
   ```
   Example: standard_abc123...
   ```

---

### **STEP 5: Configure Environment Variables (2 minutes)**

1. **In Function page, click:** "Settings" tab

2. **Add Environment Variables:**

   Click "+ Create variable" for each:

   | Key | Value |
   |-----|-------|
   | `APPWRITE_FUNCTION_ENDPOINT` | `https://fra.cloud.appwrite.io/v1` |
   | `APPWRITE_FUNCTION_PROJECT_ID` | `perojek-pml` |
   | `APPWRITE_FUNCTION_API_KEY` | [Paste API Key from Step 4] |
   | `DATABASE_ID` | `kantin-db` |
   | `USERS_COLLECTION_ID` | `users` |
   | `REGISTRATION_REQUESTS_COLLECTION_ID` | `registration_requests` |

3. **Click:** "Update" after adding all variables

---

### **STEP 6: Deploy Function Code (3 minutes)**

#### **Option A: Via CLI (Recommended)**

1. **Navigate to function directory:**
   ```bash
   cd "d:\Semester 6\Pml\PML_7\appwrite-functions\approve-registration"
   ```

2. **Install dependencies:**
   ```bash
   npm install
   ```

3. **Create `appwrite.json` config:**
   Create file `appwrite.json` in function directory:
   ```json
   {
     "projectId": "perojek-pml",
     "projectName": "perojek-pml",
     "functions": [
       {
         "name": "approve-registration",
         "$id": "YOUR_FUNCTION_ID_FROM_STEP_3",
         "runtime": "node-18.0",
         "path": ".",
         "entrypoint": "src/main.js",
         "ignore": [
           "node_modules",
           ".git"
         ],
         "execute": ["any"],
         "timeout": 15
       }
     ]
   }
   ```
   **Replace:** `YOUR_FUNCTION_ID_FROM_STEP_3` with actual Function ID

4. **Deploy:**
   ```bash
   appwrite deploy function
   ```
   
   Select: `approve-registration`
   
   Wait for upload to complete (~30 seconds)

5. **Activate deployment:**
   - Go to Console → Functions → approve-registration → Deployments
   - Find your deployment
   - Click "..." → "Execute"

#### **Option B: Manual Upload (Alternative)**

1. **Create deployment package:**
   ```bash
   cd "d:\Semester 6\Pml\PML_7\appwrite-functions\approve-registration"
   npm install
   ```

2. **Create archive:**
   ```bash
   # Windows (PowerShell)
   Compress-Archive -Path package.json,src,node_modules -DestinationPath function.zip
   ```

3. **Upload via Console:**
   - Functions → approve-registration → Deployments tab
   - Click "Create deployment"
   - Upload `function.zip`
   - Entrypoint: `src/main.js`
   - Click "Create"
   - Wait for build (~2 minutes)
   - Click "Activate" on the deployment

---

### **STEP 7: Update Flutter Config (1 minute)**

1. **Open file:**
   ```
   d:\Semester 6\Pml\PML_7\kantin_app\lib\core\config\appwrite_config.dart
   ```

2. **Replace Function ID:**
   ```dart
   // Find this line:
   static const String approveRegistrationFunctionId = 'YOUR_FUNCTION_ID_HERE';
   
   // Replace with:
   static const String approveRegistrationFunctionId = '6734abc123...'; // Your actual Function ID
   ```

3. **Save file**

---

### **STEP 8: Test Function (2 minutes)**

#### **Test in Console First:**

1. **Go to:**
   ```
   Functions → approve-registration → Execute
   ```

2. **Test payload:**
   ```json
   {
     "requestId": "test-123",
     "adminUserId": "admin-123",
     "temporaryPassword": "TestPass123",
     "notes": "Test execution"
   }
   ```
   
   **Note:** This will fail because `test-123` doesn't exist, but it validates the function runs.

3. **Check logs:**
   - Should see error about requestId not found
   - This is OK! It means function is working.

#### **Test in Flutter App:**

1. **Hot reload/restart app:**
   ```bash
   # In terminal where flutter is running:
   R  # Capital R for hot restart
   ```

2. **Test approve flow:**
   - Register new business owner (or use existing pending)
   - Login as admin
   - Go to "Registrasi" tab → "Pending"
   - Click "Approve" on a pending request
   - Enter temporary password
   - Click "Setujui"

3. **Expected result:**
   - ✅ Success message
   - ✅ User created in Auth
   - ✅ Document created in users collection
   - ✅ Status updated to "approved"
   - ✅ User visible in "Kelola Users" tab
   - ✅ User can login with temp password

---

## 🐛 Troubleshooting

### **Error: "Appwrite Function not configured"**
→ Update Function ID in `appwrite_config.dart` (Step 7)

### **Error: "Missing API Key"**
→ Check environment variables in Function settings (Step 5)

### **Error: "User already exists"**
→ Email already registered. Delete from Auth → Users or use different email.

### **Function not executing**
→ Check deployment is active in Console → Functions → Deployments

### **"Failed to create document"**
→ Check collection permissions allow create for authenticated users

---

## ✅ Success Checklist

After deployment, verify:
- [ ] Function shows in Console
- [ ] Environment variables configured
- [ ] Deployment active
- [ ] Function ID updated in Flutter
- [ ] Test execution works
- [ ] Approve creates user successfully
- [ ] User can login
- [ ] User appears in "Kelola Users"

---

## 📊 Monitoring

### **View Function Logs:**
```
Console → Functions → approve-registration → Executions
```

Each execution shows:
- ✅ Timestamp
- ✅ Status (completed/failed)
- ✅ Duration
- ✅ Logs output
- ✅ Response

### **Common Log Messages:**
```
✅ "Processing registration approval..." - Function started
✅ "User created in Auth with ID: ..." - Auth user created
✅ "User document created successfully" - Database updated
✅ "Registration approval completed successfully" - Success!
❌ "User already exists" - Email conflict
❌ "Failed to create user" - Auth error
```

---

## 🎯 Next Steps

After successful deployment:

1. ✅ Delete manual user creation docs (no longer needed)
2. ✅ Test with multiple registrations
3. ✅ Monitor function executions
4. ✅ Set up error notifications (optional)
5. ✅ Document for team

---

## 📞 Need Help?

- **Function not working?** Check logs in Console
- **Build failing?** Verify Node.js version (18+)
- **Permission errors?** Check API key scopes
- **Still stuck?** Review full README.md

---

**Total Time:** ~10-15 minutes  
**Difficulty:** Easy  
**Status:** Production Ready ✅

---

**Last Updated:** 2025-11-19
