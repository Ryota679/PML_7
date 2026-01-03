import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_app/shared/models/user_model.dart';
import '../providers/tenant_contracts_provider.dart';

/// Dialog for adding contract tokens to a tenant
class AddContractTokenDialog extends ConsumerStatefulWidget {
  final UserModel user;

  const AddContractTokenDialog({
    super.key,
    required this.user,
  });

  @override
  ConsumerState<AddContractTokenDialog> createState() => _AddContractTokenDialogState();
}

class _AddContractTokenDialogState extends ConsumerState<AddContractTokenDialog> {
  int? _selectedMonths;
  bool _isLoading = false;

  final List<int> _monthOptions = [1, 3, 6, 12];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Tambah Token Kontrak'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User info
          Text('Tenant: ${widget.user.fullName}'),
          Text(
            '@${widget.user.username}',
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 16),

          // Duration selection
          const Text(
            'Pilih Durasi:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          ...List.generate(_monthOptions.length, (index) {
            final months = _monthOptions[index];
            return RadioListTile<int>(
              title: Text('$months Bulan'),
              subtitle: Text(months == 1 ? '$months bulan' : '+$months bulan dari kontrak saat ini'),
              value: months,
              groupValue: _selectedMonths,
              onChanged: (value) {
                setState(() {
                  _selectedMonths = value;
                });
              },
              dense: true,
              contentPadding: EdgeInsets.zero,
            );
          }),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context, false),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: _isLoading || _selectedMonths == null ? null : _addToken,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Tambah'),
        ),
      ],
    );
  }

  Future<void> _addToken() async {
    if (_selectedMonths == null || widget.user.id == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final success = await ref.read(tenantContractsProvider.notifier).addContractToken(
            widget.user.id!,
            _selectedMonths!,
          );

      if (mounted) {
        if (success) {
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Berhasil menambahkan $_selectedMonths bulan ke kontrak ${widget.user.fullName}',
              ),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Gagal menambahkan token kontrak'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
