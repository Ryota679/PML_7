import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/tenant_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/tenant_provider.dart';
import '../utils/tenant_access_helper.dart';
import 'widgets/create_tenant_dialog.dart';
import 'widgets/edit_tenant_dialog.dart';
import 'widgets/tenant_card.dart';
import 'widgets/tenant_upgrade_dialog.dart';
import 'widgets/generate_invitation_dialog_for_tenant.dart';
import 'package:kantin_app/shared/widgets/upgrade_dialog.dart';

/// Page for managing tenants (Business Owner)
class TenantManagementPage extends ConsumerStatefulWidget {
  const TenantManagementPage({super.key});

  @override
  ConsumerState<TenantManagementPage> createState() =>
      _TenantManagementPageState();
}

class _TenantManagementPageState extends ConsumerState<TenantManagementPage> {
  @override
  void initState() {
    super.initState();
    // Load tenants on init
    Future.microtask(() {
      ref.read(myTenantsProvider.notifier).loadTenants();
    });
  }

  @override
  Widget build(BuildContext context) {
    final tenantState = ref.watch(myTenantsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Tenant'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(myTenantsProvider.notifier).loadTenants();
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _buildBody(tenantState),
      floatingActionButton: _buildFloatingActionButton(context),
    );
  }
  
  Widget? _buildFloatingActionButton(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final tenantState = ref.watch(myTenantsProvider);
    
    if (user == null) return null;
    
    
    // Tenant creation is core feature - available for all tiers
    // No limits on tenant count (contract management app)
    
    return FloatingActionButton.extended(
      onPressed: () => _showCreateTenantDialog(context),
      icon: const Icon(Icons.add),
      label: const Text('Tambah Tenant'),
    );
  }

