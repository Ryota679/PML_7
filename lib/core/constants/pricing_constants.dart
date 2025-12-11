/// Pricing Constants for Premium Subscriptions
/// 
/// Defines pricing for Business Owner and Tenant premium tiers
class PricingConstants {
  // Business Owner Premium Pricing
  static const int BO_PREMIUM_MONTHLY_IDR = 149000;  // Rp 149.000/bulan
  static const int BO_PREMIUM_YEARLY_IDR = 1490000;  // Rp 1.490.000/tahun (save 2 months)
  
  static const String BO_PREMIUM_DESCRIPTION = 
    'Unlimited tenants, full management access, advanced analytics';
  
  static const List<String> BO_PREMIUM_FEATURES = [
    'Unlimited tenants',
    'Full CRUD access untuk semua tenant',
    'Advanced analytics & reports',
    'Priority support',
    'Contract management',
  ];
  
  // Tenant Premium Pricing (per tenant)
  static const int TENANT_PREMIUM_MONTHLY_IDR = 49000;  // Rp 49.000/bulan
  static const int TENANT_PREMIUM_YEARLY_IDR = 490000;  // Rp 490.000/tahun (save 2 months)
  
  static const String TENANT_PREMIUM_DESCRIPTION = 
    'Unlimited products, unlimited staff, advanced analytics';
  
  static const List<String> TENANT_PREMIUM_FEATURES = [
    'Unlimited products (1000+)',
    'Unlimited staff (50+)',
    'Unlimited categories',
    'Advanced sales analytics',
    'Product performance insights',
    'Priority support',
  ];
  
  // Payment methods (for future integration)
  static const List<String> PAYMENT_METHODS = [
    'gopay',
    'ovo',
    'dana',
    'shopee_pay',
    'bank_transfer',
    'qris',
  ];
  
  // Discount codes (example structure for future)
  static const Map<String, double> PROMO_CODES = {
    'LAUNCH50': 0.5,  // 50% off
    'EARLYBIRD': 0.3,  // 30% off
  };
}
