import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_app/features/business_owner/services/tenant_swap_service.dart';
import 'package:kantin_app/features/business_owner/presentation/pages/tenant_selection_page.dart';
import 'package:kantin_app/shared/models/user_model.dart';

/// Helper functions for tenant selection and swap features
class TenantSelectionHelper {

  /// Show tenant selection page (full screen, like Kelola Tenant)
  /// 
  /// Use when:
  /// - User trial expired and has >2 tenants
  /// - User wants to change selection (within swap window)
  static Future<bool?> showSelectionDialog(
    BuildContext context, {
    required WidgetRef ref,
    required UserModel user,
    bool isSwap = false,
  }) async {
    try {
      // Get swap service from provider
      final swapService = ref.read(tenantSwapServiceProvider);
      // Fetch user's tenants (use userId = Auth ID, not document ID)
      final tenants = await swapService.getUserTenants(user.userId);

      if (tenants.length <= 2) {
        // No need to select if user has 2 or fewer tenants
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Anda hanya memiliki <= 2 tenant, tidak perlu memilih'),
            ),
          );
        }
        return null;
      }

      // Navigate to full-page selection
      if (context.mounted) {
        return await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (context) => TenantSelectionPage(
              userId: user.userId,  // Use Auth ID
              tenants: tenants,
              isSwap: isSwap,
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat data tenant: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
    
    return null;
  }

  /// Check if user should see selection dialog
  /// 
  /// Returns true if:
  /// - User is on FREE tier
  /// - User has payment_status = 'expired' (trial ended)
  /// - User has NOT made manual selection yet
  static bool shouldShowSelectionPrompt(UserModel user) {
    return user.subscriptionTier == 'free' &&
           user.paymentStatus == 'expired' &&
           user.manualTenantSelection != true;
  }

  /// Check if user can use swap (DISABLED - grace period removed)
  static Future<bool> canUserSwap(UserModel user) async {
    // Grace period swap removed
    return false;
  }

  /// Get swap days remaining (DISABLED - grace period removed)
  static int getSwapDaysRemaining(UserModel user) {
    // Grace period swap removed
    return 0;
  }
}
