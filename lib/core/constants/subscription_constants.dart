class SubscriptionConstants {
  // Trial
  static const int TRIAL_DURATION_DAYS = 30;
  
  // Invitation
  static const int INVITATION_EXPIRY_HOURS = 5;
  
  // Selection
  static const int MAX_SELECTED_TENANTS = 2;
  static const int MAX_SWAP_COUNT = 1;  // 1x swap allowed
  
  // SELECTED Tenant Limits (Better limits for 2 selected tenants)
  static const int SELECTED_MAX_PRODUCTS = 20;
  static const int SELECTED_MAX_STAFF = 2;
  static const int SELECTED_MAX_CATEGORIES = 10;
  
  // NON-SELECTED Tenant Limits (Stricter limits for remaining tenants)
  static const int NON_SELECTED_MAX_PRODUCTS = 10;
  static const int NON_SELECTED_MAX_STAFF = 1;
  static const int NON_SELECTED_MAX_CATEGORIES = 10;
  
  // Premium Limits (Unlimited)
  static const int PREMIUM_MAX_TENANTS = 999;
  static const int PREMIUM_MAX_PRODUCTS = 999;
  static const int PREMIUM_MAX_STAFF = 999;
  static const int PREMIUM_MAX_CATEGORIES = 999;
  
  // Trial warnings (days before expiry)
  static const List<int> WARNING_DAYS = [7, 3, 1];
  
  // Deprecated - kept for backward compatibility
  @Deprecated('Use tiered limits (SELECTED_* or NON_SELECTED_*) instead')
  static const int FREE_MAX_TENANTS = 2;
  
  @Deprecated('Use SELECTED_MAX_PRODUCTS or NON_SELECTED_MAX_PRODUCTS instead')
  static const int FREE_MAX_PRODUCTS_PER_TENANT = 20;
  
  @Deprecated('Use SELECTED_MAX_STAFF or NON_SELECTED_MAX_STAFF instead')
  static const int FREE_MAX_STAFF_PER_TENANT = 1;
  
  @Deprecated('No longer used - removed grace period mechanism')
  static const int SWAP_GRACE_PERIOD_DAYS = 7;
}
