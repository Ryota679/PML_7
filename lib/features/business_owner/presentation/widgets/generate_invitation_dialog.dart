import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_app/features/auth/providers/auth_provider.dart';
import 'package:kantin_app/features/business_owner/providers/tenant_provider.dart';
import 'package:kantin_app/features/invitation/providers/invitation_provider.dart';

/// Dialog for generating invitation codes for Tenant/Staff
class GenerateInvitationDialog extends ConsumerStatefulWidget {
  const GenerateInvitationDialog({Key? key}) : super(key: key);

  @override
  ConsumerState<GenerateInvitationDialog> createState() => _GenerateInvitationDialogState();
}

class _GenerateInvitationDialogState extends ConsumerState<GenerateInvitationDialog> {
  String? selectedType; // 'tenant' or 'staff'
  String? selectedTenantId;
  bool isLoading = false;
  String? generatedCode;
  String? error;

  @override
  Widget build(BuildContext context) {
    // Show different dialog based on state
    if (generatedCode == null) {
      return _buildInputDialog();
    } else {
      return _buildDisplayDialog();
    }
  }

  /// Input dialog for selecting type and tenant
  Widget _buildInputDialog() {
    final tenantsAsync = ref.watch(myTenantsProvider);

    return AlertDialog(
      title: const Text('Generate Kode Undangan'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Type selector
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Tipe Undangan',
                border: OutlineInputBorder(),
                helperText: 'Owner hanya dapat mengundang Tenant',
              ),
              value: selectedType,
              items: const [
                DropdownMenuItem(value: 'tenant', child: Text('Tenant')),
                // Staff can only be invited by Tenant users
              ],
              onChanged: (value) => setState(() => selectedType = value),
            ),
            
            const SizedBox(height: 16),
            
            // Tenant selector
            Builder(
              builder: (context) {
                final tenantState = tenantsAsync;
                final tenants = tenantState.tenants;
                
                if (tenantState.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (tenantState.error != null) {
                  return Text('Error: ${tenantState.error}', style: const TextStyle(color: Colors.red));
                }
                
                if (tenants.isEmpty) {
                  return const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'Belum ada tenant. Buat tenant dulu.',
                        style: TextStyle(color: Colors.orange),
                      ),
                    ),
                  );
                }
                
                return DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Pilih Tenant',
                    border: OutlineInputBorder(),
                  ),
                  value: selectedTenantId,
                  items: tenants.map((tenant) => DropdownMenuItem(
                    value: tenant.id,
                    child: Text(tenant.name),
                  )).toList(),
                  onChanged: (value) => setState(() => selectedTenantId = value),
                );
              },
            ),
            
            if (error != null) ...[
              const SizedBox(height: 16),
              Card(
                color: Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    error!,
                    style: TextStyle(color: Colors.red.shade900),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: (selectedType != null && selectedTenantId != null && !isLoading)
              ? _generateCode
              : null,
          child: isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Generate'),
        ),
      ],
    );
  }

  /// Display dialog showing generated code
  Widget _buildDisplayDialog() {
    final typeLabel = selectedType == 'tenant' ? 'Tenant' : 'Staff';
    
    return AlertDialog(
      title: Text('Kode Undangan $typeLabel'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Bagikan kode ini:'),
            const SizedBox(height: 16),
            
            // Code display
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200, width: 2),
              ),
              child: SelectableText(
                generatedCode!,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                  letterSpacing: 3,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.access_time, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 8),
                Text(
                  'Kode berlaku 5 jam',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Copy button
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                icon: const Icon(Icons.copy),
                label: const Text('Copy Kode'),
                onPressed: _copyToClipboard,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Tutup'),
        ),
      ],
    );
  }

  /// Generate invitation code
  Future<void> _generateCode() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      final invitationRepo = ref.read(invitationRepositoryProvider);
      final currentUser = ref.read(authProvider).user;
      
      if (currentUser == null) {
        throw Exception('User not logged in');
      }

      final invitation = await invitationRepo.generateInvitation(
        type: selectedType!,
        createdBy: currentUser.userId,
        tenantId: selectedTenantId!,
      );

      setState(() {
        generatedCode = invitation.data['code'];
        isLoading = false;
      });

    } catch (e) {
      setState(() {
        error = 'Gagal generate kode: $e';
        isLoading = false;
      });
    }
  }

  /// Copy code to clipboard
  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: generatedCode!));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Kode disalin ke clipboard!'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}
