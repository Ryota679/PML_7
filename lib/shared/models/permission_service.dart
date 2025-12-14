import '../models/user_model.dart';

/// Permission Service
/// 
/// Centralized permission checking for role-based access control
class PermissionService {
  /// Check if user can manage products (create, edit, delete)
  static bool canManageProducts(UserModel? user) {
    if (user == null) return false;
    return user.isTenantOwner;
  }

  /// Check if user can manage categories
  static bool canManageCategories(UserModel? user) {
    if (user == null) return false;
    return user.isTenantOwner;
  }

  /// Check if user can manage staff (create, remove staff accounts)
  static bool canManageStaff(UserModel? user) {
    if (user == null) return false;
    return user.isTenantOwner;
  }

  /// Check if user can view reports and analytics
  static bool canViewReports(UserModel? user) {
    if (user == null) return false;
    return user.isTenantOwner;
  }

  /// Check if user can view orders (both owner and staff)
  static bool canViewOrders(UserModel? user) {
    if (user == null) return false;
    return user.role == 'tenant'; // Both owner and staff
  }

  /// Check if user can update order status (both owner and staff)
  static bool canUpdateOrderStatus(UserModel? user) {
    if (user == null) return false;
    return user.role == 'tenant'; // Both owner and staff
  }

  /// Check if user can manage tenant settings
  static bool canManageTenantSettings(UserModel? user) {
    if (user == null) return false;
    return user.isTenantOwner;
  }

  /// Check if user is business owner (can manage all tenants)
  static bool isBusinessOwner(UserModel? user) {
    if (user == null) return false;
    return user.isBusinessOwner;
  }

  /// Check if user is admin system
  static bool isAdminSystem(UserModel? user) {
    if (user == null) return false;
    return user.role == 'adminsystem';
  }

  /// Get user role display name
  static String getRoleDisplayName(UserModel user) {
    if (user.role == 'adminsystem') return 'Admin System';
    if (user.isBusinessOwner) return 'Business Owner';
    if (user.isTenantOwner) return 'Tenant Owner';
    if (user.isTenantStaff) return 'Staff';
    if (user.role == 'guest') return 'Guest';
    return 'Unknown';
  }

  /// Get sub-role display name (for badges)
  static String? getSubRoleDisplayName(UserModel user) {
    if (user.subRole == 'staff') return 'Staff';
    if (user.role == 'tenant' && user.subRole == null) return 'Owner';
    return null;
  }
}
