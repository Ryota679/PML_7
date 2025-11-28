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
import 'package:kantin_app/features/guest/presentation/customer_code_entry_page.dart';
import 'package:kantin_app/features/customer/presentation/customer_registration_page.dart';
import 'package:kantin_app/features/customer/presentation/customer_login_page.dart';
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

      // Jika masih loading, tampilkan loading
      if (isLoading) {
        return '/loading';
      }

      // Jika belum login, redirect ke guest landing (kecuali public routes)
      if (!isAuthenticated) {
        // Allow public access to these routes
        final isPublicRoute = state.matchedLocation == '/guest' ||
                              state.matchedLocation.startsWith('/menu/') || 
                              state.matchedLocation.startsWith('/cart/') ||
                              state.matchedLocation == '/enter-code' ||
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

      // Jika sudah login, redirect dari login ke dashboard sesuai role
      if (state.matchedLocation == '/login' || 
          state.matchedLocation == '/customer-login') {
        if (userRole == 'adminsystem') {
          return '/admin';
        } else if (userRole == AppConstants.roleOwnerBusiness) {
          return '/business-owner';
        } else if (userRole == AppConstants.roleTenant) {
          return '/tenant';
        } else if (userRole == AppConstants.roleCustomer) {
          return '/customer-dashboard';
        }
      }

      // Jika di root, redirect ke dashboard sesuai role
      if (state.matchedLocation == '/') {
        if (userRole == 'adminsystem') {
          return '/admin';
        } else if (userRole == AppConstants.roleOwnerBusiness) {
          return '/business-owner';
        } else if (userRole == AppConstants.roleTenant) {
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
      // Guest/Public routes
      GoRoute(
        path: '/enter-code',
        builder: (context, state) => const CustomerCodeEntryPage(),
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
