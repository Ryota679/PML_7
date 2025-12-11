import 'package:kantin_app/shared/models/user_model.dart';
import 'package:kantin_app/shared/models/tenant_model.dart';

/// Tenant Access Guard
/// 
/// Checks if user can access a specific tenant based on freemium rules
class TenantAccessGuard {
  /// Check if user can access tenant
  /// 
  /// Returns true if:
  /// - User is premium (unlimited access)
  /// - User is free tier AND tenant is selected
  /// - User is free tier AND still in grace period (can swap)
  /// - User is on trial (unlimited access during trial)
  static bool canAccessTenant({
    required UserModel user,
    required TenantModel tenant,
  }) {
    // Premium users have unlimited access
    if (user.isPremium) return true;
    
    // Trial users have unlimited access
    if (user.isTrialActive) return true;
    
    // Free tier users must check tenant selection
    if (user.isFree) {
      // Check if tenant is selected for free tier
      final isSelected = tenant.selectedForFreeTier ?? false;
      
      // If tenant is selected, allow access
      if (isSelected) return true;
      
      // If user is in grace period (can swap), allow access temporarily
      // This allows user to see all tenants before making swap decision
      if (user.swapAvailableUntil != null) {
        final now = DateTime.now();
        final inGracePeriod = user.swapAvailableUntil!.isAfter(now);
        
        if (inGracePeriod) return true;
      }
      
      // Otherwise, deny access
      return false;
    }
    
    // Default: allow access (shouldn't reach here)
    return true;
  }
  
  /// Check if user should see "select tenants" warning
  /// 
  /// Returns true if:
  /// - User is free tier
  /// - User has NOT manually selected tenants yet
  /// - User has more than 2 tenants
  static bool shouldShowSelectionWarning(UserModel user, int tenantCount) {
    if (!user.isFree) return false;
    if (tenantCount <= 2) return false;
    
    final hasManuallySelected = user.manualTenantSelection ?? false;
    return !hasManuallySelected;
  }
  
  /// Get access denial reason
  static String getAccessDenialReason({
    required UserModel user,
    required TenantModel tenant,
  }) {
    if (user.isFree) {
      final isSelected = tenant.selectedForFreeTier ?? false;
      
      if (!isSelected) {
        // Check if grace period has ended
        if (user.swapAvailableUntil != null) {
          final now = DateTime.now();
          final gracePeriodEnded = user.swapAvailableUntil!.isBefore(now);
          
          if (gracePeriodEnded) {
            return 'Tenant ini tidak termasuk dalam 2 tenant aktif Anda. Masa tenggang untuk menukar telah berakhir.';
          }
        }
        
        return 'Tenant ini tidak termasuk dalam 2 tenant aktif Anda pada paket gratis.';
      }
    }
    
    return 'Akses ditolak';
  }
}
