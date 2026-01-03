import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:kantin_app/features/auth/providers/auth_provider.dart';
import 'package:kantin_app/features/notifications/presentation/widgets/notification_bell.dart';
import 'package:kantin_app/features/notifications/providers/notification_provider.dart';
import 'package:kantin_app/shared/models/permission_service.dart';
import 'package:kantin_app/shared/models/tenant_model.dart';
import 'package:kantin_app/shared/models/user_model.dart';
import 'package:kantin_app/core/config/appwrite_config.dart';
import 'package:kantin_app/core/providers/appwrite_provider.dart';
import 'package:kantin_app/shared/widgets/upgrade_dialog.dart';
import 'package:appwrite/appwrite.dart';
import 'widgets/tenant_grace_warning_banner.dart';
import 'widgets/tenant_d7_warning_banner.dart';
import 'widgets/tenant_consolidated_trial_banner.dart';
import 'widgets/tenant_not_selected_banner.dart';
import 'widgets/tenant_selected_banner.dart';
import '../../business_owner/providers/grace_period_provider.dart';
import '../../business_owner/presentation/widgets/free_tier_banner.dart';
import 'pages/product_management_page.dart';
import 'pages/staff_management_page.dart';
import 'pages/qr_code_display_page.dart';
import 'pages/tenant_order_dashboard_page.dart';
import 'pages/tenant_single_report_page.dart';
import 'providers/current_tenant_provider.dart';
import '../providers/tenant_subscription_provider.dart';
import '../providers/product_provider.dart';
import 'widgets/contact_owner_banner.dart';
import 'widgets/expiry_warning_banner.dart';

/// Tenant Dashboard
/// 
/// Dashboard untuk Tenant
class TenantDashboard extends ConsumerStatefulWidget {
  const TenantDashboard({super.key});

  @override
  ConsumerState<TenantDashboard> createState() => _TenantDashboardState();
}

