import 'package:kantin_app/ui/business_owner_dashboard.dart';
import 'package:kantin_app/ui/login_screen.dart';
import 'package:kantin_app/ui/tenant_dashboard.dart';
import 'package:kantin_app/ui/tenant_menu_screen.dart';
import 'package:kantin_app/src/features/tenant_management/presentation/screens/tenant_profile_screen.dart';
import 'package:go_router/go_router.dart';

final router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/biz',
      builder: (context, state) => const BusinessOwnerDashboard(),
    ),
    GoRoute(
      path: '/tenant',
      builder: (context, state) => const TenantDashboard(),
    ),
    GoRoute(
      path: '/tenant/profile',
      builder: (context, state) => const TenantProfileScreen(),
    ),
    GoRoute(
      path: '/tenant/:id',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return TenantMenuScreen(tenantId: id);
      },
    ),
  ],
);
