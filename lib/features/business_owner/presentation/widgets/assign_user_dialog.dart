import 'dart:convert';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:appwrite/appwrite.dart';
import '../../../../core/providers/appwrite_provider.dart';
import '../../../../core/config/appwrite_config.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../../shared/models/tenant_model.dart';
import '../../../../shared/models/user_model.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../providers/tenant_provider.dart';
import '../../providers/tenant_user_provider.dart';

/// Dialog for assigning user to tenant
class AssignUserDialog extends ConsumerStatefulWidget {
  const AssignUserDialog({super.key});

  @override
  ConsumerState<AssignUserDialog> createState() => _AssignUserDialogState();
}

class _AssignUserDialogState extends ConsumerState<AssignUserDialog> {
  UserModel? _selectedUser;
  TenantModel? _selectedTenant;
  bool _isLoading = false;
  
  // Mode: true = create new, false = assign existing
  bool _isCreateMode = false;
  
  // Form controllers for new user
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final availableUsersAsync = ref.watch(availableUsersProvider);
    final tenantsState = ref.watch(myTenantsProvider);

    return AlertDialog(
      title: const Text('Assign User ke Tenant'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 500,
          minWidth: 300,
        ),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
              // Mode toggle
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(
                    value: false,
                    label: Text('User Lama'),
                    icon: Icon(Icons.people),
                  ),
                  ButtonSegment(
                    value: true,
                    label: Text('Buat Baru'),
                    icon: Icon(Icons.person_add),
                  ),
                ],
                selected: {_isCreateMode},
                onSelectionChanged: (Set<bool> newSelection) {
                  setState(() {
                    _isCreateMode = newSelection.first;
                  });
                },
              ),
              const SizedBox(height: 16),
              
              // Conditional content based on mode
              if (!_isCreateMode) ...[
                // Available users dropdown (existing code)
                availableUsersAsync.when(
              data: (users) {
                if (users.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.orange.shade700),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Tidak ada user tersedia.\nSemua user sudah di-assign ke tenant.',
                            style: TextStyle(
                              color: Colors.orange.shade700,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return DropdownButtonFormField<UserModel>(
                  initialValue: _selectedUser,
                  decoration: const InputDecoration(
                    labelText: 'Pilih User *',
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(),
                  ),
                  isExpanded: true,
                  items: users.map((user) {
                    return DropdownMenuItem(
                      value: user,
                      child: Text(
                        '${user.fullName} (${user.email})',
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedUser = value;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Pilih user terlebih dahulu';
                    }
                    return null;
                  },
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (error, stack) => Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Error loading users: $error',
                  style: TextStyle(color: Colors.red.shade700),
                ),
              ),
            ),
              ] else ...[
                // Create new user form
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nama Lengkap *',
                    hintText: 'Masukkan nama lengkap',
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Nama harus diisi';
                    }
                    return null;
                  },
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 12),
                
                TextFormField(
                  controller: _usernameController,
                  decoration: const InputDecoration(
                    labelText: 'Username *',
                    hintText: 'username (untuk login)',
                    prefixIcon: Icon(Icons.alternate_email),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Username harus diisi';
                    }
                    if (value.length < 3) {
                      return 'Username minimal 3 karakter';
                    }
                    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value)) {
                      return 'Username hanya boleh huruf, angka, dan underscore';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email *',
                    hintText: 'user@example.com',
                    prefixIcon: Icon(Icons.email),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Email harus diisi';
                    }
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                      return 'Format email tidak valid';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Password *',
                    hintText: 'Minimal 8 karakter',
                    prefixIcon: Icon(Icons.lock),
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
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
                const SizedBox(height: 12),
                
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Nomor Telepon (Opsional)',
                    hintText: '081234567890',
                    prefixIcon: Icon(Icons.phone),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      if (!RegExp(r'^[0-9+\-\s()]+$').hasMatch(value)) {
                        return 'Format nomor telepon tidak valid';
                      }
                    }
                    return null;
                  },
                ),
              ],
            const SizedBox(height: 16),
            
            // Tenants dropdown (shared for both modes)
            if (tenantsState.tenants.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange.shade700),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Tidak ada tenant.\nBuat tenant terlebih dahulu.',
                        style: TextStyle(
                          color: Colors.orange.shade700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              DropdownButtonFormField<TenantModel>(
              initialValue: _selectedTenant,
              decoration: const InputDecoration(
                labelText: 'Pilih Tenant *',
                prefixIcon: Icon(Icons.store),
                border: OutlineInputBorder(),
              ),
              isExpanded: true,
              items: tenantsState.tenants.map((tenant) {
                return DropdownMenuItem(
                  value: tenant,
                  child: Text(
                    '${tenant.type.icon} ${tenant.name} - ${tenant.type.label}',
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedTenant = value;
                });
              },
              validator: (value) {
                if (value == null) {
                  return 'Pilih tenant terlebih dahulu';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            // Info
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
                  Expanded(
                    child: Text(
                      _isCreateMode
                          ? 'Akun baru akan dibuat dan langsung di-assign sebagai admin tenant.'
                          : 'User yang di-assign akan menjadi admin tenant dan bisa mengelola produk & kategori.',
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: _isLoading ? null : (_isCreateMode ? _createAndAssignUser : _assignUser),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(_isCreateMode ? 'Buat & Assign' : 'Assign'),
        ),
      ],
    );
  }

  Future<void> _assignUser() async {
    if (_selectedUser == null || _selectedTenant == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih user dan tenant terlebih dahulu'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Check free tier user limit
    final auth = ref.read(authProvider);
    if (auth.user != null && auth.user!.isFree) {
      // Count existing users for this tenant
      final usersState = ref.read(myTenantUsersProvider);
      final usersForTenant = usersState.users.where((u) => u.tenantId == _selectedTenant!.id).length;
      
      if (usersForTenant >= 1) {
        // Show upgrade dialog
        _showUserLimitDialog();
        return;
      }
    }

    setState(() {
      _isLoading = true;
    });

    final success = await ref
        .read(myTenantUsersProvider.notifier)
        .assignUserToTenant(_selectedUser!.id!, _selectedTenant!.id);

    if (mounted) {
      setState(() {
        _isLoading = false;
      });

      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${_selectedUser!.fullName} berhasil di-assign ke ${_selectedTenant!.name}',
            ),
            backgroundColor: Colors.green,
          ),
        );
        
        // Refresh available users
        ref.invalidate(availableUsersProvider);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal assign user ke tenant'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _createAndAssignUser() async {
    // Validate form
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Check tenant selected
    if (_selectedTenant == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih tenant terlebih dahulu'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Check free tier user limit
    final auth = ref.read(authProvider);
    if (auth.user != null && auth.user!.isFree) {
      // Count existing users for this tenant
      final usersState = ref.read(myTenantUsersProvider);
      final usersForTenant = usersState.users.where((u) => u.tenantId == _selectedTenant!.id).length;
      
      if (usersForTenant >= 1) {
        // Show upgrade dialog
        _showUserLimitDialog();
        return;
      }
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Get Appwrite Functions service
      final functions = ref.read(appwriteFunctionsProvider);

      // Prepare payload with snake_case field names (function expects these)
      final payload = {
        'user_type': 'tenant',
        'email': _emailController.text.trim(),
        'password': _passwordController.text.trim(),
        'full_name': _nameController.text.trim(),
        'username': _usernameController.text.trim(),
        'tenant_id': _selectedTenant!.id,
        'phone': _phoneController.text.trim().isEmpty 
            ? null 
            : _phoneController.text.trim(),
      };

      AppLogger.info('Calling create-user function with payload: $payload');

      // Call Appwrite Function to create user
      final execution = await functions.createExecution(
        functionId: AppwriteConfig.createUserFunctionId,
        body: jsonEncode(payload),
      );

      AppLogger.info('Function execution response: ${execution.responseBody}');

      // Parse response
      final response = jsonDecode(execution.responseBody);
      
      if (response['success'] == true) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });

          // Success
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '✅ User "${_nameController.text}" berhasil dibuat!',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Di-assign ke: ${_selectedTenant!.name}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'User dapat login dengan email dan password yang telah dibuat.',
                    style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 4),
            ),
          );

          // Refresh lists
          ref.invalidate(availableUsersProvider);
          ref.read(myTenantUsersProvider.notifier).loadTenantUsers();
        }
      } else {
        throw Exception(response['error'] ?? 'Unknown error from function');
      }
    } catch (e, stackTrace) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        // Log error for debugging
        AppLogger.error('Error creating user', e, stackTrace);
        if (kDebugMode) {
          print('❌ Full Error creating user: $e');
          print('📍 Stack trace: $stackTrace');
        }

        String errorMessage = 'Gagal membuat user';
        if (e.toString().contains('email')) {
          errorMessage = 'Email sudah terdaftar';
        } else if (e.toString().contains('password')) {
          errorMessage = 'Password tidak memenuhi syarat';
        } else if (e.toString().contains('username')) {
          errorMessage = 'Username sudah digunakan';
        } else if (e.toString().contains('unique')) {
          errorMessage = 'Data sudah ada (email/username duplikat)';
        } else if (e.toString().contains('Function not found')) {
          errorMessage = 'Function tidak ditemukan. Pastikan function sudah di-deploy.';
        } else if (e.toString().contains('unauthorized')) {
          errorMessage = 'Tidak memiliki akses untuk menjalankan function';
        } else {
          // Show full error for debugging
          errorMessage = 'Error: ${e.toString()}';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 8),
          ),
        );
      }
    }
  }

  void _showUserLimitDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.block, color: Colors.red.shade700),
            const SizedBox(width: 12),
            const Expanded(
              child: Text('User Limit Reached'),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Free tier: Max 1 user per tenant',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            if (_selectedTenant != null) ...[
              const SizedBox(height: 8),
              Text(
                'Tenant "${_selectedTenant!.name}" sudah memiliki 1 user.',
                style: const TextStyle(fontSize: 13),
              ),
            ],
            const SizedBox(height: 16),
            const Text(
              'Upgrade to Premium untuk:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildFeatureItem('Unlimited users per tenant'),
            _buildFeatureItem('Unlimited tenants'),
            _buildFeatureItem(' Full analytics & reports'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.purple.shade700,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 24),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Business Owner Premium',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Rp 149.000/bulan',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
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

  Widget _buildFeatureItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }
}
