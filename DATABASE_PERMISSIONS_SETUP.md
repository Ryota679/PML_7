# Database Permissions Setup for Freemium Tenant Selection

> **⚠️ IMPORTANT**: This manual setup is required for the tenant swap feature to work properly.

## Overview

The freemium tier system requires Business Owners to update specific fields in the `tenants` and `users` collections. This document outlines the required permission changes.

---

## Required Permission Updates

### 1. **Tenants Collection**

**Collection ID**: `tenants`

**Fields that need write access for Business Owners:**
- `selected_for_free_tier` (boolean)

**Current Permissions**: ✅ Already set to `Any` + `Users`

**Action Required**: ✅ **No changes needed** - Business Owners can already update tenant fields.

---

### 2. **Users Collection**

**Collection ID**: `users`

**Fields that need write access for Business Owners:**
- `manual_tenant_selection` (boolean)
- `swap_used` (boolean)
- `swap_available_until` (datetime)

**Current Permissions**: `Any` (Read) + `Users` (CRUD)

**Action Required**: ✅ **No changes needed** - Users can update their own documents.

---

## Verification Steps

### Step 1: Verify Tenants Collection Permissions

1. Open **Appwrite Console** → **Databases** → `kantin-db` → **Collections** → `tenants`
2. Click **Settings** tab → **Permissions**
3. Verify the following permissions exist:
   ```
   Read:   Any
   Create: Users
   Update: Users  ✅ (Required for selected_for_free_tier)
   Delete: Users
   ```

### Step 2: Verify Users Collection Permissions

1. Open **Appwrite Console** → **Databases** → `kantin-db` → **Collections** → `users`
2. Click **Settings** tab → **Permissions**
3. Verify the following permissions exist:
   ```
   Read:   Any
   Update: Users  ✅ (Required for manual_tenant_selection, swap_used, swap_available_until)
   ```

---

## Field Verification

### Tenants Collection - Required Field

Ensure this field exists in the `tenants` collection:

| Field Name              | Type    | Required | Default | Size |
|------------------------|---------|----------|---------|------|
| `selected_for_free_tier` | Boolean | No       | false   | -    |

### Users Collection - Required Fields

Ensure these fields exist in the `users` collection:

| Field Name                | Type     | Required | Default | Size |
|--------------------------|----------|----------|---------|------|
| `manual_tenant_selection` | Boolean  | No       | false   | -    |
| `swap_used`               | Boolean  | No       | false   | -    |
| `swap_available_until`    | DateTime | No       | null    | -    |

---

## Testing Permissions

### Test 1: Update Tenant Selection

```dart
// Test in Business Owner Dashboard
// Login as business owner with multiple tenants
// Click "Test: Pilih Tenant" menu
// Select 2 tenants
// Click "Simpan Pilihan"
// Expected: Success message, no permission errors
```

### Test 2: Use Swap Opportunity

```dart
// Prerequisite: User must have swap_available_until in future
// Login as business owner
// Click "Tukar Tenant" button in swap banner
// Select different 2 tenants
// Click "Gunakan Kesempatan Swap"
// Expected: Success, swap_used = true
```

### Test 3: Verify Database Updates

1. After test 1, check `tenants` collection:
   - 2 selected tenants should have `selected_for_free_tier = true`
   - Other tenants should have `selected_for_free_tier = false`

2. After test 1, check `users` collection:
   - User should have `manual_tenant_selection = true`

3. After test 2, check `users` collection:
   - User should have `swap_used = true`

---

## Troubleshooting

### Error: "Unauthorized to update document"

**Cause**: Permission configuration issue.

**Solution**:
1. Verify user is authenticated
2. Check that `Users` role has `Update` permission on the collection
3. Ensure user is updating their own document (not another user's)

### Error: "Attribute not found"

**Cause**: Required field doesn't exist in collection.

**Solution**:
1. Go to Appwrite Console → Database → Collection
2. Click **Attributes** tab
3. Add missing attribute (see "Field Verification" section above)

---

## Security Notes

### Document-Level Authorization

The app implements document-level authorization:

1. **Tenants Collection**:
   - Users can only update tenants they own (`owner_id` matches `user.userId`)
   - Checked in `TenantSwapService.saveSelection()` and `useSwapOpportunity()`

2. **Users Collection**:
   - Users can only update their own user document
   - Checked via Appwrite's built-in permission system

### Field-Level Protection

**Protected by app logic:**
- `selected_for_free_tier`: Only updated via `TenantSwapService`
- `manual_tenant_selection`: Only set to `true` after valid selection
- `swap_used`: Only set to `true` once, cannot be reset
- `swap_available_until`: Set by cleanup function, not user-modifiable

---

## Completion Checklist

- [ ] Verified `tenants` collection has `Users` update permission
- [ ] Verified `users` collection has `Users` update permission
- [ ] Verified `selected_for_free_tier` field exists in `tenants`
- [ ] Verified `manual_tenant_selection` field exists in `users`
- [ ] Verified `swap_used` field exists in `users`
- [ ] Verified `swap_available_until` field exists in `users`
- [ ] Tested tenant selection flow (no errors)
- [ ] Tested swap opportunity flow (no errors)
- [ ] Verified database updates correctly

---

## Summary

**Estimated Time**: 5-10 minutes

**Status**: ✅ **Permissions likely already configured correctly**

The current permission setup (`Any` + `Users`) should already allow Business Owners to update the required fields. This document serves as verification and troubleshooting reference.

**Next Steps**:
1. Test tenant selection in running app
2. If permission errors occur, follow troubleshooting steps
3. Proceed to Task 3: Inactive Tenant Guard

---

**Last Updated**: 9 December 2025  
**Configuration**: Appwrite Cloud (fra.cloud.appwrite.io)  
**Database**: kantin-db
