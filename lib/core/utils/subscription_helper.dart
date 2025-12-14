import 'package:kantin_app/shared/models/user_model.dart';

/// Helper utilities for subscription tier management and feature access control
/// 
/// Phase 3 Enforcement: Free tier restrictions for Business Owner and Tenants
class SubscriptionHelper {
  /// Check if user is on free tier (not trial, not premium)
  static bool isFreeTier(UserModel user) {
    // Free tier: payment_status is null, 'free', or trial expired
    if (user.paymentStatus == null || user.paymentStatus == 'free') {
      return true;
    }
    
    // If trial, check if expired
    if (user.paymentStatus == 'trial') {
      if (user.subscriptionExpiresAt == null) return false;
      
      final expiresAt = DateTime.parse(user.subscriptionExpiresAt!);
      final now = DateTime.now();
      
      // Trial expired = free tier
      return now.isAfter(expiresAt);
    }
    
    // Premium or other statuses
    return false;
  }
  
  /// Check if user can create/edit content (not on free tier)
  static bool canEdit(UserModel user) {
    return !isFreeTier(user);
  }
  
  /// Check if user can create new content (not on free tier)
  static bool canCreate(UserModel user) {
    return !isFreeTier(user);
  }
  
  /// Check if user is on trial (active, not expired)
  static bool isActiveTrial(UserModel user) {
    if (user.paymentStatus != 'trial') return false;
    if (user.subscriptionExpiresAt == null) return false;
    
    final expiresAt = DateTime.parse(user.subscriptionExpiresAt!);
    final now = DateTime.now();
    
    return now.isBefore(expiresAt);
  }
  
  /// Check if user is on premium
  static bool isPremium(UserModel user) {
    return user.paymentStatus == 'premium';
  }
  
  /// Get days remaining in trial (returns 0 if not trial or expired)
  static int getDaysRemainingInTrial(UserModel user) {
    if (user.paymentStatus != 'trial') return 0;
    if (user.subscriptionExpiresAt == null) return 0;
    
    final expiresAt = DateTime.parse(user.subscriptionExpiresAt!);
    final now = DateTime.now();
    
    if (now.isAfter(expiresAt)) return 0;
    
    return expiresAt.difference(now).inDays;
  }
  
  /// Get tier display name
  static String getTierName(UserModel user) {
    if (isPremium(user)) return 'Premium';
    if (isActiveTrial(user)) return 'Trial';
    return 'Free';
  }
  
  /// Check if Business Owner can access feature based on ownership
  /// Used for features that require ownership checks (e.g., tenant management by BO)
  static bool canAccessAsOwner(UserModel currentUser, String ownerId) {
    // Premium can always access
    if (isPremium(currentUser)) return true;
    
    // Active trial can always access
    if (isActiveTrial(currentUser)) return true;
    
    // Free tier: can only VIEW (handled by canEdit/canCreate separately)
    // For now, allow access but restrict actions
    return currentUser.id == ownerId;
  }
}
