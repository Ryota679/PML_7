import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_app/features/auth/providers/auth_provider.dart';
import 'package:kantin_app/shared/models/user_model.dart';
import 'package:kantin_app/shared/models/permission_service.dart';
import '../providers/staff_provider.dart';
import '../../providers/tenant_subscription_provider.dart';
import '../widgets/add_staff_dialog.dart';

/// Staff Management Page
/// 
/// Page untuk tenant owner mengelola staff accounts
class StaffManagementPage extends ConsumerStatefulWidget {
  const StaffManagementPage({super.key});

  @override
  ConsumerState<StaffManagementPage> createState() => _StaffManagementPageState();
}

class _StaffManagementPageState extends ConsumerState<StaffManagementPage> {
  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final staffAsync = ref.watch(staffProvider);

    // Permission check
    if (!PermissionService.canManageStaff(user)) {
      return Scaffold(
        appBar: AppBar(title: const Text('Akses Ditolak')),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.block, size: 64, color: Colors.red),
              SizedBox(height: 16),
              Text(
                'Hanya Tenant Owner yang dapat mengelola staff',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Staff'),
        // NEW: Show active staff count badge
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Consumer(
            builder: (context, ref, _) {
              final staffAsync = ref.watch(staffProvider);
              final subscriptionStatusAsync = ref.watch(tenantSubscriptionStatusProvider);
              
              return subscriptionStatusAsync.when(
                data: (status) {
                  return staffAsync.when(
                    data: (staffList) {
                      final activeCount = staffList.where((s) => s.isActive).length;
                      final totalCount = staffList.length;
                      final limit = status.isBusinessOwnerFreeTier ? 1 : 999;
                      final isAtLimit = status.isBusinessOwnerFreeTier && activeCount >= limit;
                      
                      return Container(
                        padding: const EdgeInsets.all(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: isAtLimit ? Colors.orange.shade50 : Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isAtLimit ? Colors.orange.shade200 : Colors.blue.shade200,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.people,
                                size: 16,
                                color: isAtLimit ? Colors.orange.shade700 : Colors.blue.shade700,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '$totalCount Staff ($activeCount/${status.isBusinessOwnerFreeTier ? limit : '∞'} Active)',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isAtLimit ? Colors.orange.shade900 : Colors.blue.shade900,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              );
            },
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(staffProvider.notifier).refresh(),
            tooltip: 'Refresh',
          ),
        ],
      ),
      floatingActionButton: Consumer(
        builder: (context, ref, _) {
          final subscriptionStatusAsync = ref.watch(tenantSubscriptionStatusProvider);
          final staffAsync = ref.watch(staffProvider);
          
          return subscriptionStatusAsync.when(
            data: (subscriptionStatus) {
              return staffAsync.when(
                data: (staffList) {
                  // Free tier: 1 staff limit
                  if (subscriptionStatus.isBusinessOwnerFreeTier) {
                    if (staffList.length >= 1) {
                      // At limit - show locked FAB with upgrade prompt
                      return FloatingActionButton.extended(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                '👥 Limit staff tercapai (1/1).\n\nUpgrade ke Premium untuk unlimited staff!',
                              ),
                              backgroundColor: Colors.orange,
                              duration: Duration(seconds: 4),
                            ),
                          );
                        },
                        backgroundColor: Colors.grey,
                        icon: const Icon(Icons.lock),
                        label: const Text('Limit Tercapai'),
                      );
                    }
                  }
                  
                  // Premium or within free tier limit - show normal FAB
                  return FloatingActionButton.extended(
                    onPressed: () => _showAddStaffDialog(context),
                    icon: const Icon(Icons.person_add),
                    label: const Text('Tambah Staff'),
                  );
                },
                loading: () => FloatingActionButton.extended(
                  onPressed: null,
                  icon: const Icon(Icons.person_add),
                  label: const Text('Loading...'),
                ),
                error: (_, __) => FloatingActionButton.extended(
                  onPressed: () => _showAddStaffDialog(context),
                  icon: const Icon(Icons.person_add),
                  label: const Text('Tambah Staff'),
                ),
              );
            },
            loading: () => FloatingActionButton.extended(
              onPressed: null,
              icon: const Icon(Icons.person_add),
              label: const Text('Loading...'),
            ),
            error: (_, __) => FloatingActionButton.extended(
              onPressed: () => _showAddStaffDialog(context),
              icon: const Icon(Icons.person_add),
              label: const Text('Tambah Staff'),
            ),
          );
        },
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(staffProvider.notifier).refresh(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info Card
              Card(
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue.shade700),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Staff hanya dapat melihat dan mengupdate pesanan. Mereka tidak bisa mengelola menu atau staff lainnya.',
                          style: TextStyle(color: Colors.blue.shade900),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Staff List Header
              Row(
                children: [
                  Text(
                    'Daftar Staff',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const Spacer(),
                  staffAsync.when(
                    data: (staffList) => Chip(
                      label: Text('${staffList.length} Staff'),
                      avatar: const Icon(Icons.people, size: 16),
                    ),
                    loading: () => const Chip(
                      label: Text('...'),
                      avatar: Icon(Icons.people, size: 16),
                    ),
                    error: (_, __) => const Chip(
                      label: Text('0 Staff'),
                      avatar: Icon(Icons.people, size: 16),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Staff List
              staffAsync.when(
                data: (staffList) => _buildStaffList(staffList),
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (error, stack) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        const Icon(Icons.error_outline, size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(
                          'Error: $error',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.red),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => ref.read(staffProvider.notifier).refresh(),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStaffList(List<UserModel> staffList) {
    if (staffList.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            children: [
              Icon(Icons.people_outline, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'Belum ada staff',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              SizedBox(height: 8),
              Text(
                'Tap tombol "Tambah Staff" untuk membuat akun staff',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: staffList.length,
      itemBuilder: (context, index) {
        final staff = staffList[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blue.shade100,
              child: Text(
                staff.fullName.substring(0, 1).toUpperCase() ?? '?',
                style: TextStyle(color: Colors.blue.shade700, fontWeight: FontWeight.bold),
              ),
            ),
            title: Text(
              staff.fullName ?? 'Unknown',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('@${staff.username}'),
                Text(staff.email ?? '', style: const TextStyle(fontSize: 12)),
                if (staff.phone != null) Text(staff.phone!, style: const TextStyle(fontSize: 12)),
              ],
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'toggle') {
                  _toggleStaffStatus(staff, !staff.isActive);
                } else if (value == 'delete') {
                  _confirmDeleteStaff(context, staff);
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'toggle',
                  child: Row(
                    children: [
                      Icon(
                        staff.isActive ? Icons.visibility_off : Icons.check_circle,
                        size: 20,
                        color: staff.isActive ? null : Colors.green,
                      ),
                      const SizedBox(width: 12),
                      Text(staff.isActive ? 'Nonaktifkan' : 'Aktifkan'),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_forever, size: 20, color: Colors.red),
                      SizedBox(width: 12),
                      Text(
                        'Delete Permanent',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Toggle staff active status with free tier validation
  Future<void> _toggleStaffStatus(UserModel staff, bool isActive) async {
    // NEW: Validate free tier limits before activation
    if (isActive) {
      final subscriptionStatus = await ref.read(tenantSubscriptionStatusProvider.future);
      if (subscriptionStatus.isBusinessOwnerFreeTier) {
        // Count currently active staff
        final staffState = ref.read(staffProvider);
        final allStaff = staffState.value ?? [];
        final activeStaffCount = allStaff.where((s) => s.isActive).length;
        
        final limit = 1; // Free tier: 1 active staff
        
        if (activeStaffCount >= limit) {
          // Show upgrade snackbar
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  '👥 Limit staff aktif tercapai (1/1).\n\nUpgrade ke Premium untuk unlimited staff!',
                ),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 4),
              ),
            );
          }
          return; // Don't activate
        }
      }
    }
    
    final success = await ref
        .read(staffProvider.notifier)
        .toggleStaffStatus(staff.id!, isActive);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Status staff diubah menjadi ${isActive ? "Aktif" : "Nonaktif"}'
                : 'Gagal mengubah status staff',
          ),
          backgroundColor: success ? Colors.green : Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _showAddStaffDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => const AddStaffDialog(),
    );

    // Refresh staff list if staff was added
    if (result == true && mounted) {
      ref.read(staffProvider.notifier).refresh();
    }
  }

  void _confirmDeleteStaff(BuildContext context, UserModel staff) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 8),
            Text('Delete Staff Permanently?'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This will PERMANENTLY delete "${staff.fullName}"',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text('• Staff account will be removed'),
            const Text('• Cannot login anymore'),
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
              await _deleteStaffPermanent(staff);
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

  Future<void> _deleteStaffPermanent(UserModel staff) async {
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
              Text('Deleting staff permanently...'),
            ],
          ),
          duration: Duration(seconds: 30),
        ),
      );
    }

    // Get current user ID (tenant owner who is deleting)
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

    // Call delete permanent via staff provider
    final success = await ref
        .read(staffProvider.notifier)
        .deleteStaffPermanent(staff.id!, deletedBy);

    if (mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Staff "${staff.fullName}" deleted permanently!'
                : 'Failed to delete staff',
          ),
          backgroundColor: success ? Colors.green : Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
}
