import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_app/core/constants/app_constants.dart';
import 'package:kantin_app/core/router/app_router.dart';
import 'package:kantin_app/core/services/local_notification_service.dart';
import 'package:kantin_app/core/theme/app_theme.dart';
import 'package:kantin_app/core/utils/logger.dart';
import 'package:kantin_app/features/tenant/providers/billing_provider.dart';
import 'package:kantin_app/shared/widgets/app_lifecycle_observer.dart';
import 'package:kantin_app/shared/widgets/purchase_feedback_listener.dart';

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize logger
  AppLogger.info('Starting Tenant QR-Order App');
  
  // Initialize local notifications
  AppLogger.info('📢 Initializing local notifications...');
  await LocalNotificationService.instance.initialize();
  AppLogger.info('✅ Local notifications initialized');
  
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

// Global key for ScaffoldMessenger to show SnackBars from anywhere
final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = 
    GlobalKey<ScaffoldMessengerState>();

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    
    // Pre-initialize billing service on mobile platforms only
    // This runs once when app starts, so products are ready before user clicks upgrade
    if (!kIsWeb) {
      ref.watch(billingServiceProvider);
      print('[MAIN] Billing service pre-initialized');
    }

    return AppLifecycleObserver(
      child: PurchaseFeedbackListener(
        child: MaterialApp.router(
          scaffoldMessengerKey: scaffoldMessengerKey, // ← Add global key
          title: AppConstants.appName,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.system,
          routerConfig: router,
        ),
      ),
    );
  }
}
