# Database Schema Migration - Freemium Model

**Date:** 10 December 2025  
**Purpose:** Implement tiered freemium model with tenant selection  
**Status:** In Progress  

---

## 📋 Migration Steps

### Step 1: Add New Fields to `users` Collection

**Collection:** `users`  
**Database:** kantin-db  

#### New Fields to Add:

| Field Name | Type | Required | Default | Description |
|------------|------|----------|---------|-------------|
| `selected_tenant_ids` | Array of Strings | No | `[]` | Array of 2 tenant IDs selected by BO |
| `selection_submitted_at` | DateTime | No | `null` | When user submitted tenant selection |
| `swap_used` | Boolean | No | `false` | Whether 1x swap has been used |
| `selected_staff_per_tenant` | JSON Object | No | `{}` | Map of tenant_id to array of staff user IDs |

#### Appwrite Console Steps:

1. Navigate to: **Databases** → **kantin-db** → **users** → **Columns** tab
2. Click **"+ Create column"** for each field:

**Field 1: selected_tenant_ids**
```
Column name: selected_tenant_ids
Type: String[] (Array)
Size: 255 (per item)
Required: No
Default: [] (empty array)
Array: Yes
```

**Field 2: selection_submitted_at**
```
Column name: selection_submitted_at
Type: DateTime
Required: No
Default: null
```

**Field 3: swap_used**
```
Column name: swap_used
Type: Boolean
Required: No
Default: false
```

**Field 4: selected_staff_per_tenant**
```
Column name: selected_staff_per_tenant
Type: String (JSON)
Size: 5000
Required: No
Default: {}
```

---

### Step 2: Remove Deprecated Fields (Optional Cleanup)

**⚠️ CAUTION:** Only proceed if these fields are no longer used in code.

Fields to remove:
- ❌ `free_tier_grace_started_at`
- ❌ `free_tier_users_chosen`
- ❌ `swap_available_until`

**Recommended:** Leave these fields for now, remove after full migration verified.

---

### Step 3: Create Index

**Index Name:** `idx_selected_tenants`  
**Collection:** `users`  
**Field:** `selected_tenant_ids`  
**Type:** Fulltext (for array search)

#### Appwrite Console Steps:

1. Navigate to: **Databases** → **kantin-db** → **users** → **Indexes** tab
2. Click **"+ Create index"**
3. Fill in:
```
Index key: idx_selected_tenants
Type: Key (not fulltext, use Key for array)
Attributes: selected_tenant_ids
Order: ASC
```

---

### Step 4: Update UserModel (Flutter Code)

**File:** `lib/shared/models/user_model.dart`

Add new fields to UserModel class - this will be done in code changes.

---

## 🧪 Verification

After migration, verify:

```dart
// Test query with new fields
final user = await databases.getDocument(
  databaseId: 'kantin-db',
  collectionId: 'users',
  documentId: 'test-user-id',
);

print('Selected tenants: ${user.data['selected_tenant_ids']}');
print('Selection submitted: ${user.data['selection_submitted_at']}');
print('Swap used: ${user.data['swap_used']}');
print('Staff per tenant: ${user.data['selected_staff_per_tenant']}');
```

---

## 📊 Data Format Examples

### selected_tenant_ids
```json
[
  "tenant_id_1",
  "tenant_id_2"
]
```

### selected_staff_per_tenant
```json
{
  "tenant_id_1": ["staff_user_id_1", "staff_user_id_2"],
  "tenant_id_2": ["staff_user_id_1"],
  "tenant_id_3": ["staff_user_id_1"]
}
```

### selection_submitted_at
```
2025-12-10T12:00:00.000Z
```

---

## ✅ Migration Checklist

- [ ] **Step 1:** Add `selected_tenant_ids` field
- [ ] **Step 1:** Add `selection_submitted_at` field
- [ ] **Step 1:** Add `swap_used` field
- [ ] **Step 1:** Add `selected_staff_per_tenant` field
- [ ] **Step 3:** Create `idx_selected_tenants` index
- [ ] **Step 4:** Update UserModel in code
- [ ] **Verify:** Test read/write with new fields
- [ ] **Cleanup:** (Later) Remove deprecated fields

---

**Next Steps:** After database migration, proceed to update `subscription_constants.dart`
