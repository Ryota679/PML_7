import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_app/features/auth/providers/auth_provider.dart';
import 'package:kantin_app/features/invitation/providers/invitation_provider.dart';

/// Simplified invitation dialog for specific tenant
/// Only generates Tenant codes (no Staff option for Owner users)
class GenerateInvitationDialogForTenant extends ConsumerStatefulWidget {
  final String tenantId;
  
  const GenerateInvitationDialogForTenant({
    Key? key,
    required this.tenantId,
  }) : super(key: key);

  @override
  ConsumerState<GenerateInvitationDialogForTenant> createState() =>
      _GenerateInvitationDialogForTenantState();
}

class _GenerateInvitationDialogForTenantState
    extends ConsumerState<GenerateInvitationDialogForTenant> {
  bool isLoading = false;
  String? generatedCode;
  String? error;

  @override
  Widget build(BuildContext context) {
    if (generatedCode == null) {
      return _buildConfirmDialog();
    } else {
      return _buildDisplayDialog();
    }
  }

  /// Confirm dialog before generating
  Widget _buildConfirmDialog() {
    return AlertDialog(
      title: const Text('Generate Kode Undangan Tenant'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Kode ini akan digunakan untuk mengundang Tenant baru.',
            style: TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 12),
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
                    'Kode berlaku selama 5 jam',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (error != null) ...[
            const SizedBox(height: 12),
            Text(
              error!,
              style: const TextStyle(color: Colors.red),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: isLoading ? null : _generateCode,
          child: isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Generate Kode'),
        ),
      ],
    );
  }

  /// Display generated code
  Widget _buildDisplayDialog() {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.check_circle, color: Colors.green.shade600),
          const SizedBox(width: 12),
          const Text('Kode Berhasil Dibuat!'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.shade200, width: 2),
            ),
            child: Column(
              children: [
                const Text(
                  'Kode Undangan Tenant',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  generatedCode!,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade800,
                    letterSpacing: 4,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Berlaku 5 jam',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Bagikan kode ini ke calon tenant untuk melakukan registrasi.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13),
          ),
        ],
      ),
      actions: [
        OutlinedButton.icon(
          onPressed: () {
            Clipboard.setData(ClipboardData(text: generatedCode!));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Kode berhasil disalin!'),
                duration: Duration(seconds: 2),
              ),
            );
          },
          icon: const Icon(Icons.copy, size: 18),
          label: const Text('Salin Kode'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Selesai'),
        ),
      ],
    );
  }

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

      // Use invitation repository to generate code
      final invitation = await invitationRepo.generateInvitation(
        type: 'tenant',
        createdBy: currentUser.userId,
        tenantId: widget.tenantId,
      );

      setState(() {
        generatedCode = invitation.data['code'];
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = 'Gagal generate kode: ${e.toString()}';
        isLoading = false;
      });
    }
  }
}
