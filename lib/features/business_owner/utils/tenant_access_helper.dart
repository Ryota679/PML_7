import 'package:kantin_app/shared/models/user_model.dart';
import 'package:kantin_app/shared/models/tenant_model.dart';

/// Tenant Access Helper
/// 
/// Determines access level for tenants based on:
/// - Business Owner subscription tier (free/premium)
/// - Tenant selection status (selected_for_free_tier)
/// - Tenant's individual subscription (subscription_tier)
class TenantAccessHelper {
  
  /// Check if business owner has full access to this tenant
  /// 
  /// Returns true if:
  /// - Business Owner is premium (unlimited access)
  /// - Business Owner is free + tenant is selected
  /// - Tenant has individual premium subscription
  static bool hasFullAccess({
    required UserModel businessOwner,
    required TenantModel tenant,
  }) {
    // Case 1: BO is premium = always full access
    if (businessOwner.isPremium) return true;
    
    // Case 2: BO is free/trial + tenant is selected = full access
    if ((businessOwner.isFree || businessOwner.isTrialActive) && 
        tenant.selectedForFreeTier == true) {
      return true;
    }
    
    // Case 3: Tenant has individual premium subscription
    if (tenant.hasPremiumSubscription) {
      return true;
    }
    
    // Case 4: Limited access (BO is free + tenant not selected + no tenant premium)
    return false;
  }
  
  /// Check if business owner can edit this tenant
  static bool canEditTenant({
    required UserModel businessOwner,
    required TenantModel tenant,
  }) {
    return hasFullAccess(businessOwner: businessOwner, tenant: tenant);
  }
  
  /// Check if business owner can assign staff to this tenant
  /// 
  /// Returns true if has full access OR tenant has < max staff limit
  static bool canAssignStaff({
    required UserModel businessOwner,
    required TenantModel tenant,
    required int currentStaffCount,
  }) {
    // Full access = unlimited staff
    if (hasFullAccess(businessOwner: businessOwner, tenant: tenant)) {
      return true;
    }
    
    // Limited access = max 1 staff
    final maxStaff = getMaxStaffCount(businessOwner: businessOwner, tenant: tenant);
    return currentStaffCount < maxStaff;
  }
  
  /// Get maximum staff count for this tenant
  static int getMaxStaffCount({
    required UserModel businessOwner,
    required TenantModel tenant,
  }) {
    // Full access = unlimited (return high number)
    if (hasFullAccess(businessOwner: businessOwner, tenant: tenant)) {
      return 999;
    }
    
    // Limited access = max 1 staff
    return 1;
  }
  
  /// Get user-friendly denial reason
  static String getAccessDenialReason({
    required UserModel businessOwner,
    required TenantModel tenant,
  }) {
    if (businessOwner.isPremium) {
      return 'Akses penuh tersedia.';
    }
    
    if (tenant.selectedForFreeTier == true) {
      return 'Akses penuh tersedia.';
    }
    
    if (tenant.hasPremiumSubscription) {
      return 'Akses penuh tersedia (Tenant Premium).';
    }
    
    // Limited access
    return 'Tenant ini tidak termasuk 2 tenant aktif Anda (free tier). '
           'Upgrade untuk mengelola tenant ini.';
  }
  
  /// Check if business owner can upgrade (has swap available or can buy premium)
  static bool canUpgrade({
    required UserModel businessOwner,
  }) {
    // Grace period swap removed - always false
    final hasSwapAvailable = false;
    
    // Can always upgrade to premium (if not already)
    final canBuyPremium = !businessOwner.isPremium;
    
    return hasSwapAvailable || canBuyPremium;
  }
  
  /// Get access level description for UI
  static String getAccessLevelDescription({
    required UserModel businessOwner,
    required TenantModel tenant,
  }) {
    if (businessOwner.isPremium) {
      return 'Premium - Akses Penuh';
    }
    
    if (tenant.hasPremiumSubscription) {
      return 'Tenant Premium - Akses Penuh';
    }
    
    if (tenant.selectedForFreeTier == true) {
      return 'Free Tier - Akses Penuh (Tenant Dipilih)';
    }
    
    return 'Free Tier - Akses Terbatas';
  }
}
