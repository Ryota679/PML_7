import 'package:shared_preferences/shared_preferences.dart';
import '../../../shared/models/product_model.dart';
import '../providers/tenant_subscription_provider.dart';
import '../../products/providers/product_provider.dart';

/// Auto-Deactivation Service
/// 
/// Handles automatic product de activation when premium expires
/// Uses random selection to keep products within limit
class AutoDeactivationService {
  /// Check and auto-deactivate excess products if premium just expired
  static Future<void> checkAndAutoDeactivate({
    required String tenantId,
    required TenantSubscriptionStatus subscriptionStatus,
    required List<ProductModel> products,
    required Function(String productId, bool isAvailable) updateProduct,
  }) async {
    // 1. Check if just expired (compare with last known status)
    final prefs = await SharedPreferences.getInstance();
    final lastStatus = prefs.getString('last_premium_status_$tenantId');
    final currentStatus = subscriptionStatus.isBusinessOwnerFreeTier ? 'free' : 'premium';
    
    // Save current status for next check
    await prefs.setString('last_premium_status_$tenantId', currentStatus);
    
    // Only proceed if just transitioned from premium to free
    final justExpired = (lastStatus == 'premium' && currentStatus == 'free');
    if (!justExpired) return;
    
    // 2. Get new product limit
    final newLimit = subscriptionStatus.productLimit; // 10 or 15
    
    // 3. Get all active products
    final activeProducts = products.where((p) => p.isAvailable).toList();
    
    // 4. Check if over limit
    if (activeProducts.length <= newLimit) return;
    
    // 5. Random selection
    activeProducts.shuffle(); // Randomize order
    final toKeep = activeProducts.take(newLimit).toList();
    final toDeactivate = activeProducts.skip(newLimit).toList();
    
    // 6. Deactivate excess products
    for (final product in toDeactivate) {
      await updateProduct(product.id, false); // Set isAvailable = false
    }
    
    // 7. Set flag to show dialog in Kelola Menu
    await prefs.setBool('show_overlimit_dialog_$tenantId', true);
  }
  
  /// Check if should show over-limit dialog in Kelola Menu
  static Future<bool> shouldShowOverLimitDialog(String tenantId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('show_overlimit_dialog_$tenantId') ?? false;
  }
  
  /// Mark over-limit dialog as shown
  static Future<void> markDialogShown(String tenantId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('show_overlimit_dialog_$tenantId', false);
  }
  
  /// Check if user has permanently dismissed the dialog
  static Future<bool> hasUserDismissedDialog(String tenantId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('hide_overlimit_dialog_$tenantId') ?? false;
  }
  
  /// Permanently dismiss the dialog
  static Future<void> permanentlyDismissDialog(String tenantId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hide_overlimit_dialog_$tenantId', true);
  }
}
