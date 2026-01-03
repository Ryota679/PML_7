import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/user_model.dart';
import '../../../shared/models/tenant_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/tenant_provider.dart';
import '../providers/tenant_user_provider.dart';
import '../providers/grace_period_provider.dart';
import 'widgets/assign_user_dialog.dart';
import 'widgets/tenant_user_card.dart';

/// Page for managing tenant users (Business Owner)
/// 
/// Phase 3 Enforcement Status:
/// - Create User: ✅ BLOCKED (FAB removed, no create action)
/// - Assign User: ✅ BLOCKED (no assign action in UI)
/// - Delete User: ✅ ALLOWED (free tier can delete)
/// - Edit/Toggle: ⚠️ Currently allowed (consider blocking for free tier)
class TenantUserManagementPage extends ConsumerStatefulWidget {
  final bool isSelectionMode;
  
  const TenantUserManagementPage({
    super.key,
    this.isSelectionMode = false,
  });

  @override
  ConsumerState<TenantUserManagementPage> createState() =>
      _TenantUserManagementPageState();
}

class _TenantUserManagementPageState
    extends ConsumerState<TenantUserManagementPage> {
  // Selection mode state
  final Map<String, String> _selectedUsers = {}; // Map<tenantId, userId>
  
  // Filter state
  String? _selectedTenantId; // null = show all
  
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
        title: Text(widget.isSelectionMode 
            ? 'Pilih User yang Tetap Aktif' 
            : 'Kelola User Tenant'),
        // NEW: Show active user count badge
        bottom: !widget.isSelectionMode ? PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Consumer(
            builder: (context, ref, _) {
              final userState = ref.watch(myTenantUsersProvider);
              final authUser = ref.watch(authProvider).user;
              
              if (authUser == null || userState.users.isEmpty) return const SizedBox.shrink();
              
              // Filter by selected tenant if applicable
              final relevantUsers = _selectedTenantId == null
                  ? userState.users.where((u) => u.subRole == null || u.subRole!.isEmpty).toList()
                  : userState.users.where((u) => 
                      u.tenantId == _selectedTenantId && 
                      (u.subRole == null || u.subRole!.isEmpty)
                    ).toList();
              
              final activeCount = relevantUsers.where((u) => u.isActive).length;
              final totalCount = relevantUsers.length;
              final limit = authUser.isFreeTier ? 1 : 999;
              
              final isAtLimit = authUser.isFreeTier && activeCount >= limit;
              
              // Show tenant name if filtered
              final tenantName = _selectedTenantId != null
                  ? ref.watch(myTenantsProvider).tenants
                      .firstWhere((t) => t.id == _selectedTenantId, orElse: () => null as dynamic)
                      ?.name
                  : null;
              
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
                        tenantName != null
                            ? '$tenantName: $activeCount/${authUser.isFreeTier ? limit : '∞'} Active'
                            : '$totalCount Users ($activeCount active)',
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
          ),
        ) : null,
        actions: [
          if (widget.isSelectionMode)
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _selectedUsers.isNotEmpty 
                  ? () => _saveSelection(context)
                  : null,
              tooltip: 'Simpan Pilihan',
            )
          else
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                ref.read(myTenantUsersProvider.notifier).loadTenantUsers();
              },
              tooltip: 'Refresh',
            ),
        ],
      ),
      body: widget.isSelectionMode
          ? _buildSelectionBody(userState, tenantsState.tenants)
          : Column(
              children: [
                // Tenant filter tabs
                if (!widget.isSelectionMode && tenantsState.tenants.isNotEmpty)
                  _buildTenantTabs(tenantsState.tenants),
                // User list
                Expanded(
                  child: _buildBody(userState, tenantsState.tenants),
                ),
              ],
            ),
      // FAB: Show for premium BO, hide for free tier
      floatingActionButton: widget.isSelectionMode 
          ? null 
          : Consumer(
              builder: (context, ref, _) {
                final user = ref.watch(authProvider).user;
                
                // Show FAB if BO is premium (not free tier)
                if (user != null && !user.isFreeTier) {
                  return FloatingActionButton.extended(
                    onPressed: () => _showAssignUserDialog(context),
                    icon: const Icon(Icons.person_add),
                    label: const Text('Tambah User'),
                  );
                }
                
                // Hide for free tier
                return const SizedBox.shrink();
              },
            ),
    );
  }

  /// Build tenant filter tabs
  Widget _buildTenantTabs(List tenants) {
    final tenantList = tenants.cast<TenantModel>();
    
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: tenantList.map((tenant) {
          final isSelected = _selectedTenantId == tenant.id;
          
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              selected: isSelected,
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(tenant.type.icon, style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  Text(
                    tenant.name,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? Colors.white : Colors.grey.shade300,
                    ),
                  ),
                ],
              ),
              onSelected: (selected) {
                setState(() {
                  _selectedTenantId = selected ? tenant.id : null;
                });
              },
              selectedColor: Colors.blue.shade700,
              checkmarkColor: Colors.white,
              backgroundColor: Colors.grey.shade800,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.grey.shade300,
              ),
              side: BorderSide(
                color: isSelected ? Colors.blue.shade700 : Colors.grey.shade600,
                width: isSelected ? 2 : 1,
              ),
            ),
          );
        }).toList(),
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

    // Filter users by selected tenant
    final filteredUsers = _selectedTenantId == null
        ? state.users
        : state.users.where((u) => u.tenantId == _selectedTenantId).toList();

    if (filteredUsers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Tidak ada user di tenant ini',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
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
        itemCount: filteredUsers.length,
        itemBuilder: (context, index) {
          final user = filteredUsers[index];
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

  /// Show upgrade dialog when trying to activate disabled user
  void _showUpgradeDialog(BuildContext context, dynamic tenant) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.block, color: Colors.red, size: 28),
            SizedBox(width: 12),
            Text('User Limit Reached'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Free tier: Max 1 user per tenant',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 4),
            Text(
              'Tenant "${tenant?.name ?? 'Unknown'}" sudah memiliki 1 user aktif.',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 20),
            const Text(
              'Upgrade to Premium untuk:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...[
              'Unlimited users per tenant',
              'Unlimited tenants',
              'Full analytics & reports',
            ].map((benefit) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 20),
                  const SizedBox(width: 12),
                  Expanded(child: Text(benefit)),
                ],
              ),
            )),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.purple.shade600, Colors.purple.shade400],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.star, color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Business Owner Premium',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Rp 149.000/bulan',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
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
                  content: Text('Fitur upgrade coming soon!'),
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
    // NEW: Validate free tier limits before activation
    if (isActive) {
      final authUser = ref.read(authProvider).user;
      if (authUser != null && authUser.isFreeTier) {
        // Count currently active tenant users for this tenant
        final allUsers = ref.read(myTenantUsersProvider).users;
        final activeUsersInTenant = allUsers.where((u) => 
          u.tenantId == user.tenantId && 
          u.isActive && 
          (u.subRole == null || u.subRole!.isEmpty) // Tenant users only, not staff
        ).length;
        
        final limit = 1; // Free tier: 1 active user per tenant
        
        if (activeUsersInTenant >= limit) {
          // Show upgrade dialog
          if (mounted) {
            _showUpgradeDialog(context, null);
          }
          return; // Don't activate
        }
      }
    }
    
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

  // ===== Selection Mode Methods =====
  
  /// Build selection mode body (grouped by tenant with radio buttons)
  Widget _buildSelectionBody(TenantUserState userState, List tenants) {
    if (userState.isLoading && userState.users.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    // Group users by tenant (only tenants with >1 user)
    final groupedUsers = <String, List<UserModel>>{};
    for (final user in userState.users) {
      if (user.tenantId != null) {
        groupedUsers.putIfAbsent(user.tenantId!, () => []).add(user);
      }
    }

    // Filter to only show tenants with >1 user
    final tenantsWithMultipleUsers = groupedUsers.entries
        .where((entry) => entry.value.length > 1)
        .toList();

    if (tenantsWithMultipleUsers.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green.shade400, Colors.green.shade600],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.check_circle,
                  size: 64,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Tidak ada tenant dengan lebih dari 1 user',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Semua tenant sudah sesuai dengan limit free tier.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Info banner - IMPROVED CONTRAST
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade700, Colors.blue.shade600],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.info_outline,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  'Pilih 1 user per tenant yang akan tetap aktif. User lain akan dinonaktifkan.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        
        // Tenants with multiple users
        ...tenantsWithMultipleUsers.map((entry) {
          final tenantId = entry.key;
          final users = entry.value;
          final tenant = tenants.cast<TenantModel?>().firstWhere(
            (t) => t?.id == tenantId,
            orElse: () => null,
          );

          return Card(
            margin: const EdgeInsets.only(bottom: 20),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tenant header - IMPROVED
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        if (tenant != null)
                          Text(
                            tenant.type.icon,
                            style: const TextStyle(fontSize: 24),
                          ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            tenant?.name ?? 'Unknown Tenant',
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // User radio buttons - IMPROVED CONTRAST
                  ...users.map((user) {
                    final isSelected = _selectedUsers[tenantId] == user.id;
                    
                    return InkWell(
                      onTap: () {
                        setState(() {
                          _selectedUsers[tenantId] = user.id!;
                        });
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isSelected 
                              ? Colors.purple.shade50 
                              : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected 
                                ? Colors.purple 
                                : Colors.grey.shade300,
                            width: isSelected ? 2 : 1.5,
                          ),
                          boxShadow: isSelected ? [
                            BoxShadow(
                              color: Colors.purple.withOpacity(0.15),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ] : [],
                        ),
                        child: Row(
                          children: [
                            Radio<String>(
                              value: user.id!,
                              groupValue: _selectedUsers[tenantId],
                              onChanged: (value) {
                                setState(() {
                                  _selectedUsers[tenantId] = value!;
                                });
                              },
                              activeColor: Colors.purple,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user.fullName,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                      color: isSelected 
                                          ? Colors.black87 
                                          : Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    user.email,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isSelected)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.purple.shade600,
                                      Colors.purple.shade500,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.purple.withOpacity(0.3),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.check_circle,
                                      size: 14,
                                      color: Colors.white,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'DIPILIH',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  /// Save user selection and disable others
  Future<void> _saveSelection(BuildContext context) async {
    // Validate all tenants have selection
    final userState = ref.read(myTenantUsersProvider);
    final groupedUsers = <String, List<UserModel>>{};
    for (final user in userState.users) {
      if (user.tenantId != null) {
        groupedUsers.putIfAbsent(user.tenantId!, () => []).add(user);
      }
    }
    final tenantsWithMultipleUsers = groupedUsers.entries
        .where((entry) => entry.value.length > 1)
        .toList();
    
    // Check if all required selections are made
    for (final entry in tenantsWithMultipleUsers) {
      if (!_selectedUsers.containsKey(entry.key)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mohon pilih 1 user untuk setiap tenant'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
    }

    // Get tenant list for display names
    final tenantsState = ref.read(myTenantsProvider);
    
    // Build confirmation message
    final selectedList = <String>[];
    for (final entry in _selectedUsers.entries) {
      final tenant = tenantsState.tenants.cast<TenantModel?>().firstWhere(
        (t) => t?.id == entry.key,
        orElse: () => null,
      );
      final user = userState.users.firstWhere(
        (u) => u.id == entry.value,
        orElse: () => UserModel(
          id: '',
          userId: '',
          username: 'unknown',
          email: '',
          fullName: 'Unknown',
          role: 'tenant',
          isActive: true,
          createdAt: DateTime.now(),
          subscriptionTier: 'free',
        ),
      );
      selectedList.add('${tenant?.type.icon ?? '🏪'} ${tenant?.name ?? 'Unknown'}: ${user.fullName}');
    }

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber, color: Colors.orange, size: 28),
            SizedBox(width: 12),
            Text('Konfirmasi Pilihan'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'User yang akan tetap AKTIF:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 12),
              ...selectedList.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              )),
              const Divider(height: 24),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'PERINGATAN',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      '• User lain akan DINONAKTIFKAN\n'
                      '• Akun yang dinonaktifkan TIDAK BISA LOGIN\n'
                      '• Pilihan ini TIDAK DAPAT DIUBAH',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.black87,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Ya, Simpan & Nonaktifkan'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Show loading
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
            SizedBox(width: 12),
            Text('Menyimpan pilihan...'),
          ],
        ),
        duration: Duration(seconds: 30),
      ),
    );

    // Get grace period service
    final gracePeriodService = ref.read(gracePeriodServiceProvider);
    
    // Get current user (BO)
    final auth = ref.read(authProvider);
    final ownerId = auth.user?.userId;

    if (ownerId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error: Owner ID tidak ditemukan'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // Save choices
    final success = await gracePeriodService.saveUserChoices(
      ownerId,
      _selectedUsers,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ User berhasil dipilih! User lain telah dinonaktifkan.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
        
        // Go back to dashboard
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal menyimpan pilihan'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
