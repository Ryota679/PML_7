# Inactive Tenant Guard Implementation

## Overview

The inactive tenant guard prevents free-tier business owners from accessing tenants they haven't selected as active.

## Implementation Status

### ✅ Completed

1. **Inactive Tenant Page** (`inactive_tenant_page.dart`)
   - Lock icon with clear messaging
   - Two action options:
     - Swap tenant selection
     - Upgrade to premium
   - Back navigation to dashboard

2. **Tenant Access Guard** (`tenant_access_guard.dart`)
   - Logic to check if user can access tenant
   - Supports:
     - Premium users (unlimited access)
     - Trial users (unlimited access)
     - Free tier with selected tenants
     - Grace period (temporary access before swap deadline)
   - Helper methods for warnings and denial reasons

3. **Router Integration**
   - Added `/inactive-tenant` route
   - Import for `InactiveTenantPage`

### 📝 Usage Pattern

The guard is designed to be used in **business owner context** when managing multiple tenants, not in tenant user context.

#### Scenario 1: Business Owner with Free Tier

**Context**: Business owner has 5 tenants, selected 2 for free tier

**Flow**:
1. Owner tries to view/edit tenant #3 (not selected)
2. Check: `TenantAccessGuard.canAccessTenant(user, tenant)`
3. If false → Navigate to `/inactive-tenant`
4. User sees options to swap or upgrade

**Implementation Location**: Business Owner tenant management pages
- `tenant_management_page.dart` - When viewing tenant details
- `tenant_user_management_page.dart` - When managing tenant users
- Any page that shows/edits specific tenant data

#### Scenario 2: Tenant User Login

**Context**: User with role `tenant`, assigned to specific tenant

**Flow**:
1. User logs in → Redirected to `/tenant`
2. Tenant dashboard loads user's assigned tenant
3. **No guard needed** - Tenant users only see their own tenant

**Why**: Tenant users don't have multiple tenants to access. The `tenantId` field in their user document determines their only tenant.

---

## Integration Points

### 1. Business Owner Tenant Management

**File**: `lib/features/business_owner/presentation/tenant_management_page.dart`

**Where to add guard**:
```dart
// When clicking on tenant card to view details
onTap: () {
  final canAccess = TenantAccessGuard.canAccessTenant(
    user: currentUser,
    tenant: tenant,
  );
  
  if (!canAccess) {
    context.go('/inactive-tenant');
    return;
  }
  
  // Navigate to tenant details/edit page
}
```

### 2. Business Owner User Management

**File**: `lib/features/business_owner/presentation/tenant_user_management_page.dart`

**Where to add guard**:
```dart
// When filtering/viewing users for a specific tenant
if (selectedTenantId != null) {
  final tenant = tenants.firstWhere((t) => t.id == selectedTenantId);
  
  final canAccess = TenantAccessGuard.canAccessTenant(
    user: currentUser,
    tenant: tenant,
  );
  
  if (!canAccess) {
    // Show warning or disable selection
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Tenant ini tidak aktif pada paket gratis Anda'),
        action: SnackBarAction(
          label: 'Lihat Detail',
          onPressed: () => context.go('/inactive-tenant'),
        ),
      ),
    );
    return;
  }
}
```

### 3. Tenant Selection Page

**File**: `lib/features/business_owner/presentation/pages/tenant_selection_page.dart`

**Current Status**: ✅ Already handles selection logic

**No guard needed**: This page is specifically for selecting/swapping tenants, so all tenants must be visible.

---

## Testing Checklist

### Test Case 1: Premium User
- [ ] Premium user can access all tenants
- [ ] No "Inactive Tenant" page shown

### Test Case 2: Trial User
- [ ] Trial user can access all tenants during trial period
- [ ] After trial expires → Grace period begins
- [ ] After grace period → Only selected 2 tenants accessible

### Test Case 3: Free User (Manual Selection)
- [ ] User with manual selection can only access 2 selected tenants
- [ ] Attempting to access non-selected tenant → Redirect to inactive page
- [ ] Inactive page shows "Tukar Tenant" button
- [ ] Inactive page shows "Upgrade" button

### Test Case 4: Free User (Grace Period)
- [ ] User in grace period can access all tenants (temporary)
- [ ] Banner shows "X days remaining to swap"
- [ ] After grace period ends → Only selected tenants accessible

### Test Case 5: Tenant Role User
- [ ] Tenant user (non-owner) can access their assigned tenant
- [ ] Tenant dashboard loads without guard check
- [ ] No inactive page shown to tenant users

---

## Future Enhancements

1. **Soft Lock** (Phase 2):
   - Show tenant data in read-only mode
   - Add "Unlock with Premium" button on each field
   - Better user experience than complete block

2. **Tenant Preview** (Phase 2):
   - Allow viewing tenant stats without editing
   - Show "Upgrade to Edit" message
   - Helps users decide which tenants to select

3. **Auto-Redirect** (Phase 2):
   - If user tries to access inactive tenant multiple times
   - Auto-show tenant selection page
   - Streamline the swap process

---

## Implementation Priority

**Current Sprint**: ✅ Core guard logic complete

**Recommended Next Steps**:
1. Add guard check to `tenant_management_page.dart` ← **HIGH PRIORITY**
2. Add guard check to `tenant_user_management_page.dart` ← **MEDIUM PRIORITY**
3. Test all scenarios ← **HIGH PRIORITY**
4. Optional: Add soft lock UI ← **LOW PRIORITY (Future)**

---

## Notes

- **Guard is CLIENT-SIDE only**: The guard prevents UI access but database permissions should also restrict updates to non-selected tenants.
- **Database-level protection**: `TenantSwapService` verifies tenant ownership before updates.
- **Grace period is forgiving**: Users can still access all tenants during grace period to help them decide which 2 to keep.
- **Tenant users unaffected**: The freemium limits only apply to business owners, not to tenant role users.

---

**Status**: ✅ **Foundation Complete, Integration Pending**

The guard system is built and ready to use. It needs to be integrated into the business owner tenant management flows for full protection.

**Estimated Integration Time**: 30-45 minutes

---

**Last Updated**: 9 December 2025  
**Files Created**: 3 (inactive_tenant_page.dart, tenant_access_guard.dart, router route)  
**Files Modified**: 1 (app_router.dart)
