class SubscriptionConstants {
  // Trial
  static const int TRIAL_DURATION_DAYS = 30;  // Changed from 7
  
  // Invitation
  static const int INVITATION_EXPIRY_HOURS = 5;  // Changed from 7 days = 168 hours
  
  // Tier limits
  static const int FREE_MAX_TENANTS = 2;
  static const int FREE_MAX_PRODUCTS_PER_TENANT = 30;
  static const int FREE_MAX_STAFF_PER_TENANT = 3;
  
  static const int PREMIUM_MAX_TENANTS = 999;
  static const int PREMIUM_MAX_PRODUCTS_PER_TENANT = 999;
  static const int PREMIUM_MAX_STAFF_PER_TENANT = 999;
  
  // Trial warnings (days before expiry)
  static const List<int> WARNING_DAYS = [7, 3, 1];
  
  // Swap feature
  static const int SWAP_GRACE_PERIOD_DAYS = 7;  // 1 week after downgrade
}
