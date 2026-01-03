# Appwrite Function: Approve Registration

Auto-create user in Appwrite Auth and database when admin approves registration.

## 🚀 Features

- ✅ Creates user in Appwrite Authentication
- ✅ Creates user document in `users` collection
- ✅ Updates registration request status
- ✅ Transaction rollback on failure
- ✅ Proper error handling
- ✅ Production-ready

---

## 📋 Prerequisites

- Appwrite Cloud account (https://cloud.appwrite.io)
- Appwrite CLI installed ([Install Guide](https://appwrite.io/docs/tooling/command-line/installation))
- Node.js 18+ (for local testing)

---

## 🔧 Setup Instructions

### **Step 1: Install Appwrite CLI**

```bash
# Windows (PowerShell as Admin)
iwr -useb https://appwrite.io/cli/install.ps1 | iex

# Or via npm
npm install -g appwrite-cli
```

Verify installation:
```bash
appwrite --version
```

---

### **Step 2: Login to Appwrite**

```bash
appwrite login
```

Follow prompts:
- Endpoint: `https://fra.cloud.appwrite.io/v1`
- Email: [Your Appwrite account email]
- Password: [Your password]

---

### **Step 3: Initialize Project**

```bash
# Navigate to function directory
cd "d:\Semester 6\Pml\PML_7\appwrite-functions\approve-registration"

# Link to your Appwrite project
appwrite init project

# Select: perojek-pml
```

---

### **Step 4: Create Function in Appwrite Console**

1. **Go to Appwrite Console:**
   ```
   https://fra.cloud.appwrite.io/console/project-perojek-pml
   ```

2. **Navigate:**
   ```
   Functions → Create Function
   ```

3. **Configure:**
   ```
   Name: approve-registration
   Runtime: Node.js 18.0
   Execute Access: Server (default)
   ```

4. **Add Environment Variables:**
   ```
   APPWRITE_FUNCTION_ENDPOINT = https://fra.cloud.appwrite.io/v1
   APPWRITE_FUNCTION_PROJECT_ID = perojek-pml
   APPWRITE_FUNCTION_API_KEY = [Your API Key - see below]
   DATABASE_ID = kantin-db
   USERS_COLLECTION_ID = users
   REGISTRATION_REQUESTS_COLLECTION_ID = registration_requests
   ```

5. **Create API Key:**
   - Settings → API Keys → Create API Key
   - Name: `Function - Approve Registration`
   - Scopes: ✅ `users.write`
   - Copy the API key and paste in environment variables

6. **Save Function**

---

### **Step 5: Deploy Function**

#### **Option A: Via Appwrite CLI (Recommended)**

```bash
# Install dependencies
npm install

# Deploy to Appwrite
appwrite deploy function

# Select: approve-registration
# Confirm deployment
```

#### **Option B: Manual Upload (Console)**

1. **Create deployment package:**
   ```bash
   npm install
   tar -czf function.tar.gz package.json src/ node_modules/
   ```

2. **Upload via Console:**
   - Functions → approve-registration → Deployments
   - Create Deployment → Upload `function.tar.gz`
   - Set as Active

---

### **Step 6: Get Function ID**

After deployment, copy **Function ID** from console (e.g., `6734abc123...`)

You'll need this for Flutter integration.

---

## 📱 Flutter Integration

Update `appwrite_config.dart`:

```dart
class AppwriteConfig {
  // ... existing config ...
  
  // Function IDs
  static const String approveRegistrationFunctionId = 'YOUR_FUNCTION_ID_HERE';
}
```

The Flutter code will automatically call this function when admin approves.

---

## 🧪 Testing

### **Test via Console:**

1. Functions → approve-registration → Execute
2. Test payload:
   ```json
   {
     "requestId": "test-request-id",
     "adminUserId": "admin-user-id",
     "temporaryPassword": "TestPassword123",
     "notes": "Test approval"
   }
   ```

### **Test via Flutter App:**

1. Register new business owner
2. Admin approve registration
3. Check logs in Function console
4. Verify user created in Auth → Users
5. Verify document in Database → kantin-db → users
6. Test login with temporary password

---

## 📊 Function Payload

### **Request:**
```json
{
  "requestId": "string (required)",
  "adminUserId": "string (optional)",
  "temporaryPassword": "string (required)",
  "notes": "string (optional)"
}
```

### **Success Response:**
```json
{
  "success": true,
  "message": "User created successfully",
  "data": {
    "userId": "6734abc...",
    "email": "user@example.com",
    "fullName": "User Name",
    "role": "owner_business"
  }
}
```

### **Error Response:**
```json
{
  "success": false,
  "error": "Error message",
  "code": "ERROR_CODE"
}
```

---

## 🔐 Security Notes

### **API Key Permissions:**
Function requires API key with:
- ✅ `users.write` - To create users in Auth

### **Function Access:**
- Execute Access: **Server** (not public)
- Only callable from authenticated Flutter app
- Admin role verification done in Flutter

### **Environment Variables:**
- Never commit API keys to git
- Use different API keys for dev/prod
- Rotate keys regularly

---

## 🐛 Troubleshooting

### **Error: "Missing API Key"**
- Check environment variables in Function settings
- Verify API key has `users.write` scope

### **Error: "User already exists"**
- Email already registered in Auth
- Check Auth → Users in console
- Delete existing user or use different email

### **Error: "Failed to create document"**
- Check Database permissions
- Verify collection ID is correct
- Check field types match

### **Function not executing**
- Check function is deployed and active
- Check logs in Function console
- Verify Function ID in Flutter code

---

## 📝 Logs

View function logs in Console:
```
Functions → approve-registration → Executions
```

Logs show:
- ✅ Request received
- ✅ User creation steps
- ✅ Success/error messages
- ⚠️ Rollback actions (if needed)

---

## 🔄 Rollback Logic

If user document creation fails:
1. ⚠️ Function detects error
2. 🔄 Automatically deletes user from Auth
3. ❌ Returns error to Flutter
4. 📝 Admin can retry approval

This prevents orphaned users in Auth.

---

## 📚 Resources

- [Appwrite Functions Docs](https://appwrite.io/docs/products/functions)
- [Node.js SDK](https://appwrite.io/docs/sdks#server)
- [Appwrite CLI](https://appwrite.io/docs/tooling/command-line)

---

## 🎯 Next Steps

After successful deployment:

1. ✅ Test function via Console
2. ✅ Update Flutter `appwrite_config.dart` with Function ID
3. ✅ Test approve flow in app
4. ✅ Monitor function executions
5. ✅ Set up error notifications (optional)

---

**Created:** 2025-11-19  
**Version:** 1.0.0  
**Runtime:** Node.js 18.0
