import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kantin_app/core/constants/app_constants.dart';
import 'package:kantin_app/features/auth/presentation/login_page.dart';
import 'package:kantin_app/features/auth/providers/auth_provider.dart';
import 'package:kantin_app/debug_admin_page.dart';
import 'package:kantin_app/features/admin/presentation/admin_dashboard.dart';
import 'package:kantin_app/features/business_owner/presentation/business_owner_dashboard.dart';
import 'package:kantin_app/features/registration/presentation/business_owner_registration_page.dart';
import 'package:kantin_app/features/tenant/presentation/tenant_dashboard.dart';
import 'package:kantin_app/features/guest/presentation/guest_landing_page.dart';
import 'package:kantin_app/features/guest/presentation/guest_menu_page.dart';
import 'package:kantin_app/features/guest/presentation/cart_page.dart';
import 'package:kantin_app/features/guest/presentation/pages/checkout_page.dart';
import 'package:kantin_app/features/guest/presentation/pages/order_tracking_page.dart';
import 'package:kantin_app/features/guest/presentation/customer_code_entry_page.dart';
import 'package:kantin_app/features/guest/presentation/pages/qr_scanner_page.dart';
import 'package:kantin_app/features/customer/presentation/customer_registration_page.dart';
import 'package:kantin_app/features/customer/presentation/customer_login_page.dart';
import 'package:kantin_app/features/tenant/presentation/pages/inactive_tenant_page.dart';
import 'package:kantin_app/features/tenant/presentation/pages/tenant_upgrade_payment_page.dart';
import 'package:kantin_app/shared/widgets/loading_widget.dart';

