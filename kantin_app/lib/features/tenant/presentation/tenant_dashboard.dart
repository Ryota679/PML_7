import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:kantin_app/features/auth/providers/auth_provider.dart';
import 'package:kantin_app/shared/models/permission_service.dart';
import 'package:kantin_app/shared/models/tenant_model.dart';
import 'pages/product_management_page.dart';
import 'pages/staff_management_page.dart';
import 'pages/qr_code_display_page.dart';
import 'pages/tenant_order_dashboard_page.dart';
import 'providers/current_tenant_provider.dart';

/// Tenant Dashboard
/// 
/// Dashboard untuk Tenant
class TenantDashboard extends ConsumerWidget {
  const TenantDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final tenantAsync = ref.watch(currentTenantProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Tenant'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              _showLogoutDialog(context, ref);
            },
            tooltip: 'Logout',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Selamat Datang,',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user?.fullName ?? 'Tenant',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Chip(
                          label: Text(user?.role ?? ''),
                          avatar: const Icon(Icons.person, size: 16),
                        ),
                        const SizedBox(width: 8),
                        tenantAsync.when(
                          data: (tenant) => tenant != null
                              ? Chip(
                                  label: Text(tenant.name),
                                  avatar: Text(tenant.type.icon),
                                  backgroundColor: Colors.blue.shade50,
                                )
                              : const SizedBox.shrink(),
                          loading: () => const SizedBox.shrink(),
                          error: (_, __) => const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Contract Status Card
            if (user?.contractEndDate != null)
              _buildContractStatusCard(context, user!.contractEndDate!),
            if (user?.contractEndDate != null)
              const SizedBox(height: 16),
            
            // Menu Grid
            Text(
              'Menu Utama',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                _buildMenuCard(
                  context,
                  icon: Icons.receipt_long,
                  title: 'Pesanan',
                  subtitle: 'Kelola pesanan masuk',
                  color: Colors.blue,
                  onTap: () {
                    // Navigate to tenant order dashboard
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const TenantOrderDashboardPage(),
                      ),
                    );
                  },
                ),
                _buildMenuCard(
                  context,
                  icon: Icons.restaurant_menu,
                  title: 'Menu',
                  subtitle: 'Kelola menu produk',
                  color: Colors.green,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ProductManagementPage(),
                      ),
                    );
                  },
                ),
                // QR Code - Navigate to QR display page
                tenantAsync.when(
                  data: (tenant) => tenant != null
                      ? _buildMenuCard(
                          context,
                          icon: Icons.qr_code,
                          title: 'QR Code',
                          subtitle: 'QR Code menu',
                          color: Colors.purple,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => QrCodeDisplayPage(
                                  tenantId: tenant.id!,
                                  tenantName: tenant.name,
                                ),
                              ),
                            );
                          },
                        )
                      : const SizedBox.shrink(),
                  loading: () => _buildMenuCard(
                    context,
                    icon: Icons.qr_code,
                    title: 'QR Code',
                    subtitle: 'Loading...',
                    color: Colors.purple,
                    onTap: () {},
                  ),
                  error: (_, __) => const SizedBox.shrink(),
                ),
                _buildMenuCard(
                  context,
                  icon: Icons.analytics,
                  title: 'Laporan',
                  subtitle: 'Lihat statistik',
                  color: Colors.orange,
                  onTap: () {
                    // TODO: Navigate to reports
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Fitur akan tersedia nanti'),
                      ),
                    );
                  },
                ),
                
                // Kelola Staff - Only for Tenant Owners
                if (PermissionService.canManageStaff(user))
                  _buildMenuCard(
                    context,
                    icon: Icons.people,
                    title: 'Kelola Staff',
                    subtitle: 'Manajemen staff',
                    color: Colors.teal,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const StaffManagementPage(),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContractStatusCard(BuildContext context, DateTime contractEndDate) {
    final now = DateTime.now();
    final daysRemaining = contractEndDate.difference(now).inDays;
    final isExpiringSoon = daysRemaining <= 7 && daysRemaining >= 0;
    final isExpired = daysRemaining < 0;

    return Card(
      color: isExpired 
          ? Colors.red.shade50 
          : isExpiringSoon 
              ? Colors.orange.shade50 
              : Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              isExpired ? Icons.error : Icons.check_circle,
              color: isExpired 
                  ? Colors.red 
                  : isExpiringSoon 
                      ? Colors.orange 
                      : Colors.green,
              size: 32,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isExpired ? 'Kontrak Habis' : 'Kontrak Aktif',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isExpired 
                          ? Colors.red.shade700 
                          : isExpiringSoon 
                              ? Colors.orange.shade700 
                              : Colors.green.shade700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isExpired
                        ? 'Hubungi business owner untuk perpanjangan'
                        : 'Sisa $daysRemaining hari (${DateFormat('dd MMM yyyy').format(contractEndDate)})',
                    style: TextStyle(
                      color: isExpired 
                          ? Colors.red.shade700 
                          : isExpiringSoon 
                              ? Colors.orange.shade700 
                              : Colors.green.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: color,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Apakah Anda yakin ingin keluar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () {
              ref.read(authProvider.notifier).logout();
              Navigator.pop(context);
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