class _TenantDashboardState extends ConsumerState<TenantDashboard> {
  @override
  void initState() {
    super.initState();
    
    // Start order notification subscription
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Start subscription for tenant/staff
      ref.read(notificationProvider.notifier).startOrderSubscription();
      
      // Check and auto-deactivate products if over limit
      await _checkAndAutoDeactivateProducts();
    });
  }

  @override
  void dispose() {
    // Stop subscription when leaving dashboard
    ref.read(notificationProvider.notifier).stopOrderSubscription();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final tenantAsync = ref.watch(currentTenantProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(user?.subRole == 'staff' ? 'Dashboard Staff' : 'Dashboard Tenant'),
        actions: [
          const NotificationBell(),  // Order notifications
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
            // Phase 5: H-7 Expiry Warning Banner REMOVED
            // Using TenantConsolidatedTrialBanner instead (better educational flow)
            // See _buildTrialNotificationBanners() below
            
            // Phase 3: Free Tier Banner (Blue) - HIDDEN for staff
            // Staff don't manage subscriptions
            if (user?.subRole != 'staff')
              Consumer(
              builder: (context, ref, _) {
                // CRITICAL: Check Business Owner premium, not tenant user
                // Tenants inherit premium from owner
                // Check if in H-7 warning period
                return ref.watch(tenantSubscriptionStatusProvider).when(
                  data: (status) {
                    final now = DateTime.now();
                    
                    // CRITICAL: If BO is premium, tenant inherits premium → hide banner
                    if (!status.isBusinessOwnerFreeTier) {
                      return const SizedBox.shrink();
                    }
                    
                    // Check BO expiry
                    if (status.businessOwnerExpiresAt != null) {
                      final boDaysLeft = status.businessOwnerExpiresAt!.difference(now).inDays;
                      if (boDaysLeft > 0 && boDaysLeft <= 7) {
                        // In H-7 period, hide FreeTierBanner (BO still premium)
                        return const SizedBox.shrink();
                      }
                    }
                    
                    // Check tenant expiry (if tenant has own premium)
                    if (user != null && user.isPremium && user.subscriptionExpiresAt != null) {
                      final tenantDaysLeft = user.subscriptionExpiresAt!.difference(now).inDays;
                      if (tenantDaysLeft > 0 && tenantDaysLeft <= 7) {
                        // In H-7 period, hide FreeTierBanner (tenant still premium)
                        return const SizedBox.shrink();
                      }
                    }
                    
                    // Not in warning period, show FreeTierBanner
                    return FreeTierBanner(
                      onUpgrade: () => showDialog(
                        context: context,
                        builder: (context) => const UpgradeDialog(
                          isBusinessOwner: false,
                        ),
                      ),
                    );
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                );
              },
            ),
            
            // Phase 4: Contact Owner Banner - HIDDEN for staff
            if (user?.subRole != 'staff')
              Consumer(
              builder: (context, ref, _) {
                final subscriptionStatus = ref.watch(tenantSubscriptionStatusProvider);
                return subscriptionStatus.when(
                  data: (status) => ContactOwnerBanner(subscriptionStatus: status),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                );
              },
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
                      user?.fullName ?? 'Tenant',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Chip(
                          label: Text(user?.subRole == 'staff' ? 'staff' : (user?.role ?? '')),
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
            
            // Staff Information Banner
            if (user?.subRole == 'staff')
              Card(
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue.shade700),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Staff hanya dapat melihat dan mengupdate pesanan. Mereka tidak bisa mengelola menu atau staff lainnya.',
                          style: TextStyle(
                            color: Colors.blue.shade900,
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (user?.subRole == 'staff')
              const SizedBox(height: 16),
            
            // D-7 & D-0 Tenant Notification Banners - HIDDEN for staff
            if (user != null && user.subRole != 'staff')
              _buildTrialNotificationBanners(context, ref, user),
            
            // Grace Period Warning - HIDDEN for staff
            if (user != null && user.subRole != 'staff')
              _buildGraceWarningBanner(context, ref, user),
            
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
                // Menu - HIDDEN for staff
                if (user?.subRole != 'staff')
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
                // QR Code - HIDDEN for staff
                if (user?.subRole != 'staff')
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
                                  tenantId: tenant.id,
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
                
                // Laporan - LOCKED for free tier tenants, HIDDEN for staff
                if (user?.subRole != 'staff')
                  Consumer(
                  builder: (context, ref, _) {
                    final subscriptionStatus = ref.watch(tenantSubscriptionStatusProvider);
                    
                return subscriptionStatus.when(
                  data: (status) {
                    // Free tier: Show locked menu
                    if (status.isBusinessOwnerFreeTier) {
                      return Card(
                        child: InkWell(
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (context) => const UpgradeDialog(
                                isBusinessOwner: false,
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade300,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(Icons.analytics, color: Colors.grey.shade600, size: 28),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          const Text(
                                            'Laporan',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Icon(Icons.lock, size: 16, color: Colors.grey.shade600),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Upgrade untuk akses',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }
                    
                    // Premium: Show normal menu
                    return Card(
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const TenantSingleReportPage(),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.orange.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(Icons.analytics, color: Colors.orange, size: 28),
                              ),
                              const SizedBox(width: 16),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Laporan',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'Lihat statistik',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
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
    bool showBadge = false,
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
              Stack(
                clipBehavior: Clip.none,
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
                  // Warning badge
                  if (showBadge)
                    Positioned(
                      right: -4,
                      top: -4,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade600,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(
                          Icons.warning_amber,
                          color: Colors.white,
                          size: 14,
                        ),
                      ),
                    ),
                ],
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

  /// Build grace warning banner (fetch BO info via tenant)
  static Widget _buildGraceWarningBanner(
    BuildContext context,
    WidgetRef ref,
    dynamic user,
  ) {
    final tenantId = user.tenantId;
if (kDebugMode) print('🔍 [TenantWarning] User tenantId: $tenantId');
    if (tenantId == null) {
  if (kDebugMode) print('❌ [TenantWarning] No tenantId found');
      return const SizedBox.shrink();
    }

    return FutureBuilder(
      future: _fetchTenant(ref, tenantId),
      builder: (context, tenantSnapshot) {
        if (!tenantSnapshot.hasData) {
      if (kDebugMode) print('⏳ [TenantWarning] Waiting for tenant data...');
          return const SizedBox.shrink();
        }
        
        final tenant = tenantSnapshot.data;
    if (kDebugMode) print('🏪 [TenantWarning] Tenant fetched: ${tenant?.name}');
        if (tenant == null) {
      if (kDebugMode) print('❌ [TenantWarning] Tenant is null');
          return const SizedBox.shrink();
        }
        
        final ownerId = tenant.ownerId;
    if (kDebugMode) print('👤 [TenantWarning] Owner ID: $ownerId');
        if (ownerId == null) {
      if (kDebugMode) print('❌ [TenantWarning] Owner ID is null');
          return const SizedBox.shrink();
        }
        
        return FutureBuilder(
          future: _fetchBusinessOwner(ref, ownerId),
          builder: (context, boSnapshot) {
            if (!boSnapshot.hasData) {
          if (kDebugMode) print('⏳ [TenantWarning] Waiting for BO data...');
              return const SizedBox.shrink();
            }
            
            final bo = boSnapshot.data;
        if (kDebugMode) print('👔 [TenantWarning] BO fetched: ${bo?.fullName}');
            if (bo == null) {
          if (kDebugMode) print('❌ [TenantWarning] BO is null');
              return const SizedBox.shrink();
            }
            
            final gracePeriodService = ref.read(gracePeriodServiceProvider);
            final isInGrace = gracePeriodService.isInGracePeriod(bo);
        if (kDebugMode) print('⚠️ [TenantWarning] BO in grace period: $isInGrace');
            if (!isInGrace) {
          if (kDebugMode) print('✅ [TenantWarning] BO not in grace, no banner needed');
              return const SizedBox.shrink();
            }
            
            final daysRemaining = gracePeriodService.getDaysRemaining(bo);
        if (kDebugMode) print('🎯 [TenantWarning] SHOWING BANNER! Days remaining: $daysRemaining');
            
            return Column(
              children: [
                TenantGraceWarningBanner(
                  tenantUser: user,
                  businessOwner: bo,
                  daysRemaining: daysRemaining,
                  onUpgrade: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Fitur upgrade tenant premium coming soon!'),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
              ],
            );
          },
        );
      },
    );
  }

  static Future<dynamic> _fetchTenant(WidgetRef ref, String tenantId) async {
    try {
  if (kDebugMode) print('📡 [TenantWarning] Fetching tenant: $tenantId');
      final databases = ref.read(appwriteDatabasesProvider);
      
      final doc = await databases.getDocument(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.tenantsCollectionId,
        documentId: tenantId,
      );
      
  if (kDebugMode) print('✅ [TenantWarning] Tenant fetch success');
      return TenantModel.fromDocument(doc);
    } catch (e) {
  if (kDebugMode) print('❌ [TenantWarning] Tenant fetch error: $e');
      return null;
    }
  }

  static Future<dynamic> _fetchBusinessOwner(WidgetRef ref, String userId) async {
    try {
  if (kDebugMode) print('📡 [TenantWarning] Fetching BO user: $userId');
      final databases = ref.read(appwriteDatabasesProvider);
      
      final doc = await databases.getDocument(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.usersCollectionId,
        documentId: userId,
      );
      
  if (kDebugMode) print('✅ [TenantWarning] BO fetch success: ${doc.data}');
      return UserModel.fromDocument(doc);
    } catch (e) {
  if (kDebugMode) print('❌ [TenantWarning] BO fetch error: $e');
  if (kDebugMode) print('   Database ID: ${AppwriteConfig.databaseId}');
  if (kDebugMode) print('   Collection ID: ${AppwriteConfig.usersCollectionId}');
  if (kDebugMode) print('   Document ID: $userId');
      return null;
    }
  }

  /// Build D-7 and D-0 Trial Notification Banners (NEW)
  static Widget _buildTrialNotificationBanners(
    BuildContext context,
    WidgetRef ref,
    dynamic user,
  ) {
    final tenantId = user.tenantId;
if (kDebugMode) print('🔍 [TenantTrialBanner] Checking for user: ${user.fullName}, tenantId: $tenantId');
    
    if (tenantId == null) return const SizedBox.shrink();

    return FutureBuilder(
      future: _fetchTenant(ref, tenantId),
      builder: (context, tenantSnapshot) {
        if (!tenantSnapshot.hasData) {
          return const SizedBox.shrink();
        }
        
        final tenant = tenantSnapshot.data;
    if (kDebugMode) print('  > Tenant fetched: ${tenant?.name}, ownerId: ${tenant?.ownerId}');
        
        if (tenant == null) return const SizedBox.shrink();
        
        final ownerId = tenant.ownerId;
        if (ownerId == null) return const SizedBox.shrink();
        
        return FutureBuilder(
          future: _fetchBusinessOwner(ref, ownerId),
          builder: (context, boSnapshot) {
            if (!boSnapshot.hasData) {
              return const SizedBox.shrink();
            }
            
            final ownerUser = boSnapshot.data;
        if (kDebugMode) print('  > Owner fetched: ${ownerUser?.fullName}');
        if (kDebugMode) print('  > Payment Status: ${ownerUser?.paymentStatus}');
        if (kDebugMode) print('  > Expires At: ${ownerUser?.subscriptionExpiresAt}');
            
            if (ownerUser == null) return const SizedBox.shrink();
            
            // Check if owner has active subscription (trial, premium, or active)
            if (ownerUser.paymentStatus != 'trial' && 
                ownerUser.paymentStatus != 'premium' && 
                ownerUser.paymentStatus != 'active') {
          if (kDebugMode) print('  > Not in trial/premium, skipping banner');
              return const SizedBox.shrink();
            }
            
            // Calculate days until trial expiry
            if (ownerUser.subscriptionExpiresAt == null) {
              return const SizedBox.shrink();
            }
            
            final now = DateTime.now();
            final expiresAt = ownerUser.subscriptionExpiresAt!;
            final daysRemaining = expiresAt.difference(now).inDays;
        if (kDebugMode) print('  > Days remaining: $daysRemaining');
            
            // D-7 to D-0: Show consolidated educational banner
            if (daysRemaining >= 0 && daysRemaining <= 7) {
          if (kDebugMode) print('  > SHOWING trial banner');
              return Column(
                children: [
                  TenantConsolidatedTrialBanner(
                    ownerUser: ownerUser,
                    tenant: tenant,
                  ),
                  const SizedBox(height: 16),
                ],
              );
            } else {
          if (kDebugMode) print('  > Days remaining $daysRemaining outside range [0, 7]');
            }
            
            // D-0 or after: Check if selected or not
            if (daysRemaining < 0 || (daysRemaining == 0 && ownerUser.selectionSubmittedAt != null)) {
              // Check if current tenant is in selected list
              final currentTenantId = tenantId;
              final selectedIds = ownerUser.selectedTenantIds ?? [];
              final isSelected = selectedIds.contains(currentTenantId);
              
              return Column(
                children: [
                  if (isSelected)
                    TenantSelectedBanner()
                  else
                    TenantNotSelectedBanner(ownerUser: ownerUser),
                  const SizedBox(height: 16),
                ],
              );
            }
            
            return const SizedBox.shrink();
          },
        );
      },
    );
  }
  
  /// Check and auto-deactivate products if over limit
  /// Triggered when tenant owner OR staff logs in
  Future<void> _checkAndAutoDeactivateProducts() async {
    final user = ref.read(authProvider).user;
    if (user?.tenantId == null) return;
    
    // IMPORTANT: Only auto-deactivate for tenant owner OR staff
    // BO viewing tenant products should not trigger auto-deactivation
    // This prevents permission errors and ensures auto-deactivation happens
    // when the actual tenant team logs in after BO downgrade
    if (user?.role != 'tenant' && user?.subRole != 'staff') {
  if (kDebugMode) print('⏭️ [AUTO-DEACTIVATE] Skipped - User is not tenant team (role: ${user?.role}, sub_role: ${user?.subRole})');
      return;
    }
    
    final tenantId = user!.tenantId!;
    
    // Get subscription status and products
    try {
      final subscriptionStatus = await ref.read(tenantSubscriptionStatusProvider.future);
      final productsState = ref.read(tenantProductsProvider(tenantId));
      
      // Check if over limit
      final activeProducts = productsState.products.where((p) => p.isAvailable).toList();
      final activeCount = activeProducts.length;
      
      if (activeCount <= subscriptionStatus.productLimit) {
    if (kDebugMode) print('✅ [AUTO-DEACTIVATE] Not needed - Products within limit ($activeCount/${subscriptionStatus.productLimit})');
        return;
      }
      
      // AUTO-DEACTIVATE excess products (random pick)
  if (kDebugMode) print('🔴 [AUTO-DEACTIVATE] Over limit! Active: $activeCount, Limit: ${subscriptionStatus.productLimit}');
      final excessCount = activeCount - subscriptionStatus.productLimit;
  if (kDebugMode) print('🔴 [AUTO-DEACTIVATE] Need to deactivate: $excessCount products');
      
      // Shuffle and pick random products to deactivate
      final shuffled = List.from(activeProducts)..shuffle();
      final toDeactivate = shuffled.take(excessCount).toList();
      
  if (kDebugMode) print('🔴 [AUTO-DEACTIVATE] Deactivating products:');
      for (var product in toDeactivate) {
    if (kDebugMode) print('   • ${product.name} (${product.id})');
        await ref
            .read(tenantProductsProvider(tenantId).notifier)
            .toggleProductAvailability(product.id, false);
      }
      
  if (kDebugMode) print('✅ [AUTO-DEACTIVATE] Complete! Deactivated $excessCount products');
      
      // Show notification
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '🔴 $excessCount produk telah dinonaktifkan otomatis karena melebihi limit ($activeCount → ${subscriptionStatus.productLimit})',
            ),
            backgroundColor: Colors.orange.shade700,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Lihat',
              textColor: Colors.white,
              onPressed: () {
                // Navigate to Product Management
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProductManagementPage(),
                  ),
                );
              },
            ),
          ),
        );
      }
    } catch (e) {
  if (kDebugMode) print('❌ [AUTO-DEACTIVATE] Error: $e');
    }
  }

}

