# 🚀 Appwrite Function Deployment Guide
## Create Tenant User Function

Last Updated: 26 November 2025

---

## 📋 Overview

Function Name: **create-tenant-user**  
Purpose: Create tenant users in both Appwrite Auth and Database  
Runtime: Node.js 21.0

---

## 🔧 Step-by-Step Deployment

### **Step 1: Create Function in Appwrite Console**

1. Open: https://fra.cloud.appwrite.io/console
2. Select Project: **perojek-pml**
3. Navigate to: **Functions** (sidebar)
4. Click: **"Create Function"**

**Configuration:**
```
Function ID: create-tenant-user
Name: Create Tenant User
Runtime: Node.js (21.0)
Execute Access: Any
Events: (leave empty)
Schedule: (leave empty)
Timeout: 15 seconds
```

Click **"Create"**

---

### **Step 2: Configure Function Settings**

1. Click on your new function: **create-tenant-user**
2. Go to **"Settings"** tab

**Basic Settings:**
- ✅ Enabled: ON
- Timeout: 15 seconds
- Execute Access: Any

**Environment Variables:**

Add these variables (click "+ Add Variable"):

```
Key: APPWRITE_ENDPOINT
Value: https://fra.cloud.appwrite.io/v1

Key: APPWRITE_PROJECT_ID
Value: perojek-pml

Key: DATABASE_ID
Value: kantin-db
```

Click **"Update"**

---

### **Step 3: Deploy Function Code**

1. Go to **"Deployments"** tab
2. Click **"Create deployment"**
3. Choose: **"Manual"**

**Create 2 files:**

#### **File 1: `index.js`**

```javascript
const sdk = require('node-appwrite');

/**
 * Create Tenant User Function
 * Creates user in Auth and Database
 */
module.exports = async ({ req, res, log, error }) => {
  try {
    // Parse request body
    const data = JSON.parse(req.body || '{}');
    const { email, password, fullName, username, tenantId, phone } = data;

    // Validate required fields
    if (!email || !password || !fullName || !username || !tenantId) {
      return res.json({
        success: false,
        error: 'Missing required fields: email, password, fullName, username, tenantId'
      }, 400);
    }

    log(`Creating tenant user: ${email}`);

    // Initialize Appwrite SDK with API key
    const client = new sdk.Client()
      .setEndpoint(process.env.APPWRITE_ENDPOINT || 'https://fra.cloud.appwrite.io/v1')
      .setProject(process.env.APPWRITE_PROJECT_ID || 'perojek-pml')
      .setKey(req.headers['x-appwrite-key'] || '');

    const users = new sdk.Users(client);
    const databases = new sdk.Databases(client);

    // Step 1: Create Auth user
    log('Step 1: Creating Auth account...');
    const authUser = await users.create(
      sdk.ID.unique(),
      email,
      phone,
      password,
      fullName
    );

    log(`Auth user created: ${authUser.$id}`);

    // Step 2: Create user document in database
    log('Step 2: Creating user document...');
    const userDoc = await databases.createDocument(
      process.env.DATABASE_ID || 'kantin-db',
      'users',
      authUser.$id, // Use same ID as Auth user
      {
        user_id: authUser.$id,
        role: 'tenant',
        full_name: fullName,
        username: username,
        email: email,
        phone: phone || '',
        tenant_id: tenantId,
        is_active: true,
      }
    );

    log(`User document created: ${userDoc.$id}`);

    // Return success
    return res.json({
      success: true,
      userId: authUser.$id,
      message: `User ${fullName} created successfully`
    });

  } catch (err) {
    error(`Function error: ${err.message}`);
    
    return res.json({
      success: false,
      error: err.message,
      code: err.code
    }, 500);
  }
};
```

#### **File 2: `package.json`**

```json
{
  "name": "create-tenant-user",
  "version": "1.0.0",
  "description": "Create tenant user in Auth and Database",
  "main": "index.js",
  "scripts": {
    "test": "echo \"Error: no test specified\" && exit 1"
  },
  "dependencies": {
    "node-appwrite": "^13.0.0"
  },
  "devDependencies": {},
  "author": "",
  "license": "ISC"
}
```

4. Click **"Create"** or **"Deploy"**
5. Wait for deployment to complete (~30-60 seconds)
6. Status should show: **✅ Ready**

---

### **Step 4: Get Function ID**

After deployment completes:

1. Go to **"Settings"** tab
2. Find **"Function ID"** at the top
3. Copy the ID (e.g., `674598f0001234567890`)

**Update Flutter Config:**

Open: `lib/core/config/appwrite_config.dart`

Replace:
```dart
static const String createTenantUserFunctionId = 'create-tenant-user';
```

With:
```dart
static const String createTenantUserFunctionId = '674598f0001234567890'; // YOUR ACTUAL ID
```

