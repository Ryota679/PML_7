import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kantin_app/features/auth/data/auth_repository.dart';
import 'package:kantin_app/features/auth/providers/auth_provider.dart';
import 'package:kantin_app/features/invitation/providers/invitation_provider.dart';

/// Page for Staff users to enter invitation code
/// 
/// This page is shown after OAuth registration for Staff users
/// who don't have a tenant_id yet
class EnterStaffCodePage extends ConsumerStatefulWidget {
  const EnterStaffCodePage({Key? key}) : super(key: key);

  @override
  ConsumerState<EnterStaffCodePage> createState() => _EnterStaffCodePageState();
}

class _EnterStaffCodePageState extends ConsumerState<EnterStaffCodePage> {
  final _codeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Masukkan Kode Staff'),
        automaticallyImplyLeading: false, // No back button
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 24),
                
                // Icon
                Icon(
                  Icons.badge,
                  size: 80,
                  color: Theme.of(context).colorScheme.primary,
                ),
                
                const SizedBox(height: 24),
                
                // Title
                Text(
                  'Kode Undangan Staff',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 12),
                
                // Subtitle
                Text(
                  'Masukkan kode undangan yang diberikan oleh pemilik usaha',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 40),
                
                // Code input field
                TextFormField(
                  controller: _codeController,
                  decoration: InputDecoration(
                    labelText: 'Kode Undangan',
                    hintText: 'ST-123456',
                    prefixIcon: const Icon(Icons.confirmation_number),
                    border: const OutlineInputBorder(),
                    errorText: _errorMessage,
                  ),
                  textCapitalization: TextCapitalization.characters,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Kode tidak boleh kosong';
                    }
                    if (!RegExp(r'^ST-\d{6}$', caseSensitive: false).hasMatch(value)) {
                      return 'Format kode: ST-123456';
                    }
                    return null;
                  },
                  onChanged: (_) {
                    // Clear error when user types
                    if (_errorMessage != null) {
                      setState(() => _errorMessage = null);
                    }
                  },
                ),
                
                const SizedBox(height: 24),
                
                // Submit button
                FilledButton(
                  onPressed: _isLoading ? null : _validateAndSubmit,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Lanjutkan'),
                ),
                
                const SizedBox(height: 16),
                
                // Help text
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.orange.shade700),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Kode berlaku 5 jam setelah dibuat',
                          style: TextStyle(
                            color: Colors.orange.shade900,
                            fontSize: 13,
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
    );
  }

  Future<void> _validateAndSubmit() async {
    // Clear previous error
    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    // Validate form
    if (!_formKey.currentState!.validate()) {
      setState(() => _isLoading = false);
      return;
    }

    final code = _codeController.text.trim().toUpperCase();

    try {
      // Validate code with backend
      final invitationRepo = ref.read(invitationRepositoryProvider);
      final result = await invitationRepo.validateCode(code);

      if (!result.isValid) {
        setState(() {
          _errorMessage = result.error;
          _isLoading = false;
        });
        return;
      }

      // Check if code type matches (should be 'staff')
      if (result.type != 'staff') {
        setState(() {
          _errorMessage = 'Kode ini untuk Tenant, bukan Staff';
          _isLoading = false;
        });
        return;
      }

      // Update user's tenant_id
      final currentUser = ref.read(authProvider).user;
      if (currentUser == null) {
        throw Exception('User not logged in');
      }

      final authRepo = ref.read(authRepositoryProvider);
      await authRepo.updateUserProfile(
        userId: currentUser.userId,
        updates: {'tenant_id': result.tenantId},
      );

      // Mark code as used
      await invitationRepo.markAsUsed(result.documentId!, currentUser.userId);

      // Refresh user profile
      await ref.read(authProvider.notifier).refreshUserProfile();

      // Navigate to staff dashboard (same as tenant for now)
      if (mounted) {
        context.go('/tenant');
      }

    } catch (e) {
      setState(() {
        _errorMessage = 'Terjadi kesalahan: $e';
        _isLoading = false;
      });
    }
  }
}
