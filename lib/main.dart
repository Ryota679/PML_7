import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_app/core/constants/app_constants.dart';
import 'package:kantin_app/core/router/app_router.dart';
import 'package:kantin_app/core/theme/app_theme.dart';
import 'package:kantin_app/core/utils/logger.dart';

void main() {
  // Initialize logger
  AppLogger.info('Starting Tenant QR-Order App');
  
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}
