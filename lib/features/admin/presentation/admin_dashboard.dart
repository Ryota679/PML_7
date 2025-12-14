import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_app/features/admin/providers/registration_provider.dart';
import 'package:kantin_app/features/admin/providers/user_management_provider.dart';
import 'package:kantin_app/features/auth/providers/auth_provider.dart';
import 'package:kantin_app/shared/models/registration_request_model.dart';
import 'package:kantin_app/shared/models/user_model.dart';
import 'package:kantin_app/shared/widgets/loading_widget.dart';
import 'package:kantin_app/features/admin/presentation/populate_tenant_codes_page.dart';

/// Admin Dashboard
/// 
/// Dashboard untuk System Admin mengelola pendaftaran Business Owner
class AdminDashboard extends ConsumerStatefulWidget {
  const AdminDashboard({super.key});

  @override
  ConsumerState<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends ConsumerState<AdminDashboard> {
  String _selectedTab = 'registrations'; // 'registrations' or 'users'
  String _selectedFilter = 'pending';

  @override
  void initState() {
    super.initState();
    // Load pending requests on init
    Future.microtask(() {
      ref.read(registrationRequestsProvider.notifier).loadPendingRequests();
      ref.read(userManagementProvider.notifier).loadBusinessOwners();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final registrationState = ref.watch(registrationRequestsProvider);
    final userManagementState = ref.watch(userManagementProvider);
    final pendingCount = ref.watch(pendingRequestsCountProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          // Pending count badge
          if (pendingCount > 0)
            Center(
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '$pendingCount Pending',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          // Logout button
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _handleLogout(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Main tabs (Registrations vs Users)
          _buildMainTabs(),
          
          // Filter tabs or content based on selected tab
          if (_selectedTab == 'registrations') ...[
            _buildFilterTabs(),
            
            // Registration Content
            Expanded(
              child: registrationState.isLoading
                  ? const LoadingWidget(message: 'Memuat data...')
                  : registrationState.error != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                            const Icon(Icons.error_outline, size: 48, color: Colors.red),
                            const SizedBox(height: 16),
                            Text(
                              'Error: ${registrationState.error}',
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _refreshData,
                              child: const Text('Coba Lagi'),
                            ),
                          ],
                        ),
                      )
                    : registrationState.requests.isEmpty
                        ? _buildEmptyState()
                        : _buildRequestsList(registrationState.requests),
            ),
          ] else if (_selectedTab == 'users') ...[
            // Users Management Content
            Expanded(
              child: userManagementState.isLoading
                  ? const LoadingWidget(message: 'Memuat data users...')
                  : userManagementState.error != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error_outline, size: 48, color: Colors.red),
                              const SizedBox(height: 16),
                              Text(
                                'Error: ${userManagementState.error}',
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () {
                                  ref.read(userManagementProvider.notifier).loadBusinessOwners();
                                },
                                child: const Text('Coba Lagi'),
                              ),
                            ],
                          ),
                        )
                      : userManagementState.users.isEmpty
                          ? _buildEmptyUsersState()
                          : _buildUsersList(userManagementState.users),
            ),
          ] else ...[
            // Utilities Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Card(
                      child: ListTile(
                        leading: const CircleAvatar(
                          child: Icon(Icons.qr_code),
                        ),
                        title: const Text('Populate Tenant Codes'),
                        subtitle: const Text('Generate QR codes untuk semua tenant'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const PopulateTenantCodesPage(),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMainTabs() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: Border(
          bottom: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildMainTabButton(
              label: 'Registrasi',
              icon: Icons.person_add,
              value: 'registrations',
            ),
          ),
          Expanded(
            child: _buildMainTabButton(
              label: 'Kelola Users',
              icon: Icons.people,
              value: 'users',
            ),
          ),
          Expanded(
            child: _buildMainTabButton(
              label: 'Utilities',
              icon: Icons.settings,
              value: 'utilities',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainTabButton({
    required String label,
    required IconData icon,
    required String value,
  }) {
    final isSelected = _selectedTab == value;
    
    return InkWell(
      onTap: () {
        setState(() {
          _selectedTab = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? Theme.of(context).colorScheme.primary : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterTabs() {
    return Container(
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          _buildFilterChip('pending', 'Pending', Colors.orange),
          const SizedBox(width: 8),
          _buildFilterChip('approved', 'Approved', Colors.green),
          const SizedBox(width: 8),
          _buildFilterChip('rejected', 'Rejected', Colors.red),
          const SizedBox(width: 8),
          _buildFilterChip('all', 'Semua', Colors.blue),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label, Color color) {
    final isSelected = _selectedFilter == value;
    
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = value;
        });
        _refreshData();
      },
      backgroundColor: Colors.grey[200],
      selectedColor: color.withOpacity(0.2),
      checkmarkColor: color,
      labelStyle: TextStyle(
        color: isSelected ? color : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildEmptyState() {
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
            'Tidak ada pendaftaran',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _selectedFilter == 'pending'
                ? 'Belum ada pendaftaran yang menunggu review'
                : 'Tidak ada data untuk filter ini',
            style: TextStyle(
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestsList(List<RegistrationRequestModel> requests) {
    return RefreshIndicator(
      onRefresh: () async => _refreshData(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: requests.length,
        itemBuilder: (context, index) {
          final request = requests[index];
          return _buildRequestCard(request);
        },
      ),
    );
  }

  Widget _buildRequestCard(RegistrationRequestModel request) {
    Color statusColor;
    IconData statusIcon;
    
    switch (request.status) {
      case 'approved':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = Colors.orange;
        statusIcon = Icons.pending;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: statusColor.withOpacity(0.2),
                  child: Icon(statusIcon, color: statusColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.fullName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        request.email,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Chip(
                  label: Text(
                    request.statusLabel,
                    style: const TextStyle(fontSize: 12),
                  ),
                  backgroundColor: statusColor.withOpacity(0.1),
                  labelStyle: TextStyle(color: statusColor),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
            
            const Divider(height: 24),
            
            // Business info
            _buildInfoRow(Icons.business, 'Bisnis', request.businessName),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.category, 'Jenis', request.businessType),
            if (request.phone != null) ...[
              const SizedBox(height: 8),
              _buildInfoRow(Icons.phone, 'Telepon', request.phone!),
            ],
            const SizedBox(height: 8),
            _buildInfoRow(
              Icons.access_time,
              'Tanggal',
              _formatDate(request.createdAt),
            ),
            
            // Admin notes (if any)
            if (request.adminNotes != null) ...[
              const Divider(height: 24),
              Text(
                'Catatan Admin:',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                request.adminNotes!,
                style: const TextStyle(fontSize: 14),
              ),
            ],
            
            // Action buttons (only for pending)
            if (request.isPending) ...[
              const Divider(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _handleReject(request),
                      icon: const Icon(Icons.close, size: 18),
                      label: const Text('Tolak'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _handleApprove(request),
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('Setujui'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 14),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _refreshData() {
    if (_selectedFilter == 'pending') {
      ref.read(registrationRequestsProvider.notifier).loadPendingRequests();
    } else if (_selectedFilter == 'all') {
      ref.read(registrationRequestsProvider.notifier).loadAllRequests();
    } else {
      ref.read(registrationRequestsProvider.notifier).loadAllRequests(
        status: _selectedFilter,
      );
    }
  }

  Future<void> _handleApprove(RegistrationRequestModel request) async {
    final result = await _showApproveDialog(context, request);

    if (result == null) return; // User cancelled

    final notes = result['notes'];

    final response = await ref
        .read(registrationRequestsProvider.notifier)
        .approveRequest(
          request.id,
          notes: notes,
        );

    if (!mounted) return;

    if (response != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Pendaftaran ${request.fullName} disetujui!\n'
            'User dapat login menggunakan password yang mereka daftarkan.',
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 5),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal menyetujui pendaftaran'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handleReject(RegistrationRequestModel request) async {
    final reason = await _showNotesDialog(
      context,
      title: 'Tolak Pendaftaran',
      hint: 'Alasan penolakan (wajib)',
      required: true,
    );

    if (reason == null || reason.isEmpty) return;

    final success = await ref
        .read(registrationRequestsProvider.notifier)
        .rejectRequest(request.id, reason);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Pendaftaran ${request.fullName} ditolak'),
          backgroundColor: Colors.orange,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal menolak pendaftaran'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<Map<String, String>?> _showApproveDialog(
    BuildContext context,
    RegistrationRequestModel request,
  ) {
    final notesController = TextEditingController();
    
    return showDialog<Map<String, String>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Setujui Pendaftaran'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Anda akan menyetujui pendaftaran dari:',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              Text(
                '• Nama: ${request.fullName}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('• Email: ${request.email}'),
              Text('• Usaha: ${request.businessName}'),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'User akan menggunakan password yang mereka input saat registrasi',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Catatan (Opsional)',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: notesController,
                decoration: const InputDecoration(
                  hintText: 'Catatan untuk approval',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context, {
                'notes': notesController.text.trim(),
              });
            },
            child: const Text('Setujui'),
          ),
        ],
      ),
    );
  }

  Future<String?> _showNotesDialog(
    BuildContext context, {
    required String title,
    required String hint,
    bool required = false,
  }) {
    final controller = TextEditingController();
    
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            border: const OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              if (required && controller.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Catatan tidak boleh kosong'),
                    duration: Duration(seconds: 2),
                  ),
                );
                return;
              }
              Navigator.pop(context, controller.text.trim());
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyUsersState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Belum ada Business Owner',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsersList(List<UserModel> users) {
    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(userManagementProvider.notifier).loadBusinessOwners();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: users.length,
        itemBuilder: (context, index) {
          final user = users[index];
          return _buildUserCard(user);
        },
      ),
    );
  }

  Widget _buildUserCard(UserModel user) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: Text(
                    user.fullName[0].toUpperCase(),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.fullName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        user.email,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        _handleEditUser(user);
                        break;
                      case 'reset_password':
                        _handleResetPassword(user);
                        break;
                      case 'delete':
                        _handleDeleteUser(user);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 20),
                          SizedBox(width: 8),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'reset_password',
                      child: Row(
                        children: [
                          Icon(Icons.lock_reset, size: 20),
                          SizedBox(width: 8),
                          Text('Reset Password'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 20, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Hapus', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (user.phone != null) ...[
              Row(
                children: [
                  const Icon(Icons.phone, size: 16),
                  const SizedBox(width: 8),
                  Text(user.phone!),
                ],
              ),
              const SizedBox(height: 4),
            ],
            Row(
              children: [
                const Icon(Icons.badge, size: 16),
                const SizedBox(width: 8),
                Text('Role: ${user.role}'),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  user.isActive ? Icons.check_circle : Icons.cancel,
                  size: 16,
                  color: user.isActive ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Text(
                  'Status: ${user.isActive ? "Aktif" : "Nonaktif"}',
                  style: TextStyle(
                    color: user.isActive ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            if (user.createdAt != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 16),
                  const SizedBox(width: 8),
                  Text('Terdaftar: ${_formatDate(user.createdAt!)}'),
                ],
              ),
            ],
            // Contract Info
            const Divider(height: 24),
            Row(
              children: [
                const Icon(Icons.event_available, size: 16, color: Colors.blue),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Masa Kontrak',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (user.contractEndDate != null) ...[
                        Text(
                          _formatDate(user.contractEndDate!),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        _buildContractStatus(user.contractEndDate!),
                      ] else ...[
                        const Text(
                          'Belum diatur',
                          style: TextStyle(
                            color: Colors.orange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _handleAddToken(user),
                  icon: const Icon(Icons.add_circle, size: 20),
                  label: const Text('Tambah Token'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContractStatus(DateTime contractEndDate) {
    final now = DateTime.now();
    final difference = contractEndDate.difference(now);
    final daysRemaining = difference.inDays;

    Color statusColor;
    String statusText;

    if (daysRemaining < 0) {
      statusColor = Colors.red;
      statusText = 'Expired ${daysRemaining.abs()} hari yang lalu';
    } else if (daysRemaining == 0) {
      statusColor = Colors.orange;
      statusText = 'Expired hari ini';
    } else if (daysRemaining <= 7) {
      statusColor = Colors.orange;
      statusText = 'Sisa $daysRemaining hari';
    } else {
      statusColor = Colors.green;
      statusText = 'Sisa $daysRemaining hari';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: statusColor),
      ),
      child: Text(
        statusText,
        style: TextStyle(
          fontSize: 12,
          color: statusColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Future<void> _handleEditUser(UserModel user) async {
    final result = await _showEditUserDialog(context, user);
    
    if (result == null) return;
    
    final success = await ref.read(userManagementProvider.notifier).updateUser(
          documentId: user.id!,
          fullName: result['fullName'] as String,
          phone: result['phone'],
        );
    
    if (!mounted) return;
    
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User berhasil diupdate'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal mengupdate user'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handleResetPassword(UserModel user) async {
    // Show manual instruction dialog instead of API call
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.info_outline, color: Colors.blue),
            SizedBox(width: 8),
            Text('Manual Action Required'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Karena keterbatasan SDK, reset password harus dilakukan manual:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text('1. Buka Appwrite Console:'),
              SelectableText(
                '   https://fra.cloud.appwrite.io',
                style: TextStyle(color: Colors.blue[700]),
              ),
              const SizedBox(height: 8),
              const Text('2. Go to: Auth → Users'),
              const SizedBox(height: 8),
              Text('3. Cari user: ${user.email}'),
              const SizedBox(height: 8),
              const Text('4. Klik "Edit" → Set new password'),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'User Info:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    SelectableText('Name: ${user.fullName}'),
                    SelectableText('Email: ${user.email}'),
                    SelectableText('User ID: ${user.userId}'),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Mengerti'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleAddToken(UserModel user) async {
    final tokenController = TextEditingController(text: '1');
    
    final result = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.token, color: Colors.green),
            SizedBox(width: 8),
            Text('Tambah Token Kontrak'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'User: ${user.fullName}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                'Email: ${user.email}',
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Sistem Token',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      '1 Token = +30 hari masa kontrak\n'
                      '2 Token = +60 hari masa kontrak\n'
                      'dst...',
                      style: TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (user.contractEndDate != null) ...[
                Text(
                  'Kontrak saat ini: ${_formatDate(user.contractEndDate!)}',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8),
              ],
              TextField(
                controller: tokenController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Jumlah Token',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.token),
                  helperText: '1 token = 30 hari',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          FilledButton.icon(
            onPressed: () {
              final tokens = int.tryParse(tokenController.text);
              if (tokens != null && tokens > 0) {
                Navigator.pop(context, tokens);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Masukkan jumlah token yang valid'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            icon: const Icon(Icons.add_circle),
            label: const Text('Tambah Token'),
            style: FilledButton.styleFrom(backgroundColor: Colors.green),
          ),
        ],
      ),
    );
    
    if (result == null) return;
    
    // Calculate new end date
    final now = DateTime.now();
    final currentEndDate = user.contractEndDate ?? now;
    final baseDate = currentEndDate.isAfter(now) ? currentEndDate : now;
    final newEndDate = baseDate.add(Duration(days: result * 30));
    
    // Update contract
    final success = await ref.read(userManagementProvider.notifier).updateContractEndDate(
          documentId: user.id!,
          contractEndDate: newEndDate,
        );
    
    if (!mounted) return;
    
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Berhasil menambah $result token!\n'
            'Kontrak diperpanjang hingga: ${_formatDate(newEndDate)}',
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 5),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal menambah token'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handleDeleteUser(UserModel user, {bool force = false}) async {
    // 1. Initial Confirmation (only if not force)
    if (!force) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning, color: Colors.orange),
              SizedBox(width: 8),
              Text('Konfirmasi Hapus'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Apakah Anda yakin ingin menghapus user:\n\n'
                  '${user.fullName}\n${user.email}',
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    border: Border.all(color: Colors.red),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '⚠️ PERINGATAN:',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Tindakan ini akan menghapus akun secara PERMANEN beserta data profilnya.',
                        style: TextStyle(fontSize: 13, color: Colors.red),
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
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Hapus Permanen'),
            ),
          ],
        ),
      );
      
      if (confirm != true) return;
    }

    // 2. Execute Delete
    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final success = await ref.read(userManagementProvider.notifier).deleteUser(
            authUserId: user.userId,
            documentId: user.id!,
            force: force,
          );
      
      // Pop loading
      if (mounted) Navigator.pop(context);
      
      if (!mounted) return;
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User berhasil dihapus secara permanen'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal menghapus user'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // Pop loading
      if (mounted) Navigator.pop(context);

      if (e.toString().contains('HAS_ACTIVE_TENANTS')) {
        if (mounted) {
          _showForceDeleteDialog(user);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _showForceDeleteDialog(UserModel user) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber, color: Colors.red, size: 28),
            SizedBox(width: 8),
            Text('Active Tenants Detected'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'User ${user.fullName} memiliki tenant/kantin yang masih aktif.',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text(
                'Menghapus user ini akan secara OTOMATIS MENGHAPUS:\n'
                '• Semua Tenant/Kantin milik user ini\n'
                '• Semua Staff/Karyawan di tenant tersebut\n'
                '• Semua Produk dan Pesanan',
              ),
              const SizedBox(height: 16),
              const Text(
                'Apakah Anda yakin ingin melakukan FORCE DELETE?',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
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
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('FORCE DELETE SEMUA'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      _handleDeleteUser(user, force: true);
    }
  }

  Future<Map<String, String>?> _showEditUserDialog(BuildContext context, UserModel user) {
    final fullNameController = TextEditingController(text: user.fullName);
    final phoneController = TextEditingController(text: user.phone ?? '');
    final formKey = GlobalKey<FormState>();
    
    return showDialog<Map<String, String>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit User'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: fullNameController,
                decoration: const InputDecoration(
                  labelText: 'Nama Lengkap',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Nama lengkap harus diisi';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: phoneController,
                decoration: const InputDecoration(
                  labelText: 'Nomor Telepon (Opsional)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context, {
                  'fullName': fullNameController.text.trim(),
                  'phone': phoneController.text.trim().isEmpty 
                      ? null 
                      : phoneController.text.trim(),
                });
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  Future<String?> _showResetPasswordDialog(BuildContext context, UserModel user) {
    final passwordController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Password'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('User: ${user.fullName}'),
              Text('Email: ${user.email}'),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              TextFormField(
                controller: passwordController,
                decoration: const InputDecoration(
                  labelText: 'Password Baru',
                  hintText: 'Minimal 8 karakter',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Password harus diisi';
                  }
                  if (value.length < 8) {
                    return 'Password minimal 8 karakter';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context, passwordController.text.trim());
              }
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Apakah Anda yakin ingin keluar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await ref.read(authProvider.notifier).logout();
    }
  }
}
