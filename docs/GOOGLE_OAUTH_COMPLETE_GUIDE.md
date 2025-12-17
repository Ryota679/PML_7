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
- ✅ **Function needed**: NO! User has permission to create own document

**Key Takeaway:** Google handles Auth layer, your app handles Database layer (no function needed!).

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

## 5. Migration Plan

### **Phase 1: Implement Google OAuth** (Week 1-2)

✅ **Keep existing system running**

**Add:**
- [ ] Google OAuth service
- [ ] Invitation code system
- [ ] New registration flows
- [ ] Code entry pages

**Test:**
- [ ] Owner registration with Google
- [ ] Tenant self-registration with code
- [ ] Staff self-registration with code
- [ ] Universal login

---

### **Phase 2: Deprecate Manual Creation** (Week 3-4)

❌ **Remove old features**

**Delete Files:**
```bash
# Remove create-user function
rm -rf functions/create-user/

# Remove manual creation UI
rm lib/features/business_owner/.../assign_user_dialog.dart
```

**Delete from Appwrite:**
- [ ] Delete `create-user` function from Functions console

**Update UI:**
- [ ] Remove "Create Tenant" button → Replace with "Generate Invitation"
- [ ] Remove "Create Staff" button → Replace with "Generate Invitation"

**Keep:**
- ✅ Email/password login (for existing users)
- ✅ `delete-user` function (still needed)
- ✅ `cleanup-expired-contracts` function (still needed)

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
- [ ] Invalid code entered (show error)
- [ ] Expired code entered (show error)
- [ ] Existing email/password user can still login

---

## 🎯 Summary

**New System Benefits:**

✅ **Owner:** Register with Google → FREE tier → Generate invitation codes  
✅ **Tenant:** Enter code → Login with Google → Auto-linked to tenant  
✅ **Staff:** Enter code → Login with Google → Auto-linked as staff  
✅ **Login:** 1 universal page → Auto-detect role → Redirect to dashboard

**Removed Complexity:**

❌ Manual account creation (Owner creating Tenant/Staff accounts)  
❌ Password management  
❌ `create-user` function  
❌ Multiple login pages

**Implementation:**
- **Setup:** 2-3 days (Google Cloud + Appwrite)
- **Development:** 7-10 days (Flutter integration)
- **Testing:** 3-5 days (Beta + fixes)
- **Total:** ~3-4 weeks

---

**Ready to start?** Begin with Day 1: Google Cloud setup! 🚀