/// App Router Provider
final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final isLoading = authState.isLoading;
      final isAuthenticated = authState.isAuthenticated;
      final userRole = authState.user?.role;
      final isDeactivatedUser = authState.isDeactivatedUser;

      // DEBUG LOGGING
      if (isDeactivatedUser) {
        print('🔍 [ROUTER] Deactivated user detected!');
        print('🔍 [ROUTER] Current location: ${state.matchedLocation}');
        print('🔍 [ROUTER] isAuthenticated: $isAuthenticated');
        print('🔍 [ROUTER] isLoading: $isLoading');
      }

      // Jika masih loading, tampilkan loading
      if (isLoading) {
        return '/loading';
      }

      // CHECK 3: Navigation Guard - Real-time active status check
      // Only check for authenticated tenant/staff users on protected routes
      if (isAuthenticated && 
          userRole != null &&
          (userRole == 'tenant' || userRole == 'owner_business')) {
        
        // Skip check for public routes and login/register
        final isPublicRoute = state.matchedLocation == '/guest' ||
                              state.matchedLocation.startsWith('/menu/') || 
                              state.matchedLocation.startsWith('/cart/') ||
                              state.matchedLocation.startsWith('/checkout/') ||
                              state.matchedLocation.startsWith('/order/') ||
                              state.matchedLocation.startsWith('/payment/tenant-upgrade') ||
                              state.matchedLocation == '/enter-code' ||
                              state.matchedLocation == '/scan-qr' ||
                              state.matchedLocation == '/customer-login' ||
                              state.matchedLocation == '/customer-register' ||
                              state.matchedLocation == '/login' ||
                              state.matchedLocation == '/debug' ||
                              state.matchedLocation == '/register';
        
        if (!isPublicRoute) {
          // Perform real-time active status check
          print('🔍 [NAV GUARD] ══════════════════════════════════');
          print('🔍 [NAV GUARD] Target: ${state.matchedLocation}');
          print('🔍 [NAV GUARD] User: $userRole');
          print('🔍 [NAV GUARD] Deactivated flag BEFORE check: $isDeactivatedUser');
          print('🔍 [NAV GUARD] Triggering async status check...');
          
          // Trigger async check (will set deactivated flag if needed)
          // NOTE: This is non-blocking - navigation continues while check runs
          Future.microtask(() async {
            print('⏳ [NAV GUARD ASYNC] Starting database check...');
            final deactivatedInfo = await ref.read(authProvider.notifier).checkUserActiveStatus();
            if (deactivatedInfo != null) {
              print('⚠️ [NAV GUARD ASYNC] User deactivated during session!');
              print('🔒 [NAV GUARD ASYNC] Auto-destroying session...');
              
              // Auto-logout to destroy Appwrite session
              await ref.read(authProvider.notifier).logout();
              print('✅ [NAV GUARD ASYNC] Session destroyed');
              
              // NO manual navigation - logout changes auth state
              // Router will auto-redirect to login when it detects isAuthenticated = false
              print('🔄 [NAV GUARD ASYNC] Auth state changed, router will auto-redirect');
            } else {
              print('✅ [NAV GUARD ASYNC] User still active');
            }
          });
          
          print('🔍 [NAV GUARD] Async check triggered, continuing navigation...');
          print('🔍 [NAV GUARD] ══════════════════════════════════');
        }
      }

      // CRITICAL FIX: If user is deactivated, redirect TO login page
      // EXCEPT for payment page (allow deactivated users to upgrade)
      if (isDeactivatedUser && 
          state.matchedLocation != '/login' &&
          !state.matchedLocation.startsWith('/payment/tenant-upgrade')) {
        print('🔒 [ROUTER] Redirecting deactivated user TO /login to show dialog');
        return '/login';
      }

      // If already on login page and deactivated, stay there
      if (isDeactivatedUser && state.matchedLocation == '/login') {
        print('✅ [ROUTER] Already on login page, staying to show dialog');
        return null;
      }
      
      // If on payment page and deactivated, allow access (for self-upgrade)
      if (isDeactivatedUser && state.matchedLocation.startsWith('/payment/tenant-upgrade')) {
        print('✅ [ROUTER] Allowing deactivated user to access payment page for upgrade');
        return null;
      }

      // Jika belum login, redirect ke guest landing (kecuali public routes)
      if (!isAuthenticated) {
        // Allow public access to these routes
        final isPublicRoute = state.matchedLocation == '/guest' ||
                              state.matchedLocation.startsWith('/menu/') || 
                              state.matchedLocation.startsWith('/cart/') ||
                              state.matchedLocation.startsWith('/checkout/') ||
                              state.matchedLocation.startsWith('/order/') ||
                              state.matchedLocation.startsWith('/payment/tenant-upgrade') || // Payment page
                              state.matchedLocation == '/enter-code' ||
                              state.matchedLocation == '/scan-qr' ||
                              state.matchedLocation == '/customer-login' ||
                              state.matchedLocation == '/customer-register' ||
                              state.matchedLocation == '/login' ||
                              state.matchedLocation == '/debug' ||
                              state.matchedLocation == '/register';
        
        if (!isPublicRoute) {
          return '/guest'; // Redirect to guest landing page
        }
        return null;
      }

      //If from login, redirect to dashboard based on role
      if (state.matchedLocation == '/login' || 
          state.matchedLocation == '/customer-login') {
        if (userRole == 'adminsystem') {
          return '/admin';
        } else if (userRole == AppConstants.roleOwnerBusiness) {
          return '/business-owner';
        } else if (userRole == AppConstants.roleTenant) {
          // Staff users also have role='tenant', so check sub_role
          // Both tenant owners and staff go to /tenant for now
          // Staff page shows limited permissions UI
          return '/tenant';
        } else if (userRole == AppConstants.roleCustomer) {
          return '/customer-dashboard';
        }
      }

      // If at root, redirect to dashboard based on role
      if (state.matchedLocation == '/') {
        if (userRole == 'adminsystem') {
          return '/admin';
        } else if (userRole == AppConstants.roleOwnerBusiness) {
          return '/business-owner';
        } else if (userRole == AppConstants.roleTenant) {
          // Staff users also have role='tenant', so check sub_role
          // Both tenant owners and staff go to /tenant for now
          // Staff UI will be differentiated by sub_role in TenantDashboard
          return '/tenant';
        } else if (userRole == AppConstants.roleCustomer) {
          return '/customer-dashboard';
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const LoadingWidget(
          message: 'Memuat aplikasi...',
        ),
      ),
      GoRoute(
        path: '/loading',
        builder: (context, state) => const Scaffold(
          body: LoadingWidget(
            message: 'Memeriksa sesi...',
          ),
        ),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const BusinessOwnerRegistrationPage(),
      ),
      GoRoute(
        path: '/debug',
        builder: (context, state) => const DebugAdminPage(),
      ),
      // Guest Landing Page (for non-authenticated users)
      GoRoute(
        path: '/guest',
        builder: (context, state) => const GuestLandingPage(),
      ),
      // Public Payment Page (token-based access)
      GoRoute(
        path: '/payment/tenant-upgrade',
        redirect: (context, state) {
          final token = state.uri.queryParameters['token'];
          if (token == null || token.isEmpty) {
            print('❌ [ROUTER] No token provided for payment page');
            return '/guest';
          }
          print('✅ [ROUTER] Payment page accessed with token');
          return null; // Allow access
        },
        builder: (context, state) {
          final token = state.uri.queryParameters['token']!;
          return TenantUpgradePaymentPage(token: token);
        },
      ),
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminDashboard(),
      ),
      GoRoute(
        path: '/business-owner',
        builder: (context, state) => const BusinessOwnerDashboard(),
      ),
      GoRoute(
        path: '/tenant',
        builder: (context, state) => const TenantDashboard(),
      ),
      // Inactive Tenant Page
      GoRoute(
        path: '/inactive-tenant',
        builder: (context, state) => const InactiveTenantPage(),
      ),
      // Guest/Public routes
      GoRoute(
        path: '/enter-code',
        builder: (context, state) => const CustomerCodeEntryPage(),
      ),
      // QR Scanner
      GoRoute(
        path: '/scan-qr',
        builder: (context, state) => const QrScannerPage(),
      ),
      GoRoute(
        path: '/menu/:tenantId',
        builder: (context, state) {
          final tenantId = state.pathParameters['tenantId']!;
          return GuestMenuPage(tenantId: tenantId);
        },
      ),
      GoRoute(
        path: '/cart/:tenantId',
        builder: (context, state) {
          final tenantId = state.pathParameters['tenantId']!;
          return CartPage(tenantId: tenantId);
        },
      ),
      GoRoute(
        path: '/checkout/:tenantId',
        builder: (context, state) {
          final tenantId = state.pathParameters['tenantId']!;
          return CheckoutPage(tenantId: tenantId);
        },
      ),
      GoRoute(
        path: '/order/:orderNumber',
        builder: (context, state) {
          final orderNumber = state.pathParameters['orderNumber']!;
          return OrderTrackingPage(orderNumber: orderNumber);
        },
      ),
      // Customer routes (public access for login/register)
      GoRoute(
        path: '/customer-login',
        builder: (context, state) => const CustomerLoginPage(),
      ),
      GoRoute(
        path: '/customer-register',
        builder: (context, state) => const CustomerRegistrationPage(),
      ),
      GoRoute(
        path: '/customer-dashboard',
        builder: (context, state) => const Scaffold(
          body: Center(
            child: Text('Customer Dashboard - Coming Soon in Phase 3!'),
          ),
        ),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'Halaman tidak ditemukan',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              state.uri.toString(),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => context.go('/'),
              icon: const Icon(Icons.home),
              label: const Text('Kembali ke Beranda'),
            ),
          ],
        ),
      ),
    ),
  );
});
