import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_app/features/auth/providers/auth_provider.dart';
import 'package:kantin_app/shared/models/user_model.dart';
import 'package:badges/badges.dart' as badges;
import 'tenant_management_page.dart';
import 'tenant_user_management_page.dart';
import 'pages/tenant_contracts_page.dart';
import 'pages/downgrade_impact_page.dart';
import 'providers/tenant_contracts_provider.dart';
import '../providers/tenant_provider.dart';
import 'widgets/trial_warning_banner.dart';
import 'widgets/swap_opportunity_banner.dart';
import 'widgets/swap_used_banner.dart';
import 'widgets/free_tier_banner.dart';
import 'widgets/grace_period_banner.dart';
import 'widgets/d7_selection_banner.dart';
import 'widgets/no_selection_needed_banner.dart';
import 'widgets/consolidated_trial_warning_banner.dart';
import '../utils/tenant_selection_helper.dart';
import 'pages/tenant_report_page.dart';
import 'package:kantin_app/shared/widgets/upgrade_banner.dart';
import 'package:kantin_app/shared/widgets/upgrade_dialog.dart';

/// Business Owner Dashboard
/// 
/// Dashboard untuk Business Owner (owner_business)
class BusinessOwnerDashboard extends ConsumerWidget {
  const BusinessOwnerDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Business Owner'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'logout') {
                _showLogoutDialog(context, ref);
              } else if (value == 'delete_account') {
                _confirmDeleteAccount(context, ref);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.black),
                    SizedBox(width: 8),
                    Text('Logout'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete_account',
                child: Row(
                  children: [
                    Icon(Icons.delete_forever, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Delete Account', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // D-7 Selection Banner or Success Banner (NEW - educational flow)
            // Show success banner if ≤2 tenants, otherwise show selection banner
            if (user != null && (user.paymentStatus == 'trial' || 
                user.paymentStatus == 'premium' || 
                user.paymentStatus == 'active')) ...
              [
                Consumer(
                  builder: (context, ref, child) {
                    final tenantsState = ref.watch(myTenantsProvider);
                    final tenantCount = tenantsState.tenants.length;
                    
                    // Success banner for ≤2 tenants
                    if (tenantCount <= 2) {
                      // Only show during D-7 to D-0 window
                      final daysRemaining = user.subscriptionExpiresAt
                          ?.difference(DateTime.now()).inDays ?? 999;
                      
                      if (daysRemaining >= 0 && daysRemaining <= 7) {
                        return NoSelectionNeededBanner(tenantCount: tenantCount);
                      }
                    }
                    
                    // DISABLED: Old selection banner replaced by consolidated educational banner
                    return const SizedBox.shrink();
                  },
                ),
              ],
            
            // Consolidated Trial Warning Banner (replaces old trial warning)
            if (user != null)
              ConsolidatedTrialWarningBanner(user: user),
            
            // Swap Opportunity Banner (D-7, after selection, swap NOT used yet)
            if (user != null && 
                (user.paymentStatus == 'trial' || 
                 user.paymentStatus == 'premium' || 
                 user.paymentStatus == 'active') &&
                user.selectionSubmittedAt != null &&
                user.swapUsed != true &&
                user.daysUntilTrialExpiry >= 0 &&
                user.daysUntilTrialExpiry <= 7)
              SwapOpportunityBanner(user: user),
            
            
            // Free Tier Upgrade Banner removed - FreeTierBanner below is enough
            // (Was showing duplicate purple banner)
            
            // Free Tier Upgrade Banner (for free tier users, NOT trial)
            if (user != null && user.isFree && user.paymentStatus != 'trial')
              FreeTierBanner(
                onUpgrade: () => _showLaporanUpgradeDialog(context),
              ),
            
            // Grace Period Banner (ONLY post-trial, NOT during trial)
            if (user != null && user.paymentStatus != 'trial' && _shouldShowGracePeriodBanner(user))
              GracePeriodBanner(
                user: user,
                daysRemaining: _getGraceDaysRemaining(user),
                onChooseUsers: () => _showUserSelectionDialog(context),
              ),
            
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
                      user?.fullName ?? 'Business Owner',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Chip(
                      label: Text(user?.role ?? ''),
                      avatar: const Icon(Icons.business, size: 16),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Contract Status Card (ONLY for tenant/staff, not for owner_business)
            // Business owners use subscription_expires_at instead
            if (user?.role != 'owner_business' && user?.role != 'owner_bussines')
              _buildContractCard(context, user),
            
            // Add spacing only if contract card is shown
            if (user?.role != 'owner_business' && user?.role != 'owner_bussines')
              const SizedBox(height: 24),
            
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
                  icon: Icons.store,
                  title: 'Kelola Tenant',
                  subtitle: 'Tambah & edit tenant',
                  color: Colors.blue,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const TenantManagementPage(),
                      ),
                    );
                  },
                ),
                _buildMenuCard(
                  context,
                  icon: Icons.people,
                  title: 'Kelola User',
                  subtitle: 'Tambah admin tenant',
                  color: Colors.green,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const TenantUserManagementPage(),
                      ),
                    );
                  },
                ),
                // Kelola Kontrak with Badge
                Consumer(
                  builder: (context, ref, child) {
                    final tenantUsersAsync = ref.watch(tenantContractsProvider);
                    
                    int expiringCount = 0;
                    tenantUsersAsync.whenData((users) {
                      final now = DateTime.now();
                      expiringCount = users.where((tenantUserInfo) {
                        if (tenantUserInfo.user.contractEndDate == null) return false;
                        final daysRemaining = tenantUserInfo.user.contractEndDate!.difference(now).inDays;
                        return daysRemaining < 14 && daysRemaining >= 0; // Expiring within 14 days
                      }).length;
                    });
                    
                    return _buildMenuCardWithBadge(
                      context,
                      icon: Icons.calendar_month,
                      title: 'Kelola Kontrak',
                      subtitle: 'Atur kontrak tenant',
                      color: Colors.teal,
                      badgeCount: expiringCount,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const TenantContractsPage(),
                          ),
                        );
                      },
                    );
                  },
                ),
                // Pilih Tenant Aktif (Freemium Feature)
                if (user != null && (user.isFree || user.isTrialActive))
                  _buildMenuCard(
                    context,
                    icon: Icons.check_circle_outline,
                    title: 'Pilih Tenant Aktif',
                    subtitle: 'Pilih 2 tenant (free tier)',
                    color: Colors.purple,
                    onTap: () async {
                      // Navigate to downgrade impact page (educational flow)
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DowngradeImpactPage(user: user),
                        ),
                      );
                      
                      // Refresh after returning
                      await ref.read(authProvider.notifier).refreshUserProfile();
                      await ref.read(myTenantsProvider.notifier).loadTenants();
                    },
                  ),
                _buildMenuCard(
                  context,
                  icon: Icons.analytics,
                  title: 'Laporan',
                  subtitle: 'Lihat statistik',
                  color: Colors.orange,
                  onTap: () {
                    // Check if user is premium
                    if (user == null) return;
                    
                    if (user.isFree) {
                      // Show upgrade dialog for free tier
                      _showLaporanUpgradeDialog(context);
                    } else {
                      // Premium users can access
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const TenantReportPage(),
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
      // FAB removed - invitation now in Kelola Tenant menu
    );
  }

  Widget _buildContractCard(BuildContext context, user) {
    if (user?.contractEndDate == null) {
      return Card(
        color: Colors.orange[50],
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[100],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.event_busy,
                  color: Colors.orange[700],
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Kontrak Belum Diatur',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange[900],
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Hubungi admin untuk aktivasi kontrak',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.orange[800],
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

    final contractEndDate = user!.contractEndDate!;
    final now = DateTime.now();
    final difference = contractEndDate.difference(now);
    final daysRemaining = difference.inDays;

    Color statusColor;
    IconData statusIcon;
    String statusTitle;
    String statusSubtitle;

    if (daysRemaining < 0) {
      statusColor = Colors.red;
      statusIcon = Icons.error_outline;
      statusTitle = 'Kontrak Expired';
      statusSubtitle = 'Expired ${daysRemaining.abs()} hari yang lalu';
    } else if (daysRemaining == 0) {
      statusColor = Colors.orange;
      statusIcon = Icons.warning_amber;
      statusTitle = 'Kontrak Berakhir Hari Ini!';
      statusSubtitle = 'Segera hubungi admin';
    } else if (daysRemaining <= 7) {
      statusColor = Colors.orange;
      statusIcon = Icons.warning_amber;
      statusTitle = 'Sisa $daysRemaining Hari';
      statusSubtitle = 'Kontrak akan berakhir: ${_formatDate(contractEndDate)}';
    } else {
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
      statusTitle = 'Kontrak Aktif';
      statusSubtitle = 'Sisa $daysRemaining hari (${_formatDate(contractEndDate)})';
    }

    return Card(
      color: statusColor.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                statusIcon,
                color: statusColor,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    statusTitle,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: statusColor.withOpacity(0.9),
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    statusSubtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: statusColor.withOpacity(0.8),
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

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
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

  // Menu card with badge for notifications
  Widget _buildMenuCardWithBadge(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required int badgeCount,
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
              badges.Badge(
                showBadge: badgeCount > 0,
                badgeContent: Text(
                  '$badgeCount',
                  style: const TextStyle(color: Colors.white, fontSize: 10),
                ),
                badgeStyle: badges.BadgeStyle(
                  badgeColor: Colors.red.shade600,
                ),
                child: Container(
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

  void _confirmDeleteAccount(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'Are you sure you want to delete your account? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context);
              _deleteAccount(context, ref);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAccount(BuildContext context, WidgetRef ref, {bool force = false}) async {
    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      await ref.read(authProvider.notifier).deleteAccount(force: force);

      // Pop loading
      if (context.mounted) Navigator.pop(context);

      // Navigation is handled by auth state change
      
    } catch (e) {
      // Pop loading
      if (context.mounted) Navigator.pop(context);

      if (e.toString().contains('HAS_ACTIVE_TENANTS')) {
        if (context.mounted) {
          _showForceDeleteDialog(context, ref);
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete account: $e')),
          );
        }
      }
    }
  }

  void _showForceDeleteDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 8),
            Text('Warning: Active Tenants'),
          ],
        ),
        content: const Text(
          'You have active tenants. Deleting your account will PERMANENTLY DELETE all tenants, staff, products, and orders associated with your business.\n\nThis action cannot be undone. Are you absolutely sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context);
              _deleteAccount(context, ref, force: true);
            },
            child: const Text('DELETE EVERYTHING'),
          ),
        ],
      ),
    );
  }

  void _showLaporanUpgradeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.workspace_premium, color: Colors.purple.shade700),
            const SizedBox(width: 12),
            const Expanded(
              child: Text('Fitur Premium'),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Laporan & Analitik adalah fitur premium.',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
            const Text(
              'Dengan Premium, Anda mendapatkan:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildFeatureRow('📊 Statistik pendapatan & transaksi'),
            _buildFeatureRow('⭐ Top 5 produk terlaris'),
            _buildFeatureRow('📈 Analisis trend penjualan'),
            _buildFeatureRow('📅 Historical data (6 bulan)'),
            _buildFeatureRow('📄 Export PDF & Excel'),
            _buildFeatureRow('♾️ Unlimited tenants'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.purple.shade700,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.purple.shade900, width: 2),
              ),
              child: Row(
                children: [
                  Icon(Icons.star, color: Colors.amber, size: 28),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Business Owner Premium',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: 15,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Rp 149.000/bulan',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Navigate to upgrade page
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('🚧 Payment integration coming soon'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.purple,
            ),
            child: const Text('Upgrade Sekarang'),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureRow(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }
  
  // ===== Phase 3: Upgrade Dialog =====
  
  /// Show upgrade dialog for free tier users
  void _showUpgradeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const UpgradeDialog(
        isBusinessOwner: true,
      ),
    );
  }

  
  // ===== Grace Period Helpers (DISABLED - grace period removed) =====
  
  /// Check if grace period banner should be shown
  bool _shouldShowGracePeriodBanner(UserModel user) {
    // Grace period feature removed - always return false
    return false;
  }
  
  /// Get days remaining in grace period
  int _getGraceDaysRemaining(UserModel user) {
    // Grace period feature removed - always return 0
    return 0;
  }
  
  /// Navigate to user selection page
  void _showUserSelectionDialog(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const TenantUserManagementPage(
          isSelectionMode: true,
        ),
      ),
    );
  }
}
