# Premium Self-Upgrade Logic for Deactivated Tenants

## Overview
This document explains how tenant users can self-upgrade to premium when their account is deactivated by the business owner due to free tier limits.

## User Flow

### Scenario: Tenant User Deactivated (Free Tier Limit)

When a Business Owner has more than 2 tenants and hasn't selected which 2 to keep active on the free tier:
1. The 3rd+ tenant users get deactivated (`is_active = false`)
2. When they try to login, they see a **Deactivated User Dialog**
3. The dialog shows:
   - ❌ Account deactivated message
   - 📧 Business Owner contact info (via WhatsApp/Email buttons)
   - 🔄 **Logout button** - Returns to guest page  
   - 🎯 **Upgrade Premium button** - Self-upgrade option

### Self-Upgrade Flow

```
Tenant Login (Deactivated) 
  → Dialog Shows
    → Option 1: Contact Business Owner (WhatsApp/Email)
    → Option 2: Self-Upgrade to Premium
      → Navigate to Payment Page
      → Complete Payment
      → Account Reactivated (Premium)
      → CANNOT be deactivated by Business Owner anymore
```

## Database Logic

### Current Fields in `users` Collection
- `is_active`: Boolean - Whether user can access the app
- `subscriptionTier`: String - "free" | "premium"
- `paymentStatus`: String - "active" | "trial" | "premium"

### Proposed New Field
Add `premium_source` field to track who pays for premium:

```dart
// In UserModel
final String? premiumSource; // "business_owner" | "self_paid" | null
```

### Logic Rules

#### 1. **Self-Paid Premium Protection**
```dart
// When deactivating tenant users, check premium source
if (user.premiumSource == 'self_paid') {
  // SKIP - Cannot deactivate self-paid premium users
  continue;
}

// Only deactivate free tier users
if (user.subscriptionTier == 'free') {
  user.isActive = false; // Deactivate
}
```

#### 2. **Active Tenant Count Calculation**
```dart
// Count active tenants for Business Owner
int getActiveTenantCount(String businessOwnerId) {
  final allTenants = getTenantsByOwnerId(businessOwnerId);
  
  // Count ONLY free-tier active tenants
  final freeTierActive = allTenants.where((t) => 
    t.isActive && 
    t.subscriptionTier == 'free'
  ).length;
  
  return freeTierActive; // This will be max 2 on free tier
}

// Example:
// BO has 5 tenants total:
// - Tenant A: Free, Active (counted = 1)
// - Tenant B: Free, Active (counted = 2)  
// - Tenant C: Free, Deactivated (counted = 0)
// - Tenant D: Self-Paid Premium, Active (counted = 0 - doesn't count toward limit!)
// - Tenant E: BO-Paid Premium, Active (counted = 0 - doesn't count either)
// Result: 2/2 free tenants active ✅ No error!
```

#### 3. **Upgrade Process**
```dart
Future<void> selfUpgradeTenant(String userId, String paymentProof) async {
  // 1. Verify payment (via payment gateway)
  final paymentVerified = await verifyPayment(paymentProof);
  
  if (paymentVerified) {
    // 2. Update user to premium
    await updateUser(userId, {
      'subscriptionTier': 'premium',
      'paymentStatus': 'active',
      'premiumSource': 'self_paid', // KEY: Mark as self-paid
      'is_active': true, // Reactivate user
      'subscriptionStartedAt': DateTime.now().toIso8601String(),
      'subscriptionExpiresAt': DateTime.now().add(Duration(days: 365)).toIso8601String(),
    });
    
    print('✅ Tenant self-upgraded to premium - protected from deactivation');
  }
}
```

## UI/UX Considerations

### Dialog Display Logic
```dart
// In login_page.dart
if (user.role == 'tenant' && user.subRole == null) {
  // Tenant User (not staff)
  showDialog(
    DeactivatedUserDialog(
      userRole: 'tenant_user',
      ownerName: businessOwner.fullName,
      ownerEmail: businessOwner.email,
      ownerPhone: businessOwner.phone,
      onLogout: () => context.go('/guest'),
      onUpgrade: () => context.go('/payment/tenant-upgrade'), // Show upgrade button
    ),
  );
} else if (user.subRole == 'staff') {
  // Staff member - NO upgrade option
  showDialog(
    DeactivatedUserDialog(
      userRole: 'staff',
      ownerName: tenantOwner.name,
      ownerEmail: tenantOwner.email,
      ownerPhone: tenantOwner.phone,
      onLogout: () => context.go('/guest'),
      onUpgrade: null, // Staff cannot self-upgrade
    ),
  );
}
```

### Payment Page (To Be Implemented)
Create `/features/tenant/presentation/pages/tenant_payment_page.dart`:
- Show pricing (e.g., Rp 99.000/bulan)
- Payment gateway integration (Midtrans/Xendit)
- Success confirmation
- Auto-redirect to tenant dashboard after success

## Benefits

### For Tenants
- ✅ **Instant Reactivation** - No waiting for business owner response
- ✅ **Full Control** - Independent from business owner's decisions
- ✅ **Protected Status** - Cannot be deactivated once premium

### For Business Owners
- ✅ **No Impact on Free Tier Limits** - Self-paid tenants don't count
- ✅ **Revenue for Platform** - More premium subscriptions
- ✅ **Simplified Management** - Less tenant complaints about deactivation

### For Platform
- ✅ **Additional Revenue Stream** - Tenants paying directly
- ✅ **Better User Retention** - Users can stay active
- ✅ **Scalable Model** - Supports unlimited premium tenants per BO

## Implementation Checklist

- [x] Update `DeactivatedUserDialog` to show upgrade button for tenant users
- [x] Fix navigation flow (logout and upgrade buttons)
- [x] Remove contact info box for cleaner UI
- [ ] Add `premium_source` field to `users` collection schema
- [ ] Update `UserModel` with `premiumSource` field
- [ ] Create tenant payment page UI
- [ ] Integrate payment gateway (Midtrans/Xendit)
- [ ] Update active tenant count logic to exclude self-paid premium
- [ ] Add protection logic to prevent deactivating self-paid premium users
- [ ] Add webhook handler for payment verification
- [ ] Add payment success confirmation page
- [ ] Write tests for premium upgrade flow

## Migration Notes

For existing data:
```javascript
// Appwrite migration script
// Set all existing premium tenants to business_owner paid
db.collection('users')
  .find({ subscriptionTier: 'premium', role: 'tenant' })
  .forEach(user => {
    db.collection('users').updateOne(
      { _id: user._id },
      { $set: { premium_source: 'business_owner' } }
    );
  });
```

## Future Enhancements

1. **Promo Codes** - Allow discount codes for first-time upgraders
2. **Trial Period** - Offer 7-day free trial for self-upgrade
3. **Family Plan** - Allow business owner to add premium to multiple tenants at discount
4. **Auto-Renewal** - Automatic renewal with saved payment method
5. **Downgrade Option** - Allow premium users to downgrade (with data limits applied)