  Widget _buildBody(TenantState state) {
    if (state.isLoading && state.tenants.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (state.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              state.error!,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                ref.read(myTenantsProvider.notifier).loadTenants();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
            ),
          ],
        ),
      );
    }

    if (state.tenants.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.store_outlined,
              size: 100,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Belum ada tenant',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap tombol + untuk menambah tenant pertama',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(myTenantsProvider.notifier).loadTenants();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: state.tenants.length,
        itemBuilder: (context, index) {
          final tenant = state.tenants[index];
          final user = ref.read(authProvider).user;
          final isPremium = user?.isPremium ?? false;
          
          return TenantCard(
            tenant: tenant,
            onEdit: () => _showEditTenantDialog(context, tenant),
            onDelete: () => _confirmDeleteTenant(context, tenant),
            onToggleStatus: (isActive) => _toggleTenantStatus(tenant, isActive),
            onShowUpgradeInfo: () => _showUpgradeInfoDialog(context, tenant),
            onGenerateCode: () => _showGenerateCodeDialog(context, tenant),
            isPremiumUser: isPremium,
          );
        },
      ),
    );
  }

  void _showCreateTenantDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const CreateTenantDialog(),
    );
  }

  void _showEditTenantDialog(BuildContext context, TenantModel tenant) {
    // Check access before allowing edit
    final user = ref.read(authProvider).user;
    
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal memuat data user'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    // Phase 3: Free tier (trial expired) cannot edit
    if (user.isFreeTier) {
      _showPhase3UpgradeDialog(context);
      return;
    }
    
    // Free tier can only edit SELECTED tenants
    if (user.isFree && tenant.selectedForFreeTier != true) {
      _showFreeTierNonSelectedDialog(context, tenant);
      return;
    }
    
    // Check if user has full access to this tenant
    final hasAccess = TenantAccessHelper.hasFullAccess(
      businessOwner: user,
      tenant: tenant,
    );
    
    if (!hasAccess) {
      // Show upgrade dialog instead of edit dialog
      showDialog(
        context: context,
        builder: (context) => TenantUpgradeDialog(
          user: user,
          tenant: tenant,
        ),
      );
      return;
    }
    
    // Has access - show edit dialog
    showDialog(
      context: context,
      builder: (context) => EditTenantDialog(tenant: tenant),
    );
  }
  
  void _showGenerateCodeDialog(BuildContext context, TenantModel tenant) {
    // Import invitation dialog here
    showDialog(
      context: context,
      builder: (context) => GenerateInvitationDialogForTenant(tenantId: tenant.id),
    );
  }
  
  void _showUpgradeInfoDialog(BuildContext context, TenantModel tenant) {
    final user = ref.read(authProvider).user;
    
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal memuat data user'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    // Directly show upgrade dialog
    showDialog(
      context: context,
      builder: (context) => TenantUpgradeDialog(
        user: user,
        tenant: tenant,
      ),
    );
  }
  
  void _showFreeTierNonSelectedDialog(BuildContext context, TenantModel tenant) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.lock_outline, color: Colors.orange.shade700),
            const SizedBox(width: 12),
            const Expanded(
              child: Text('Tenant Tidak Dipilih'),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tenant "${tenant.name}" tidak termasuk 2 tenant aktif Anda (free tier).',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
            const Text(
              'Untuk mengelola tenant ini:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildUpgradeOptionRow(
              icon: Icons.workspace_premium,
              color: Colors.purple,
              title: 'Upgrade ke Premium',
              subtitle: 'Rp 149k/bulan - Unlimited tenants',
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
              _showUpgradeInfoDialog(context, tenant);
            },
            child: const Text('Lihat Opsi Upgrade'),
          ),
        ],
      ),
    );
  }
  
  void _showFreeTierViewOnlyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.lock_outline, color: Colors.orange.shade700),
            const SizedBox(width: 12),
            const Expanded(
              child: Text('Mode View-Only'),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Akun Free Tier hanya bisa melihat data tenant.',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
            const Text(
              'Untuk mengelola tenant (Create/Edit):',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildUpgradeOptionRow(
              icon: Icons.workspace_premium,
              color: Colors.purple,
              title: 'Upgrade ke Premium',
              subtitle: 'Rp 149k/bulan - Unlimited tenants',
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Anda masih bisa menghapus tenant',
                      style: TextStyle(fontSize: 13),
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
            child: const Text('Upgrade Sekarang'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteTenant(BuildContext context, TenantModel tenant) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Tenant?'),
        content: Text(
          'Apakah Anda yakin ingin menghapus "${tenant.name}"?\n\n'
          'Semua data produk dan kategori tenant ini juga akan terhapus.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteTenant(tenant);
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteTenant(TenantModel tenant) async {
    final success = await ref
        .read(myTenantsProvider.notifier)
        .deleteTenant(tenant.id);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Tenant "${tenant.name}" berhasil dihapus'
                : 'Gagal menghapus tenant',
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  Future<void> _toggleTenantStatus(TenantModel tenant, bool isActive) async {
    final user = ref.read(authProvider).user;
    
    // Check if trying to activate a non-selected tenant
    if (isActive && 
        tenant.selectedForFreeTier == false && 
        user != null && 
        !user.isPremium &&
        !tenant.hasPremiumSubscription) {
      // Show warning dialog
      _showActivationWarning(context, tenant);
      return;
    }
    
    // Proceed with toggle
    final success = await ref
        .read(myTenantsProvider.notifier)
        .toggleStatus(tenant.id, isActive);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Status tenant diubah menjadi ${isActive ? "Aktif" : "Nonaktif"}'
                : 'Gagal mengubah status tenant',
          ),
          backgroundColor: success ? Colors.green : Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
  
  void _showActivationWarning(BuildContext context, TenantModel tenant) {
    final user = ref.read(authProvider).user;
    if (user == null) return;
    
    
    // Grace period swap removed - always false
    final hasSwap = false;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700),
            const SizedBox(width: 12),
            const Expanded(
              child: Text('Tenant Tidak Dipilih'),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tenant "${tenant.name}" tidak termasuk dalam 2 tenant aktif Anda (free tier).',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
            const Text(
              'Untuk mengaktifkan tenant ini, Anda perlu:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            
            // Option 1: Use Swap (if available)
            if (hasSwap) ...[
              _buildUpgradeOptionRow(
                icon: Icons.swap_horiz,
                color: Colors.blue,
                title: 'Gunakan Swap Opportunity',
                subtitle: 'Tukar 2 tenant aktif Anda (gratis)',
              ),
              const SizedBox(height: 8),
            ],
            
            // Option 2: Upgrade BO to Premium
            _buildUpgradeOptionRow(
              icon: Icons.workspace_premium,
              color: Colors.purple,
              title: 'Upgrade Business Owner',
              subtitle: 'Rp 149k/bulan - Unlimited tenants',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              // Show full upgrade dialog
              _showUpgradeInfoDialog(context, tenant);
            },
            child: const Text('Lihat Opsi Upgrade'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildUpgradeOptionRow({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  // ===== Phase 3: Upgrade Dialog =====
  
  /// Show Phase 3 upgrade dialog for free tier (trial expired) users
  void _showPhase3UpgradeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const UpgradeDialog(
        isBusinessOwner: true,
      ),
    );
  }
}
