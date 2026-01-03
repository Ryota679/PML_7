# 🔐 Google OAuth Complete Implementation Guide

**Project:** Kantin QR-Order App  
**Version:** 2.0 (Updated with Invitation System)  
**Status:** Ready for Implementation  
**Last Updated:** 17 December 2025  
**Estimated Duration:** 10-14 days

---

## 📋 Table of Contents

1. [Overview & Strategy](#overview--strategy)
2. [UI/UX Design](#uiux-design)
3. [Technical Setup](#technical-setup)
4. [Implementation Code](#implementation-code)
5. [Migration Plan](#migration-plan)
6. [Testing Checklist](#testing-checklist)

---

## 1. Overview & Strategy

### **What Changes?**

| Aspect | Current (Development) | New (Production) |
|--------|----------------------|------------------|
| **Owner Registration** | Admin approval + 30d trial | Google OAuth + FREE tier |
| **Tenant Registration** | Owner creates manually | Self-register with invitation code |
| **Staff Registration** | Tenant creates manually | Self-register with invitation code |
| **Login** | Separate pages per role | 1 universal login (auto-detect role) |
| **Account Creation** | `create-user` function | Google handles Auth, client creates DB |

### **Key Benefits**

✅ **No spam** - Google verification required  
✅ **Better UX** - No password management  
✅ **Self-service** - Users register themselves  
✅ **Secure** - Invitation codes control access  
✅ **Scalable** - No manual account creation overhead

---

## 2. UI/UX Design

### **2.1 Landing Page (Scrollable)**

![Landing Page](C:/Users/Ryan/.gemini/antigravity/brain/dc1d1508-f9b4-4d2d-abec-c0bab0d47d13/landing_scrollable_1765959086065.png)

**Layout:**

```
┌─────── ABOVE FOLD ───────┐
│  🍴 Logo (small)         │
│  Kantin App              │
│  Order makanan...        │
│                           │
│ ┌─────────────────────┐  │
│ │ Masukkan Kode       │  │
│ │ [_______________]   │  │
│ │ [ Mulai Order ]     │  │ → Navigate to tenant menu
│ └─────────────────────┘  │
│    ───── atau ─────      │
│                           │
├─────── SCROLL DOWN ──────┤
│                           │
│  Bergabung sebagai:      │
│                           │
│ [ 🏪 Pemilik Usaha ]    │ → Owner registration
│ [ 👤 Tenant ]           │ → Tenant registration
│ [ 👨‍💼 Staff ]            │ → Staff registration
│                           │
│  Sudah punya akun?       │
│  Login                   │ → Universal login
└───────────────────────────┘
```

**Key Points:**
- ✅ Guest ordering stays above fold (primary use case)
- ✅ Registration options below fold (scroll to see)
- ✅ Not crowded - spacious design (~900px total height)

---

### **2.2 Universal Login Page**

![Login Page](C:/Users/Ryan/.gemini/antigravity/brain/dc1d1508-f9b4-4d2d-abec-c0bab0d47d13/oauth_login_page_1765958468468.png)

**Purpose:** ONE login for all roles (Owner, Tenant, Staff)

**Features:**
- Primary: "Lanjutkan dengan Google" button
- Secondary: "Login dengan Email" (legacy users)
- System auto-detects role from database after login

**Auto-Redirect Logic:**
```javascript
const user = await getUserFromDB(googleEmail);

if (user.role === 'owner_business') {
  → Owner Dashboard
} else if (user.role === 'tenant') {
  if (user.sub_role === 'staff') {
    → Staff Dashboard
  } else if (user.tenant_id) {
    → Tenant Dashboard
  } else {
    → Code Entry Page (need to link tenant)
  }
}
```

---

### **2.3 Code Entry Page (Tenant/Staff)**

![Code Entry](C:/Users/Ryan/.gemini/antigravity/brain/dc1d1508-f9b4-4d2d-abec-c0bab0d47d13/tenant_code_entry_1765958614517.png)

**When Shown:**
- After Google login successful
- If user has `tenant_id = null`
- For Tenant and Staff only (not Owner)

**Flow:**
1. User logs in with Google ✅
2. System checks: `tenant_id` exists?
3. NO → Show code entry page
4. User enters code (TN-ABC123 or ST-XYZ789)
5. System validates and links to tenant
6. Redirect to dashboard

---

## 3. Technical Setup

### **3.1 Google Cloud Configuration** (Day 1-2)

#### **Step 1: Create Google Cloud Project**

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create new project: `kantin-app-production`

#### **Step 2: Configure OAuth Consent Screen**

1. Navigate: **APIs & Services** → **OAuth consent screen**
2. User Type: **External**
3. Fill required fields:
   - App name: `Kantin QR-Order`
   - User support email: (your email)
   - Developer contact: (your email)
4. Scopes: `email`, `profile`
5. Save

#### **Step 3: Create OAuth Credentials**

1. Navigate: **Credentials** → **Create Credentials** → **OAuth client ID**
2. Type: **Android**
3. Package name: `com.yourcompany.kantin_app` (from `build.gradle`)

#### **Step 4: Get SHA-1 Fingerprint**

**Debug:**
```bash
cd android
./gradlew signingReport
```

**Release:**
```bash
keytool -list -v -keystore upload-keystore.jks -alias upload
```

5. Add SHA-1 to Google Cloud
6. Save **Client ID**

---

### **3.2 Appwrite Configuration** (Day 2-3)

#### **Step 1: Enable Google OAuth**

1. [Appwrite Console](https://cloud.appwrite.io) → **Auth** → **OAuth2**
2. Find **Google** → Toggle **Enable**
3. App ID: (paste Client ID)
4. App Secret: (leave empty for mobile)

#### **Step 2: Get Callback URL**

Copy callback URL from Appwrite:
```
https://fra.cloud.appwrite.io/v1/account/sessions/oauth2/callback/google/[project-id]
```

#### **Step 3: Update Google Cloud Redirect URIs**

1. Back to Google Cloud → **Credentials**
2. Click OAuth client ID
3. Add **Authorized redirect URIs**: (Appwrite callback URL)
4. Save

---

### **3.3 Database Schema Updates**

#### **Add to `users` collection:**

| Field | Type | Size | Required | Default |
|-------|------|------|----------|---------|
| `auth_provider` | String | 50 | No | `"email"` |
| `google_id` | String | 255 | No | null |
| `subscription_tier` | String | 50 | No | `"free"` |
| `subscription_expires_at` | DateTime | - | No | null |
| `payment_status` | String | 50 | No | `"free"` |

**Create Index:**
- Field: `google_id`
- Type: Unique
- Order: ASC

#### **Create `invitation_codes` collection:**

```javascript
{
  "$id": "UUID",
  "code": "string",           // TN-XXXXXX or ST-XXXXXX
  "type": "tenant | staff",
  "created_by": "user_id",    // Who generated
  "tenant_id": "UUID",        // Which tenant to join
  "status": "active | used | expired",
  "expires_at": "DateTime",   // +5 hours from creation
  "used_by": "user_id | null",
  "used_at": "DateTime | null",
  "$createdAt": "DateTime"
}
```

**Indexes:**
- `code` (unique)
- `status` (key)
- `type` (key)

---

## 3.4 Understanding Account Creation (CRITICAL!)

### **❓ FAQ: Do I Need a Function to Create Users?**

**Answer: NO! ❌**

This is the **most important concept** to understand:

### **🔐 Two-Layer Account System**

```
┌─────────────────────────────────────┐
│  LAYER 1: AUTH (Appwrite Auth)      │
│  ✅ AUTO-CREATED by Google/Appwrite │
│                                     │
│  When: User clicks "Google Sign-In" │
│  Who: Google + Appwrite (automatic) │
│  Creates:                           │
│    - User ID: abc123                │
│    - Email: user@gmail.com          │
│    - Name: John Doe                 │
│    - Provider: google               │
│                                     │
│  ✅ NO CODE NEEDED FROM YOU!        │
└─────────────────────────────────────┘
         ↓
┌─────────────────────────────────────┐
│  LAYER 2: DATABASE (users collection)│
│  ❌ NOT AUTO - App creates it       │
│                                     │
│  When: After Google OAuth success   │
│  Who: Your Flutter app (client-side)│
│  Creates:                           │
│    - $id: abc123 (same as Auth)     │
│    - role: owner_business           │
│    - subscription_tier: free        │
│    - tenant_id: (if applicable)     │
│                                     │
│  ✅ CLIENT-SIDE CODE (no function!) │
└─────────────────────────────────────┘
```

---

### **💡 Why NO Function Needed?**

**OLD System (Manual Creation):**
```
Owner creates account for Tenant
    ↓
Problem: Owner CANNOT create Auth users for others
    ↓
Solution: Call function with API key
    ↓
Function (with admin privileges):
    - Creates Auth user for Tenant
    - Creates DB document for Tenant
    ↓
✅ Function NEEDED (permission requirement)
```

**NEW System (Self-Registration):**
```
Tenant clicks "Sign in with Google"
    ↓
Google auto-creates Auth user ✅
    ↓
Tenant IS NOW AUTHENTICATED
    ↓
App code (running as authenticated user):
    await databases.createDocument(...)
    ↓
✅ Client-side creates OWN document
✅ NO FUNCTION NEEDED!
```

---

### **🔑 Key Differences**

| Aspect | OLD (create-user function) | NEW (Google OAuth) |
|--------|---------------------------|-------------------|
| **Who creates?** | Owner creates for Tenant | User creates for SELF |
| **Permission needed?** | Admin (function API key) | User (authenticated) |
| **Auth creation** | Function creates | Google auto-creates |
| **DB creation** | Function creates | Client-side creates |
| **Function slots used** | 1 slot | 0 slots ✅ |
| **Complexity** | High (rollback logic) | Low (simple) |

---

### **⚙️ Required Database Permissions**

**Appwrite Console → Database → `users` collection → Settings → Permissions:**

```
Create: Users    ← Allows authenticated users to create documents
Read: Users      ← Allows users to read their own document
Update: Users    ← Allows users to update their own document
```

This permission configuration allows:
- ✅ User can create THEIR OWN DB document after Google OAuth
- ✅ User can read THEIR OWN document
- ✅ User can update THEIR OWN document

---

### **📝 Client-Side Implementation Example**

```dart
// auth_provider.dart
Future<void> handleGoogleSignIn() async {
  // Step 1: Google OAuth (AUTO-creates Auth user)
  final session = await account.createOAuth2Session(
    provider: 'google',
  );
  
  // Step 2: Get authenticated user info
  final googleUser = await account.get();
  
  // Step 3: Check if DB document exists
  try {
    final userDoc = await databases.getDocument(
      databaseId: 'kantin-db',
      collectionId: 'users',
      documentId: googleUser.$id,
    );
    
    // User exists in DB → Login
    print('✅ User exists, logging in');
    _navigateToDashboard(userDoc);
    
  } catch (e) {
    // User NOT in DB → Create document (CLIENT-SIDE!)
    print('🆕 New user, creating DB document');
    
    await databases.createDocument(
      databaseId: 'kantin-db',
      collectionId: 'users',
      documentId: googleUser.$id,  // Use Auth user ID
      data: {
        'user_id': googleUser.$id,
        'email': googleUser.email,
        'full_name': googleUser.name,
        'role': 'owner_business',  // Determined by registration flow
        'subscription_tier': 'free',
        'payment_status': 'free',
        'auth_provider': 'google',
        'google_id': googleUser.$id,
        'is_active': true,
      },
      permissions: [
        Permission.read(Role.user(googleUser.$id)),
        Permission.update(Role.user(googleUser.$id)),
      ],
    );
    
    print('✅ DB document created!');
  }
}
```

**Notice:** No function call! Direct `databases.createDocument()` from client.

---

### **🎯 Summary**

**Q: Apakah akun otomatis create di users collection dan AUTH?**

**A:**
- ✅ **AUTH**: YES, otomatis by Google/Appwrite
- ❌ **Database**: NO, manual by app (client-side code)
- ✅ **Function needed**: NO untuk create document, YES untuk set labels

**Key Takeaway:** Google handles Auth layer, your app handles Database layer (client-side create + function for labels).

---

### **⚠️ CRITICAL: Label Management for OAuth Users**

#### **The Label Problem:**

When user registers via Google OAuth:
- ✅ Auth account created automatically
- ❌ **Auth account has NO labels** (labels need admin privileges to set)
- ❌ Existing features rely on labels for permissions
- ❌ Cross-collection queries may fail without labels

#### **The Solution: Recycle `create-user` Function**

**Instead of creating a new function**, we can **recycle the existing `create-user` function** by adding an OAuth label-setting endpoint!

**Benefits:**
- ✅ Function already exists & deployed
- ✅ API key already configured
- ✅ Security checks already in place
- ✅ No new function deployment needed
- ✅ Backward compatible (existing manual creation still works)
- ✅ Minimal code changes (10-15 lines)

**Modified Function Code:**

```javascript
// File: functions/create-user/src/main.js
export default async ({ req, res, log, error }) => {
    const client = new Client()
        .setEndpoint(process.env.APPWRITE_FUNCTION_ENDPOINT)
        .setProject(process.env.APPWRITE_FUNCTION_PROJECT_ID)
        .setKey(process.env.APPWRITE_FUNCTION_API_KEY);

    const databases = new Databases(client);
    const users = new Users(client);
    
    // Parse body
    let body = typeof req.body === 'string' ? JSON.parse(req.body) : req.body;
    
    // ===== NEW: OAuth Labels Handler =====
    if (body.action === 'set_oauth_labels') {
        try {
            const { userId, role } = body;
            
            if (!userId || !role) {
                return res.json({ success: false, error: 'Missing userId or role' }, 400);
            }
            
            // Map role to label (match your existing labels in Appwrite)
            const labelMap = {
                'owner_business': 'ownerbusnis',  // Match screenshot
                'tenant': 'tenant',
                'staff': 'tenant'  // Staff also uses tenant label
            };
            
            const label = labelMap[role];
            if (!label) {
                return res.json({ success: false, error: `Invalid role: ${role}` }, 400);
            }
            
            // Set label in Auth account
            await users.updateLabels(userId, [label]);
            
            log(`✅ OAuth label set: '${label}' for user ${userId} (role: ${role})`);
            return res.json({ 
                success: true, 
                message: 'Label set successfully',
                data: { userId, label } 
            }, 200);
            
        } catch (err) {
            error(`OAuth labels error: ${err.message}`);
            return res.json({ success: false, error: err.message }, 500);
        }
    }
    // ===== End OAuth Handler =====
    
    // EXISTING CODE CONTINUES (line 38 onwards)
    // All existing create-user logic stays exactly the same...
    // (No changes to existing tenant/staff creation)
};
```

**Usage from Flutter:**

```dart
// After creating DB document for OAuth user
await functions.createExecution(
  functionId: 'create-user',
  body: jsonEncode({
    'action': 'set_oauth_labels',  // ← NEW action
    'userId': googleUser.$id,
    'role': 'owner_business',  // or 'tenant' or 'staff'
  }),
);
```

#### **Hybrid Permissions Strategy**

**Collection-Level Permissions (DON'T CHANGE!):**

Keep your existing permissions in Appwrite Console:
```
✅ Create: Users
✅ Read: Users + label:ownerbusnis + label:tenant + label:adminroyal
✅ Update: Users + label:ownerbusnis + label:tenant + label:adminroyal
✅ Delete: Any (or admin only)
```

**Document-Level Permissions (HYBRID):**

When creating documents, use **both** User + Label permissions:

```dart
permissions: [
  // User-specific (for self-access)
  Permission.read(Role.user(googleUser.$id)),
  Permission.update(Role.user(googleUser.$id)),
  
  // Label-based (for existing features & cross-access)
  Permission.read(Role.label('ownerbusnis')),
  Permission.update(Role.label('ownerbusnis')),
  Permission.read(Role.label('adminroyal')),  // Admin access
]
```

**Why This Works:**
- ✅ User can access their own document (via `Role.user()`)
- ✅ Existing features work (via `Role.label()` in collection)
- ✅ Auth labels set via function (for cross-collection queries)
- ✅ No need to refactor existing code!

---

## 4. Implementation Code

### **4.1 Google Auth Service**

**File:** `lib/core/services/google_auth_service.dart`

```dart
import 'package:google_sign_in/google_sign_in.dart';
import 'package:appwrite/appwrite.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final googleAuthServiceProvider = Provider((ref) {
  final account = ref.read(appwriteAccountProvider);
  return GoogleAuthService(account);
});

class GoogleAuthService {
  final Account _account;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );
  
  GoogleAuthService(this._account);
  
  /// Sign in with Google OAuth
  Future<Session?> signInWithGoogle() async {
    try {
      // 1. Trigger Google Sign-In picker
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        return null; // User cancelled
      }
      
      // 2. Get auth details
      final GoogleSignInAuthentication googleAuth = 
        await googleUser.authentication;
      
      // 3. Create Appwrite session
      final session = await _account.createOAuth2Session(
        provider: 'google',
      );
      
      return session;
    } catch (e) {
      print('Google Sign-In Error: $e');
      rethrow;
    }
  }
  
  /// Sign out
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _account.deleteSession(sessionId: 'current');
  }
}
```

---

### **4.2 Invitation Code Generator**

**File:** `lib/core/utils/invitation_code_generator.dart`

```dart
import 'dart:math';

class InvitationCodeGenerator {
  static String generate(InvitationType type) {
    final prefix = type == InvitationType.tenant ? 'TN' : 'ST';
    final random = Random().nextInt(900000) + 100000; // 6 digits
    return '$prefix-$random';  // TN-123456 or ST-789012
  }
  
  static bool validate(String code) {
    final regex = RegExp(r'^(TN|ST)-\d{6}$');
    return regex.hasMatch(code);
  }
  
  static InvitationType? getType(String code) {
    if (code.startsWith('TN-')) return InvitationType.tenant;
    if (code.startsWith('ST-')) return InvitationType.staff;
    return null;
  }
}

enum InvitationType { tenant, staff }
```

---

### **4.3 Owner Registration Flow**

```dart
// After Google OAuth success
Future<void> _handleOwnerRegistration() async {
  final googleUser = await account.get();
  
  // Check if user exists
  try {
    final existing = await databases.getDocument(
      databaseId: 'kantin-db',
      collectionId: 'users',
      documentId: googleUser.$id,
    );
    
    // User exists → Navigate to dashboard
    context.go('/owner-dashboard');
    
  } catch (e) {
    // User NOT exists → Create as Owner with FREE tier
    await databases.createDocument(
      databaseId: 'kantin-db',
      collectionId: 'users',
      documentId: googleUser.$id,
      data: {
        'user_id': googleUser.$id,
        'email': googleUser.email,
        'full_name': googleUser.name,
        'role': 'owner_business',
        'subscription_tier': 'free',       // FREE (not premium)
        'payment_status': 'free',          // FREE (not trial)
        'subscription_expires_at': null,   // No expiry
        'auth_provider': 'google',
        'google_id': googleUser.$id,
        'is_active': true,
      },
    );
    
    // Navigate to dashboard
    context.go('/owner-dashboard');
  }
}
```

---

### **4.4 Tenant Registration Flow**

```dart
// Step 1: Google OAuth (no code yet)
Future<void> _handleTenantRegistration() async {
  final googleUser = await account.get();
  
  // Check if user exists
  try {
    final userDoc = await databases.getDocument(
      databaseId: 'kantin-db',
      collectionId: 'users',
      documentId: googleUser.$id,
    );
    
    // User exists - check tenant_id
    if (userDoc.data['tenant_id'] != null) {
      // Already linked → Dashboard
      context.go('/tenant-dashboard');
    } else {
      // NO tenant_id → Need code
      context.go('/enter-tenant-code');
    }
    
  } catch (e) {
    // User NOT exists → Create partial user
    await databases.createDocument(
      databaseId: 'kantin-db',
      collectionId: 'users',
      documentId: googleUser.$id,
      data: {
        'user_id': googleUser.$id,
        'email': googleUser.email,
        'full_name': googleUser.name,
        'role': 'tenant',
        'tenant_id': null,       // NULL! Need code
        'auth_provider': 'google',
        'is_active': false,      // Inactive until code entered
      },
    );
    
    // Show code entry page
    context.go('/enter-tenant-code');
  }
}

// Step 2: Code Entry (after Google login)
Future<void> _submitTenantCode(String code) async {
  // Validate code
  final invitation = await databases.listDocuments(
    databaseId: 'kantin-db',
    collectionId: 'invitation_codes',
    queries: [
      Query.equal('code', code),
      Query.equal('status', 'active'),
      Query.equal('type', 'tenant'),
    ],
  );
  
  if (invitation.documents.isEmpty) {
    throw 'Kode tidak valid atau sudah digunakan';
  }
  
  final inv = invitation.documents.first;
  
  // Check expiry
  if (DateTime.parse(inv.data['expires_at']).isBefore(DateTime.now())) {
    throw 'Kode sudah kadaluarsa';
  }
  
  // Get current user
  final user = await account.get();
  
  // Update user with tenant_id
  await databases.updateDocument(
    databaseId: 'kantin-db',
    collectionId: 'users',
    documentId: user.$id,
    data: {
      'tenant_id': inv.data['tenant_id'],
      'is_active': true,  // Activate!
    },
  );
  
  // Mark code as used
  await databases.updateDocument(
    databaseId: 'kantin-db',
    collectionId: 'invitation_codes',
    documentId: inv.$id,
    data: {
      'status': 'used',
      'used_by': user.$id,
      'used_at': DateTime.now().toIso8601String(),
    },
  );
  
  // Success! Navigate to dashboard
  context.go('/tenant-dashboard');
}
```

---

### **4.5 Generate Invitation (Owner)**

**Replace:** `assign_user_dialog.dart`  
**With:** `generate_invitation_dialog.dart`

```dart
class GenerateInvitationDialog extends StatefulWidget {
  final String tenantId;
  final InvitationType type;
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Generate Kode Undangan'),
      content: Column(
        children: [
          Text('Pilih tenant untuk undangan:'),
          DropdownButton<String>(
            value: selectedTenantId,
            items: tenants.map((t) => DropdownMenuItem(
              value: t.id,
              child: Text(t.name),
            )).toList(),
            onChanged: (id) => setState(() => selectedTenantId = id),
          ),
          ElevatedButton(
            child: Text('Generate Kode'),
            onPressed: _generateCode,
          ),
        ],
      ),
    );
  }
  
  Future<void> _generateCode() async {
    final code = InvitationCodeGenerator.generate(InvitationType.tenant);
    
    await databases.createDocument(
      databaseId: 'kantin-db',
      collectionId: 'invitation_codes',
      documentId: ID.unique(),
      data: {
        'code': code,
        'type': 'tenant',
        'created_by': currentUser.$id,
        'tenant_id': selectedTenantId,
        'status': 'active',
        'expires_at': DateTime.now()
          .add(Duration(hours: 5))
          .toIso8601String(),
      },
    );
    
    // Show code to owner
    _showCodeDialog(code);
  }
  
  void _showCodeDialog(String code) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Kode Undangan Tenant'),
        content: Column([
          Text('Bagikan kode ini ke tenant:'),
          SizedBox(height: 16),
          SelectableText(
            code,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          SizedBox(height: 16),
          Text('Kode berlaku 5 jam', style: TextStyle(color: Colors.grey)),
          SizedBox(height: 24),
          ElevatedButton.icon(
            icon: Icon(Icons.copy),
            label: Text('Copy Kode'),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: code));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Kode disalin!')),
              );
            },
          ),
          ElevatedButton.icon(
            icon: Icon(Icons.share),
            label: Text('Share via WhatsApp'),
            onPressed: () => _shareViaWhatsApp(code),
          ),
        ]),
      ),
    );
  }
}
```

---

### **4.6 Error Handling UI**

**File:** `lib/features/tenant/presentation/pages/enter_tenant_code_page.dart`

Handle semua error cases dengan dialog yang user-friendly:

```dart
class EnterTenantCodePage extends StatefulWidget {
  final TextEditingController _codeController = TextEditingController();
  bool _isLoading = false;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Masukkan Kode Tenant')),
      body: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          children: [
            TextField(
              controller: _codeController,
              decoration: InputDecoration(
                labelText: 'Kode Undangan',
                hintText: 'TN-123456',
              ),
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _submitCode,
              child: _isLoading 
                ? CircularProgressIndicator()
                : Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }
  
  Future<void> _submitCode() async {
    setState(() => _isLoading = true);
    
    try {
      final code = _codeController.text.trim();
      
      // Validate format
      if (!InvitationCodeGenerator.validate(code)) {
        _showErrorDialog(
          title: '❌ Format Salah',
          message: 'Format kode harus: TN-XXXXXX\n(6 digit angka)',
        );
        return;
      }
      
      // Check code in database
      final invitation = await databases.listDocuments(
        databaseId: 'kantin-db',
        collectionId: 'invitation_codes',
        queries: [
          Query.equal('code', code),
          Query.equal('type', 'tenant'),
        ],
      );
      
      if (invitation.documents.isEmpty) {
        _showErrorDialog(
          title: '⚠️ Kode Tidak Valid',
          message: 'Kode tidak ditemukan.\nPastikan kode yang Anda masukkan benar.',
        );
        return;
      }
      
      final inv = invitation.documents.first;
      
      // Check if already used
      if (inv.data['status'] == 'used') {
        _showErrorDialog(
          title: '🔒 Kode Sudah Digunakan',
          message: 'Kode ini sudah digunakan oleh user lain.\n'
                   'Silakan minta kode baru dari Owner.',
        );
        return;
      }
      
      // Check expiry
      final expiryTime = DateTime.parse(inv.data['expires_at']);
      final now = DateTime.now();
      
      if (expiryTime.isBefore(now)) {
        final expired = now.difference(expiryTime);
        _showErrorDialog(
          title: '⏰ Kode Kadaluarsa',
          message: 'Kode sudah expired ${expired.inHours} jam yang lalu.\n\n'
                   'Kode undangan hanya berlaku 5 jam.\n'
                   'Silakan minta kode baru dari Owner.',
        );
        return;
      }
      
      // Success! Link user to tenant
      await _linkUserToTenant(inv);
      
    } catch (e) {
      _showErrorDialog(
        title: '⚠️ Terjadi Kesalahan',
        message: 'Error: ${e.toString()}',
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }
  
  void _showErrorDialog({
    required String title,
    required String message,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }
  
  Future<void> _linkUserToTenant(Document invitation) async {
    final user = await account.get();
    
    // Update user
    await databases.updateDocument(
      databaseId: 'kantin-db',
      collectionId: 'users',
      documentId: user.$id,
      data: {
        'tenant_id': invitation.data['tenant_id'],
        'is_active': true,
      },
    );
    
    // Mark code as used
    await databases.updateDocument(
      databaseId: 'kantin-db',
      collectionId: 'invitation_codes',
      documentId: invitation.$id,
      data: {
        'status': 'used',
        'used_by': user.$id,
        'used_at': DateTime.now().toIso8601String(),
      },
    );
    
    // Success! Navigate to dashboard
    context.go('/tenant-dashboard');
  }
}
```

**Error Types Handled:**

| Error | Title | Message |
|-------|-------|---------|
| **Invalid format** | ❌ Format Salah | Format kode harus: TN-XXXXXX |
| **Code not found** | ⚠️ Kode Tidak Valid | Kode tidak ditemukan |
| **Already used** | 🔒 Kode Sudah Digunakan | Kode sudah digunakan oleh user lain |
| **Expired** | ⏰ Kode Kadaluarsa | Kode expired X jam yang lalu |
| **Generic error** | ⚠️ Terjadi Kesalahan | Error: [detail] |

---

## 5. Implementation Phases

### **Phase 1: Modify Function** (Day 1) ⭐ **START HERE**

**Objective:** Add OAuth label-setting capability to existing `create-user` function

**Files to Edit:**
- [ ] `functions/create-user/src/main.js`

**Steps:**

1. **Open function file:**
   ```bash
   cd c:\PML_7-1\functions\create-user\src
   code main.js
   ```

2. **Add OAuth handler** (after line 51, before existing validation):
   - Locate "// ========== SECURITY: Validate Caller Role ==========" comment
   - Add new handler BEFORE this section
   - Copy code from section 3.4 above (OAuth Labels Handler)

3. **Test locally** (optional):
   ```bash
   cd functions/create-user
   npm install
   # Test with sample payload
   ```

4. **Deploy to Appwrite:**
   - Via Appwrite Console: Functions → create-user → Upload new code
   - OR via CLI: `appwrite deploy function`

5. **Verify deployment:**
   - Check function logs in Appwrite Console
   - Test with Thunder Client/Postman:
     ```json
     {
       "action": "set_oauth_labels",
       "userId": "test-user-id",
       "role": "owner_business"
     }
     ```

**Checklist:**
- [ ] Function code updated (10-15 lines added)
- [ ] Tested locally (optional)
- [ ] Deployed to Appwrite
- [ ] Verified via function logs
- [ ] Tested with API call

**⚠️ IMPORTANT:** Existing manual creation still works! This is just adding a new endpoint.

---

### **Phase 2: Flutter Core Implementation** (Day 2-4)

**Objective:** Implement Google OAuth flow and registration dialogs

**Files to Create:**

1. **Registration Dialog:**
   ```
   lib/features/auth/presentation/widgets/registration_required_dialog.dart
   ```

2. **Code Entry Pages:**
   ```
   lib/features/tenant/presentation/pages/enter_tenant_code_page.dart
   lib/features/staff/presentation/pages/enter_staff_code_page.dart
   ```

**Files to Modify:**

1. **Auth Provider:**
   ```
   lib/features/auth/providers/auth_provider.dart
   ```
   - Add: `handleGoogleSignIn()`
   - Add: `_showRegistrationRequiredDialog()`
   - Add: `_registerAsOwner()`
   - Add: `_registerAsTenant()`
   - Add: `_registerAsStaff()`
   - Add: `_navigateBasedOnRole()`

**Implementation Checklist:**

**Day 2: OAuth Flow:**
- [ ] Create `handleGoogleSignIn()` method
  - [ ] OAuth session creation
  - [ ] Check user exists in DB
  - [ ] Show dialog if not exists
  - [ ] Navigate if exists

- [ ] **⚠️ EDGE CASE: State Detection Logic**
  - [ ] Implement `_handleExistingUser()` method
  - [ ] Check document exists (404 = not registered)
  - [ ] Check `tenant_id` field (NULL = incomplete)
  - [ ] Detect user state from DATABASE (not LocalStorage!)
  - [ ] Handle 3 scenarios:
    - [ ] Document NOT exists → Show registration dialog
    - [ ] Document exists + tenant_id NULL → Code entry page
    - [ ] Document exists + tenant_id NOT NULL → Dashboard

**Day 3: Registration Methods:**
- [ ] Create registration dialog
  - [ ] Show account not registered message
  - [ ] 3 role buttons (Owner/Tenant/Staff)
  - [ ] Cancel button with logout
  - [ ] **⚠️ CRITICAL:** `barrierDismissible: false` (user MUST choose!)

- [ ] Implement `_registerAsOwner()`
  - [ ] Create DB document
  - [ ] Set hybrid permissions (User + Label)
  - [ ] Call function to set labels
  - [ ] Navigate to dashboard
  - [ ] Error handling

- [ ] Implement `_registerAsTenant()`
  - [ ] Create partial document (tenant_id = null)
  - [ ] Set is_active = false
  - [ ] Call function to set labels
  - [ ] Navigate to code entry page
  - [ ] Error handling

- [ ] Implement `_registerAsStaff()`
  - [ ] Create document with sub_role = 'staff'
  - [ ] Set is_active = false
  - [ ] Call function to set labels
  - [ ] Navigate to code entry page
  - [ ] Error handling

- [ ] **⚠️ EDGE CASE: Handle Cancel (Logout)**
  - [ ] Logout from Google OAuth session
  - [ ] Delete Auth session: `account.deleteSession('current')`
  - [ ] Navigate to home page
  - [ ] **Why?** Prevent stuck state (Auth exists but DB not)

**Day 4: Code Entry:**
- [ ] Create code entry pages
  - [ ] Input field for code
  - [ ] Validate format (TN-XXXXXX or ST-XXXXXX)
  - [ ] Submit button with loading state
  - [ ] Error dialogs (format, not found, used, expired)
  - [ ] Link to tenant on success
  - [ ] Navigate to correct dashboard

- [ ] **⚠️ EDGE CASE: Auto-check on page load**
  - [ ] `initState()`: Check if user already complete
  - [ ] If tenant_id NOT NULL → Auto redirect to dashboard
  - [ ] Prevent access to code entry if already registered
  - [ ] Add "Logout" option for users who want to cancel

**Testing:**
- [ ] Google login → Dialog appears for new user ✅
- [ ] Choose Owner → Document created + labels set + dashboard ✅
- [ ] Choose Tenant → Document created + code entry shown ✅
- [ ] Choose Staff → Document created + code entry shown ✅
- [ ] Cancel → Logout + return to home ✅

**Edge Cases Testing:**
- [ ] **Scenario 1:** User login tapi tidak pilih role → Close app
  - [ ] Login lagi → Dialog muncul LAGI ✅
  - [ ] Database still empty (document not created)
  
- [ ] **Scenario 2:** User pilih Tenant → Navigate to code entry → Close app
  - [ ] Login lagi → Skip dialog, langsung ke code entry ✅
  - [ ] Database has document with tenant_id = NULL
  
- [ ] **Scenario 3:** User pilih Tenant → Isi kode → Close app
  - [ ] Login lagi → Langsung ke dashboard ✅
  - [ ] Database has document with tenant_id = (filled)

- [ ] **Scenario 4:** User cancel registration (logout)
  - [ ] Auth session cleared ✅
  - [ ] Return to home page ✅
  - [ ] Next login shows dialog again ✅

---

### **📋 State Detection Reference**

**Detection Logic (Database-Driven):**

```dart
// Pseudo-code for state detection
if (document NOT exists) {
  // User belum pilih role
  → Show registration dialog
}
else if (role == 'owner_business') {
  // Owner complete (no tenant_id needed)
  → Navigate to owner dashboard
}
else if (role == 'tenant') {
  if (tenant_id == null) {
    // User pilih role tapi belum isi kode
    → Navigate to code entry page
  }
  else {
    // User complete
    → Navigate to tenant/staff dashboard
  }
}
```

**Key Points:**
- ✅ Database = Single source of truth
- ❌ NO LocalStorage needed
- ❌ NO required constraint on tenant_id
- ✅ Schema sudah correct: role (required), tenant_id (optional)



---

### **Phase 3: Invitation System** (Day 5-6)

**Objective:** Implement invitation code generation and validation

**Files to Create:**

1. **Code Generator Utility:**
   ```
   lib/core/utils/invitation_code_generator.dart
   ```

2. **Generate Invitation Dialog:**
   ```
   lib/features/business_owner/presentation/widgets/generate_invitation_dialog.dart
   lib/features/tenant/presentation/widgets/generate_staff_invitation_dialog.dart
   ```

**Implementation:**

**Day 5:**
- [ ] Create code generator utility
  - [ ] `generate(type)` → TN-XXXXXX or ST-XXXXXX
  - [ ] `validate(code)` → Check format
  - [ ] `getType(code)` → Extract type

- [ ] Create invitation dialog UI
  - [ ] Select tenant dropdown
  - [ ] Generate button
  - [ ] Display code (large, selectable)
  - [ ] Copy button
  - [ ] Share via WhatsApp button
  - [ ] Show expiry time (5 hours)

**Day 6:**
- [ ] Database operations
  - [ ] Create invitation_codes document
  - [ ] Set expiry (+5 hours)
  - [ ] Store tenant_id linkage
  - [ ] Handle errors

- [ ] Integration testing
  - [ ] Owner generates tenant code → TN-XXXXXX created ✅
  - [ ] Tenant generates staff code → ST-XXXXXX created ✅
  - [ ] Code stored in DB with correct expiry ✅
  - [ ] Copy button works ✅
  - [ ] Share button opens WhatsApp ✅

---

### **Phase 4: Error Handling & Edge Cases** (Day 7)

**Objective:** Robust error handling for all scenarios

**Error Scenarios to Handle:**

- [ ] **Invalid code format**
  - Dialog: "❌ Format Salah"
  - Message: "Format kode harus: TN-XXXXXX (6 digit angka)"
  - Action: User can retry

- [ ] **Code not found**
  - Dialog: "⚠️ Kode Tidak Valid"
  - Message: "Kode tidak ditemukan di sistem"
  - Action: User can retry or request new code

- [ ] **Code already used**
  - Dialog: "🔒 Kode Sudah Digunakan"
  - Message: "Kode ini sudah digunakan oleh user lain"
  - Action: Request new code from Owner

- [ ] **Code expired**
  - Dialog: "⏰ Kode Kadaluarsa"
  - Message: "Kode expired X jam yang lalu. Kode berlaku 5 jam."
  - Action: Request new code from Owner

- [ ] **Network errors**
  - Dialog: "⚠️ Koneksi Gagal"
  - Message: "Periksa koneksi internet Anda"
  - Action: Retry button

- [ ] **Google OAuth cancelled**
  - No error
  - Action: Return to login page

**Testing:**
- [ ] Each error type shows correct dialog ✅
- [ ] Dialogs are user-friendly (Indonesian) ✅
- [ ] Users can recover from errors ✅
- [ ] No crashes on edge cases ✅

---

### **Phase 5: Comprehensive Testing** (Day 8-9)

**Objective:** End-to-end validation of all flows including edge cases

**Test Scenarios:**

**New User Flows:**
- [ ] New Owner: Google → Choose Owner → Dashboard ✅
- [ ] New Tenant: Google → Choose Tenant → Code Entry → Dashboard ✅
- [ ] New Staff: Google → Choose Staff → Code Entry → Dashboard ✅

**Existing User Flows:**
- [ ] Existing user: Google login → Auto navigate to dashboard ✅
- [ ] Email/password users: Still can login ✅

**Invitation Flows:**
- [ ] Owner generates tenant code → Tenant uses it ✅
- [ ] Tenant generates staff code → Staff uses it ✅
- [ ] Code expires after 5 hours ✅
- [ ] Used code cannot be reused ✅

**Error Handling:**
- [ ] All error dialogs show correctly ✅
- [ ] Users can recover from errors ✅
- [ ] No crashes on invalid input ✅

**⚠️ Edge Cases Testing (CRITICAL!):**

1. **Incomplete Registration - User tidak pilih role:**
   - [ ] User: Login Google → Dialog appears
   - [ ] User: Force close app (tidak pilih apa-apa)
   - [ ] Check DB: Document NOT created
   - [ ] User: Login Google lagi
   - [ ] Expected: Dialog muncul LAGI ✅
   - [ ] Verify: User dapat retry berkali-kali

2. **Incomplete Registration - User pilih role tapi tidak isi kode:**
   - [ ] User: Login Google → Choose Tenant
   - [ ] App: Create document (tenant_id = null, is_active = false)
   - [ ] App: Navigate to code entry page
   - [ ] User: Close app (tidak isi kode)
   - [ ] Check DB: Document exists with tenant_id = NULL
   - [ ] User: Login Google lagi
   - [ ] Expected: Skip dialog → Langsung ke code entry ✅
   - [ ] Verify: Database state preserved

3. **Session State Detection:**
   - [ ] Test: Document exists + tenant_id NULL → Code entry
   - [ ] Test: Document exists + tenant_id filled → Dashboard
   - [ ] Test: Document NOT exists → Registration dialog
   - [ ] Verify: Detection dari DATABASE (not LocalStorage)

4. **Cancel/Logout Handling:**
   - [ ] User: Login Google → Dialog appears
   - [ ] User: Click "Batal"
   - [ ] Expected: Logout from OAuth ✅
   - [ ] Expected: Navigate to home ✅
   - [ ] Check: Auth session deleted
   - [ ] User: Login Google lagi
   - [ ] Expected: Dialog muncul lagi (fresh start) ✅

5. **Multiple Session Scenarios:**
   - [ ] Session 1: Login → Pilih Tenant → Close
   - [ ] Session 2: Login → Code entry page → Close
   - [ ] Session 3: Login → Code entry page → Fill code → Success ✅
   - [ ] Verify: State transitions correct at each step

6. **Database State Verification:**
   - [ ] Owner document: tenant_id can be NULL ✅
   - [ ] Tenant incomplete: tenant_id = NULL, is_active = false ✅
   - [ ] Tenant complete: tenant_id = (filled), is_active = true ✅
   - [ ] Staff incomplete: tenant_id = NULL, is_active = false, sub_role = 'staff' ✅
   - [ ] Staff complete: tenant_id = (filled), is_active = true ✅

**Existing Features (Regression Testing):**
- [ ] Owner can still create tenant manually (existing function) ✅
- [ ] Tenant can still create staff manually (existing function) ✅
- [ ] All CRUD operations work with labels ✅
- [ ] Permissions work correctly ✅
- [ ] Products/Orders/Categories work ✅

**Database Verification:**
- [ ] User documents have correct structure ✅
- [ ] Auth labels are set correctly ✅
- [ ] Document permissions are hybrid (User + Label) ✅
- [ ] tenant_id linking works ✅
- [ ] is_active flag updated correctly ✅
- [ ] role field always filled (required) ✅
- [ ] tenant_id field can be NULL (optional) ✅

**Performance Testing:**
- [ ] OAuth flow completes in <3 seconds ✅
- [ ] Function call for labels <2 seconds ✅
- [ ] Database queries optimized ✅
- [ ] No memory leaks on repeated login ✅



---

### **Phase 6: Optional - Gradual Deprecation** (Week 2+)

**⚠️ ONLY do this AFTER Phase 1-5 are complete and stable!**

**Monitor adoption first:**
- Track: How many users use Google OAuth vs manual
- Check: Any reported issues?
- Decide: Ready to deprecate manual creation?

**If ready to deprecate:**
- [ ] Update UI: Replace "Create User" with "Generate Invitation"
- [ ] Add migration notice for existing flows
- [ ] Keep email/password login active
- [ ] Keep `create-user` function (backward compatibility)

---

### **Timeline Summary**

| Week | Tasks | Status |
|------|-------|--------|
| **1-2** | Google Cloud + Appwrite setup | TO DO |
| **2-3** | Flutter integration (OAuth + Invitation) | TO DO |
| **3** | Beta testing with real users | TO DO |
| **4** | Remove old manual creation system | TO DO |

**Total: 4 weeks**

---

## 6. Testing Checklist

### **Pre-Release Testing**

**Google OAuth:**
- [ ] Owner registration → FREE tier created
- [ ] Tenant registration → Partial user created + code entry
- [ ] Staff registration → Partial user created + code entry
- [ ] Universal login → Auto-redirect based on role

**Invitation System:**
- [ ] Generate tenant code (TN-XXXXXX)
- [ ] Generate staff code (ST-XXXXXX)
- [ ] Code expiry (5 hours) works
- [ ] Code validation (format check)
- [ ] Code linking (update tenant_id)
- [ ] Used code rejected
- [ ] Expired code rejected

**Edge Cases:**
- [ ] User cancels Google picker (no crash)
- [ ] Invalid code format entered:
  - [ ] Show "❌ Format Salah" dialog
  - [ ] Dialog explains correct format (TN-XXXXXX)
  - [ ] User can close and retry
- [ ] Non-existent code entered:
  - [ ] Show "⚠️ Kode Tidak Valid" dialog
  - [ ] User can close and retry
- [ ] Expired code entered (>5 hours old):
  - [ ] Show "⏰ Kode Kadaluarsa" dialog
  - [ ] Dialog shows how long ago it expired
  - [ ] Dialog suggests requesting new code
- [ ] Already used code entered:
  - [ ] Show "🔒 Kode Sudah Digunakan" dialog
  - [ ] Dialog suggests requesting new code
- [ ] Existing email/password user can still login

---

## 🎯 Summary

### **Complete Architecture Flow**

```
┌───────────────────────────────────────────────────┐
│         GOOGLE OAUTH REGISTRATION FLOW            │
├───────────────────────────────────────────────────┤
│                                                   │
│  1. User: "Sign in with Google"                  │
│     ↓                                             │
│  2. Google: Create Auth account ✅                │
│     (No labels yet ❌)                             │
│     ↓                                             │
│  3. App: Check if user exists in DB               │
│     ├─ EXISTS → Navigate to dashboard             │
│     └─ NOT EXISTS → Show registration dialog      │
│         ↓                                         │
│  4. User: Choose role (Owner/Tenant/Staff)        │
│     ↓                                             │
│  5. App: Create DB document (client-side)         │
│     └─ Permissions: User + Label (hybrid)         │
│     ↓                                             │
│  6. App: Call create-user function                │
│     └─ Action: set_oauth_labels                   │
│         └─ Function: users.updateLabels()         │
│             └─ Auth account now has label ✅      │
│     ↓                                             │
│  7. Navigate:                                     │
│     ├─ Owner → Dashboard                          │
│     └─ Tenant/Staff → Code Entry Page             │
│         ↓                                         │
│  8. Enter invitation code (TN-XXXXXX/ST-XXXXXX)   │
│     ↓                                             │
│  9. Validate: format, expiry, status              │
│     ↓                                             │
│  10. Update: tenant_id + is_active = true         │
│      ↓                                            │
│  11. Mark code as used                            │
│      ↓                                            │
│  12. Navigate to Dashboard ✅                     │
│                                                   │
└───────────────────────────────────────────────────┘
```

---

### **Key Architectural Decisions**

| Decision Point | Chosen Approach | Rationale |
|----------------|-----------------|-----------|
| **Function Strategy** | ✅ Recycle `create-user` | Already deployed, API key configured, minimal changes (10-15 lines) |
| **Permission Model** | ✅ Hybrid (User + Label) | Backward compatible, existing features work without refactoring |
| **Document Creation** | ✅ Client-side | User authenticated, has permission, simpler architecture |
| **Label Setting** | ✅ Via function call | Requires admin privileges, unavoidable but minimal overhead |
| **Registration UX** | ✅ Dialog-based choice | User chooses role, self-service, clear and intuitive |
| **Invitation System** | ✅ Time-limited codes | Secure, controlled access, auto-expire in 5 hours |
| **Backward Compatibility** | ✅ Keep existing flows | Email/password login + manual creation still work |

---

### **Benefits Breakdown**

**For End Users:**
- ✅ **Owner:** Register with Google → FREE tier → Generate invitation codes
- ✅ **Tenant:** Get code → Register with Google → Auto-linked to tenant
- ✅ **Staff:** Get code → Register with Google → Auto-linked as staff
- ✅ **No password management** - Google handles authentication
- ✅ **Spam protection** - Google verification required
- ✅ **Self-service** - No waiting for manual account creation

**For Developers:**
- ✅ **Minimal changes** - Recycle existing function (10-15 lines)
- ✅ **No refactoring** - Hybrid permissions solve label compatibility
- ✅ **Backward compatible** - Existing features continue working
- ✅ **Reduced overhead** - Less manual account creation work
- ✅ **Clear separation** - OAuth handler vs manual creation logic

**Technical Advantages:**
- ✅ **Single function** - Dual-purpose (manual + OAuth labels)
- ✅ **Same API key** - No new infrastructure configuration
- ✅ **Hybrid permissions** - User-specific + Label-based access
- ✅ **Client-side creation** - Reduced server load for DB operations
- ✅ **Controlled access** - Time-limited invitation codes

---

### **What Changes vs What Stays**

#### **✨ NEW Features:**
1. Google OAuth integration
2. Registration dialog with role selection
3. Invitation code system (TN/ST codes)
4. Auto-linking via invitation codes
5. OAuth label-setting endpoint in `create-user`
6. Code entry pages with validation
7. Comprehensive error handling

#### **✅ UNCHANGED (Still Works):**
1. Email/password login
2. Manual account creation by Owner/Tenant
3. All existing CRUD operations
4. Collection-level permissions
5. Existing functions (delete-user, cleanup-expired-contracts)
6. All existing features relying on labels

---

### **Implementation Timeline**

| Phase | Duration | Key Deliverables |
|-------|----------|------------------|
| **Phase 1** | Day 1 | Function modified + deployed + tested |
| **Phase 2** | Day 2-4 | OAuth flow + registration dialogs + code entry |
| **Phase 3** | Day 5-6 | Invitation system + code generation |
| **Phase 4** | Day 7 | Error handling + edge cases |
| **Phase 5** | Day 8-9 | Comprehensive testing + validation |
| **TOTAL** | **9 days** | **Fully functional OAuth system** |

---

### **Trade-offs & Mitigations**

| Aspect | Trade-off | Mitigation |
|--------|-----------|------------|
| **Function calls** | +1 API call per OAuth registration | Async execution, acceptable overhead |
| **Code complexity** | Dual-purpose function | Clear separation with `action` parameter |
| **Migration effort** | Users need to adapt | Keep old flows active during transition |
| **Testing scope** | More scenarios to test | Comprehensive test plan in Phase 5 |
| **User education** | Need to explain new flow | Clear UI messages + documentation |

---

### **Success Criteria Checklist**

**Technical:**
- [ ] Function modified with OAuth endpoint ✅
- [ ] OAuth login works for new users ✅
- [ ] Auth labels set correctly ✅
- [ ] Hybrid permissions working ✅
- [ ] Invitation codes generated ✅
- [ ] Code validation robust ✅
- [ ] No breaking changes ✅

**User Experience:**
- [ ] Registration dialog intuitive ✅
- [ ] All 3 roles can register ✅
- [ ] Error messages clear (Indonesian) ✅
- [ ] Code entry straightforward ✅
- [ ] Auto-linking works ✅

**Quality:**
- [ ] All existing features work ✅
- [ ] No crashes on edge cases ✅
- [ ] Comprehensive error handling ✅
- [ ] Performance acceptable ✅
- [ ] Documentation updated ✅

---

### **Future Enhancements (Optional)**

After stable implementation, consider:

1. **Email verification flow** for extra security
2. **QR code generation** for invitation codes
3. **Batch invitation** for multiple users
4. **Analytics dashboard** for OAuth adoption
5. **Migration tool** for email/password users to link Google
6. **2FA integration** for sensitive operations

---

## 🚀 Getting Started

**Ready to implement? Follow these steps:**

### **Step 1: Day 1 - Modify Function** ⭐ **START HERE**

1. Open `c:\PML_7-1\functions\create-user\src\main.js`
2. Add OAuth label handler code (section 3.4)
3. Deploy to Appwrite
4. Test with API call
5. ✅ Verify it works!

### **Step 2: Day 2-4 - Flutter Implementation**

1. Create OAuth handler in auth provider
2. Build registration dialog
3. Implement registration methods for 3 roles
4. Create code entry pages
5. ✅ Test each flow!

### **Step 3: Day 5-6 - Invitation System**

1. Create code generator utility
2. Build invitation dialogs
3. Implement code validation
4. ✅ Test code lifecycle!

### **Step 4: Day 7 - Error Handling**

1. Add error dialogs for all scenarios
2. Handle edge cases
3. ✅ Test failure paths!

### **Step 5: Day 8-9 - Final Testing**

1. Run comprehensive test suite
2. Verify backward compatibility
3. Check database integrity
4. ✅ Ready for production!

---

## 📚 Quick Reference

**Files to Create:**
- `lib/features/auth/presentation/widgets/registration_required_dialog.dart`
- `lib/features/tenant/presentation/pages/enter_tenant_code_page.dart`
- `lib/features/staff/presentation/pages/enter_staff_code_page.dart`
- `lib/core/utils/invitation_code_generator.dart`
- `lib/features/business_owner/presentation/widgets/generate_invitation_dialog.dart`

**Files to Modify:**
- `functions/create-user/src/main.js` (add 10-15 lines)
- `lib/features/auth/providers/auth_provider.dart` (add methods)

**DON'T Change:**
- Collection-level permissions (keep as-is)
- Existing function logic (just add new endpoint)
- Email/password login flow
- Any existing features

---

**Got questions? Check section 3.4 for the label problem solution, or section 4.3-4.6 for detailed code examples!**

**Ready to start? Begin with Phase 1 - it takes just 10-15 minutes!** 🎯