---

### **Step 5: Verify API Key Permissions**

The function uses the API key passed from Flutter app. Make sure your API key has these scopes:

**Go to:** Settings → API Keys → Find your key (`tenant-user-function`)

**Required Scopes:**
- ✅ `users.read`
- ✅ `users.write`
- ✅ `databases.read`
- ✅ `databases.write`

If key doesn't exist, create one:
1. Click **"Create API Key"**
2. Name: `tenant-user-function`
3. Expiration: Never (or 1 year)
4. Select scopes above
5. Click **"Create"**
6. **COPY the key** (shown only once!)
7. Update `lib/core/config/appwrite_config.dart`:
   ```dart
   static const String serverApiKey = 'YOUR_NEW_API_KEY_HERE';
   ```

---

## ✅ Testing

### **Test via Appwrite Console:**

1. Go to function → **"Execute"** tab
2. Enter test body:
   ```json
   {
     "email": "test@example.com",
     "password": "TestPass123!",
     "fullName": "Test User",
     "username": "testuser",
     "tenantId": "YOUR_TENANT_ID",
     "phone": "08123456789"
   }
   ```
3. Add header:
   ```
   x-appwrite-key: YOUR_API_KEY
   ```
4. Click **"Execute"**
5. Check response:
   ```json
   {
     "success": true,
     "userId": "...",
     "message": "User Test User created successfully"
   }
   ```

### **Test via Flutter App:**

1. Run app: `flutter run -d chrome`
2. Login as Business Owner (e.g., `wongireng`)
3. Go to: **Kelola User Tenant**
4. Click: **"+ Assign User"**
5. Switch to: **"Buat Baru"** tab
6. Fill form:
   - Username: `testuser2`
   - Nama: `Test User 2`
   - Email: `test2@example.com`
   - Password: `Test123!@#`
   - Phone: `08123456789`
   - Tenant: Select one
7. Click **"Buat & Assign"**
8. Should show success message ✅

### **Verify User Created:**

**Check Auth:**
1. Appwrite Console → Auth → Users
2. Find: `test2@example.com`
3. Status: Active ✅

**Check Database:**
1. Appwrite Console → Databases → kantin-db → users
2. Find document with email: `test2@example.com`
3. Check fields: username, tenant_id, role ✅

**Test Login:**
1. Logout from app
2. Login with:
   - Email: `test2@example.com`
   - Password: `Test123!@#`
3. Should redirect to Tenant Dashboard ✅

---

## 🐛 Troubleshooting

### **Error: "Function not found"**
- Check function ID in `appwrite_config.dart` matches actual ID
- Function must be deployed and status = Ready

### **Error: "Invalid API key"**
- Check API key in `appwrite_config.dart` is correct
- API key must have `users.write` and `databases.write` scopes
- API key must not be expired

### **Error: "Missing required fields"**
- Check all form fields are filled
- Check payload structure matches function expectation

### **Error: "Email already exists"**
- User dengan email tersebut sudah ada di Appwrite Auth
- Use different email or delete existing user first

### **Function execution timeout**
- Increase timeout in Function Settings (max 900s)
- Check function logs for errors

---

## 📊 Monitoring

**View Function Logs:**
1. Go to function → **"Executions"** tab
2. Click on an execution to see logs
3. Check for errors or success messages

**Log Levels:**
- `log()` - Info messages
- `error()` - Error messages

---

## 🔒 Security Notes

⚠️ **IMPORTANT:**
- API key is passed from client (Flutter app)
- For MVP/development only
- **Production:** Move API key to Appwrite server-side (environment variables)
- **Better:** Use Appwrite Teams/Labels for permission management

---

## 📝 Summary Checklist

- [ ] Function created in Appwrite Console
- [ ] Function code deployed (index.js + package.json)
- [ ] Deployment status: Ready ✅
- [ ] Environment variables configured
- [ ] Function ID copied to `appwrite_config.dart`
- [ ] API key has correct scopes
- [ ] API key copied to `appwrite_config.dart`
- [ ] Tested via Console (optional)
- [ ] Tested via Flutter app ✅
- [ ] User created in Auth ✅
- [ ] User document created in Database ✅
- [ ] User can login ✅

---

## 🎉 Success!

Once all checkboxes are complete, your function is ready to use!

New tenant users will be created automatically with:
- ✅ Appwrite Auth account (can login)
- ✅ Database document (user data)
- ✅ Auto-assigned to tenant
- ✅ Ready to use immediately

---

**Next Steps:**
- Update existing users (hari, budi, sari, far) by creating them via app or console
- Test product management with tenant users
- Continue to Sprint 3 (Guest ordering flow)

---

Last updated: 26 November 2025, 13:20 WIB
