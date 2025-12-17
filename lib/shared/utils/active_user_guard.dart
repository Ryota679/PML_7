import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_app/core/utils/logger.dart';
import 'package:kantin_app/features/auth/providers/auth_provider.dart';
import 'package:kantin_app/shared/widgets/deactivated_user_dialog.dart';

/// Active User Guard
/// 
/// Checks if user is active before allowing navigation
/// Implements CHECK 3: Navigation Guard
class ActiveUserGuard {
  final WidgetRef ref;
  final BuildContext context;

  ActiveUserGuard(this.ref, this.context);

  /// Check if navigation should be allowed
  /// 
  /// Returns true if user is active or not authenticated
  /// Returns false and shows dialog if user is deactivated
  Future<bool> canNavigate() async {
    final authState = ref.read(authProvider);
    
    // Allow navigation if not authenticated (guest flow)
    if (!authState.isAuthenticated) return true;

    // CHECK 3: Navigation Guard - Check if user is active
    AppLogger.info('🔍 Navigation Guard: Checking user active status');
    
    final deactivatedInfo = await ref
        .read(authProvider.notifier)
        .checkUserActiveStatus();

    if (deactivatedInfo != null) {
      // User is deactivated - block navigation and show dialog
      AppLogger.warning('⚠️ Navigation blocked - user deactivated');
      
      if (!context.mounted) return false;
      
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => DeactivatedUserDialog(
          userRole: deactivatedInfo.userRole,
          ownerName: deactivatedInfo.ownerName,
          ownerEmail: deactivatedInfo.ownerEmail,
          ownerPhone: deactivatedInfo.ownerPhone,
          onLogout: () async {
            await ref.read(authProvider.notifier).logout();
          },
          // TODO: Implement upgrade flow
          onUpgrade: null,
        ),
      );
      
      return false; // Block navigation
    }

    return true; // Allow navigation
  }

  /// Helper method for use in onTap handlers
  /// 
  /// Example:
  /// ```dart
  /// onTap: () async {
  ///   final guard = ActiveUserGuard(ref, context);
  ///   if (await guard.checkAndNavigate(() {
  ///     Navigator.push(...);
  ///   })) {
  ///     // Navigation succeeded
  ///   }
  /// }
  /// ```
  Future<bool> checkAndNavigate(VoidCallback navigate) async {
    if (await canNavigate()) {
      navigate();
      return true;
    }
    return false;
  }
}
