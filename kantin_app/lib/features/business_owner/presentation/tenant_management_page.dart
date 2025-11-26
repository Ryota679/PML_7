import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/tenant_model.dart';
import '../providers/tenant_provider.dart';
import 'widgets/create_tenant_dialog.dart';
import 'widgets/edit_tenant_dialog.dart';
import 'widgets/tenant_card.dart';

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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateTenantDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Tambah Tenant'),
      ),
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
          return TenantCard(
            tenant: tenant,
            onEdit: () => _showEditTenantDialog(context, tenant),
            onDelete: () => _confirmDeleteTenant(context, tenant),
            onToggleStatus: (isActive) => _toggleTenantStatus(tenant, isActive),
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
    showDialog(
      context: context,
      builder: (context) => EditTenantDialog(tenant: tenant),
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
}
