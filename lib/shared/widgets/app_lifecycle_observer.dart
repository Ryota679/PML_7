import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kantin_app/core/utils/logger.dart';
import 'package:kantin_app/features/auth/providers/auth_provider.dart';
import 'package:kantin_app/shared/widgets/deactivated_user_dialog.dart';

/// App Lifecycle Observer
/// 
/// Monitors app lifecycle and checks user active status on resume
class AppLifecycleObserver extends ConsumerStatefulWidget {
  final Widget child;

  const AppLifecycleObserver({
    super.key,
    required this.child,
  });

  @override
  ConsumerState<AppLifecycleObserver> createState() => _AppLifecycleObserverState();
}

class _AppLifecycleObserverState extends ConsumerState<AppLifecycleObserver>
    with WidgetsBindingObserver {
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // Debug logging for all state changes
    AppLogger.info('🔄 [LIFECYCLE] State changed to: $state');

    // CHECK 2: App Resume Guard
    if (state == AppLifecycleState.resumed) {
      AppLogger.info('📱 [LIFECYCLE] App RESUMED - checking user active status');
      AppLogger.info('════════════════════════════════════════');
      
      // Check user status
      _checkUserActiveStatus();
    } else if (state == AppLifecycleState.paused) {
      AppLogger.info('⏸️ [LIFECYCLE] App PAUSED (minimized)');
    } else if (state == AppLifecycleState.inactive) {
      AppLogger.info('🔶 [LIFECYCLE] App INACTIVE');
    }
  }

  Future<void> _checkUserActiveStatus() async {
    final authState = ref.read(authProvider);
    
    AppLogger.info('🔍 [LIFECYCLE CHECK] Starting active status check...');
    AppLogger.info('   - isAuthenticated: ${authState.isAuthenticated}');
    AppLogger.info('   - user role: ${authState.user?.role}');
    AppLogger.info('   - user email: ${authState.user?.email}');
    
    // Only check if user is authenticated
    if (!authState.isAuthenticated) {
      AppLogger.info('❌ [LIFECYCLE CHECK] User not authenticated - skipping check');
      return;
    }

    AppLogger.info('⏳ [LIFECYCLE CHECK] Calling checkUserActiveStatus()...');
    final deactivatedInfo = await ref
        .read(authProvider.notifier)
        .checkUserActiveStatus();

    AppLogger.info('📊 [LIFECYCLE CHECK] Result: ${deactivatedInfo != null ? "DEACTIVATED" : "ACTIVE"}');

    if (deactivatedInfo != null) {
      // User is deactivated - MUST destroy session to prevent "session_already_exists" error
      AppLogger.warning('⚠️ [LIFECYCLE CHECK] User deactivated - auto-destroying session');
      
      // Auto-logout to destroy Appwrite session
      // Router will automatically redirect to /login when isAuthenticated becomes false
      await ref.read(authProvider.notifier).logout();
      AppLogger.info('✅ [LIFECYCLE CHECK] Session destroyed, router will auto-redirect to login');
      
      // NO manual navigation - let router handle redirect via state change
    } else {
      AppLogger.info('✅ [LIFECYCLE CHECK] User still active - no action needed');
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
