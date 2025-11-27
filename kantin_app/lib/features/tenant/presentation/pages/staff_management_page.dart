import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_app/features/auth/providers/auth_provider.dart';
import 'package:kantin_app/shared/models/user_model.dart';
import 'package:kantin_app/shared/models/permission_service.dart';
import '../providers/staff_provider.dart';
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
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(staffProvider.notifier).refresh(),
            tooltip: 'Refresh',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddStaffDialog(context),
        icon: const Icon(Icons.person_add),
        label: const Text('Tambah Staff'),
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
                staff.fullName?.substring(0, 1).toUpperCase() ?? '?',
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
            trailing: IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: () {
                // TODO: Show staff options (delete, edit, etc)
              },
            ),
          ),
        );
      },
    );
  }

  Future<void> _showAddStaffDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => const AddStaffDialog(),
    );

    // Refresh staff list if staff was added
    if (result == true && mounted) {
      ref.read(staffProvider.notifier).refresh();
    }
  }
}
