/// App Constants
/// 
/// Konstanta global yang digunakan di seluruh aplikasi
class AppConstants {
  // App Info
  static const String appName = 'Tenant QR-Order';
  static const String appVersion = '1.0.0';
  
  // Role Types
  // TODO: Fix typo in database enum: 'owner_bussines' -> 'owner_business'
  static const String roleOwnerBusiness = 'owner_bussines'; // Temporary: matches DB typo
  static const String roleTenant = 'tenant';
  static const String roleGuest = 'guest';
  static const String roleCustomer = 'customer'; // Pembeli terdaftar
  
  // Order Status
  static const String orderStatusPending = 'pending';
  static const String orderStatusPreparing = 'preparing';
  static const String orderStatusReadyForPickup = 'ready_for_pickup';
  static const String orderStatusCompleted = 'completed';
  static const String orderStatusCancelled = 'cancelled';
  
  // Tenant Status
  static const String tenantStatusActive = 'active';
  static const String tenantStatusInactive = 'inactive';
}
