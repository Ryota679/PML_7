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
    
    // Thresholds
    final isExpired = daysRemaining < 0;
    final isCritical = daysRemaining >= 0 && daysRemaining < 7; // RED: < 7 days
    final isWarning = daysRemaining >= 7 && daysRemaining < 14; // ORANGE: 7-13 days
    final isActive = daysRemaining >= 14; // GREEN: 14+ days

    // Color scheme
    Color backgroundColor;
    Color iconColor;
    Color textColor;
    IconData iconData;
    String statusTitle;
    String statusMessage;

    if (isExpired) {
      backgroundColor = Colors.red.shade50;
      iconColor = Colors.red.shade700;
      textColor = Colors.red.shade700;
      iconData = Icons.error;
      statusTitle = 'Kontrak Habis';
      statusMessage = '⚠️ Akun Anda akan dihapus otomatis!\nSegera hubungi Business Owner untuk perpanjangan.';
    } else if (isCritical) {
      backgroundColor = Colors.red.shade50;
      iconColor = Colors.red.shade700;
      textColor = Colors.red.shade700;
      iconData = Icons.warning_amber;
      statusTitle = 'Segera Habis!';
      statusMessage = '🔴 Sisa $daysRemaining hari lagi (${DateFormat('dd MMM yyyy').format(contractEndDate)})\nHubungi Business Owner sekarang untuk perpanjangan!';
    } else if (isWarning) {
      backgroundColor = Colors.orange.shade50;
      iconColor = Colors.orange.shade700;
      textColor = Colors.orange.shade700;
      iconData = Icons.access_time;
      statusTitle = 'Kontrak Akan Berakhir';
      statusMessage = '🟠 Sisa $daysRemaining hari (${DateFormat('dd MMM yyyy').format(contractEndDate)})\nSegera hubungi Business Owner untuk perpanjangan.';
    } else {
      backgroundColor = Colors.green.shade50;
      iconColor = Colors.green.shade700;
      textColor = Colors.green.shade700;
      iconData = Icons.check_circle;
      statusTitle = 'Kontrak Aktif';
      statusMessage = 'Sisa $daysRemaining hari (${DateFormat('dd MMM yyyy').format(contractEndDate)})';
    }

    return Card(
      color: backgroundColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              iconData,
              color: iconColor,
              size: 32,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    statusTitle,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    statusMessage,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 13,
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
