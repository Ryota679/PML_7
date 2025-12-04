import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/user_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/tenant_provider.dart';
import '../providers/tenant_user_provider.dart';
import 'widgets/assign_user_dialog.dart';
import 'widgets/tenant_user_card.dart';

/// Page for managing tenant users (Business Owner)
class TenantUserManagementPage extends ConsumerStatefulWidget {
  const TenantUserManagementPage({super.key});

  @override
  ConsumerState<TenantUserManagementPage> createState() =>
      _TenantUserManagementPageState();
}

class _TenantUserManagementPageState
    extends ConsumerState<TenantUserManagementPage> {
  @override
  void initState() {
    super.initState();
    // Load tenant users on init
    Future.microtask(() {
      ref.read(myTenantUsersProvider.notifier).loadTenantUsers();
      ref.read(myTenantsProvider.notifier).loadTenants();
    });
  }

  @override
  Widget build(BuildContext context) {
    final userState = ref.watch(myTenantUsersProvider);
    final tenantsState = ref.watch(myTenantsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola User Tenant'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(myTenantUsersProvider.notifier).loadTenantUsers();
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _buildBody(userState, tenantsState.tenants),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAssignUserDialog(context),
        icon: const Icon(Icons.person_add),
        label: const Text('Assign User'),
      ),
    );
  }

  Widget _buildBody(TenantUserState state, List tenants) {
    if (state.isLoading && state.users.isEmpty) {
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
                ref.read(myTenantUsersProvider.notifier).loadTenantUsers();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
            ),
          ],
        ),
      );
    }

    if (state.users.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 100,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Belum ada user tenant',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap tombol + untuk assign user ke tenant',
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(myTenantUsersProvider.notifier).loadTenantUsers();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: state.users.length,
        itemBuilder: (context, index) {
          final user = state.users[index];
          // Find tenant for this user, safely handle if not found
          final tenant = tenants.cast<dynamic>().firstWhere(
            (t) => t.id == user.tenantId,
            orElse: () => null,
          );
          
          return TenantUserCard(
            user: user,
            tenant: tenant,
            onRemove: () => _confirmRemoveUser(context, user),
            onDelete: () => _confirmDeleteUser(context, user),
            onToggleStatus: (isActive) => _toggleUserStatus(user, isActive),
          );
        },
      ),
    );
  }

  void _showAssignUserDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const AssignUserDialog(),
    );
  }

  void _confirmRemoveUser(BuildContext context, UserModel user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove User?'),
        content: Text(
          'Apakah Anda yakin ingin remove "${user.fullName}" dari tenant?\n\n'
          'User tidak akan bisa lagi mengakses data tenant.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              await _removeUser(user);
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  Future<void> _removeUser(UserModel user) async {
    final success = await ref
        .read(myTenantUsersProvider.notifier)
        .removeUserFromTenant(user.id!);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'User "${user.fullName}" berhasil di-remove'
                : 'Gagal remove user',
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  void _confirmDeleteUser(BuildContext context, UserModel user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 8),
            Text('Delete User Permanently?'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This will PERMANENTLY delete "${user.fullName}" and ALL related data:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text('• User account (cannot login anymore)'),
            if (user.role == 'tenant') ...[
              const Text('• All staff users'),
              const Text('• All products'),
              const Text('• All orders'),
            ],
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: const Row(
                children: [
                  Icon(Icons.error, color: Colors.red, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This action CANNOT be undone!',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
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
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteUserPermanent(user);
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('DELETE PERMANENT'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteUserPermanent(UserModel user) async {
    // Show loading
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              ),
              SizedBox(width: 12),
              Text('Deleting user permanently...'),
            ],
          ),
          duration: Duration(seconds: 30),
        ),
      );
    }

    // Get current user ID (deletedBy)
    final auth = ref.read(authProvider);
    final deletedBy = auth.user?.userId ?? '';

    if (deletedBy.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error: Unable to get current user ID'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // Call delete permanent
    final success = await ref
        .read(myTenantUsersProvider.notifier)
        .deleteUserPermanent(user.id!, deletedBy);

    if (mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'User "${user.fullName}" deleted permanently!'
                : 'Failed to delete user',
          ),
          backgroundColor: success ? Colors.green : Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _toggleUserStatus(UserModel user, bool isActive) async {
    final success = await ref
        .read(myTenantUsersProvider.notifier)
        .toggleUserStatus(user.id!, isActive);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Status user diubah menjadi ${isActive ? "Aktif" : "Nonaktif"}'
                : 'Gagal mengubah status user',
          ),
          backgroundColor: success ? Colors.green : Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
}
