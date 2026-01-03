import 'package:flutter/material.dart';

/// Registration Required Dialog
/// 
/// Shown to Google OAuth users who don't have a database account
class RegistrationRequiredDialog extends StatelessWidget {
  final String email;
  final VoidCallback onOwnerSelected;
  final VoidCallback onTenantSelected;
  final VoidCallback onStaffSelected;
  final VoidCallback onCancel;

  const RegistrationRequiredDialog({
    super.key,
    required this.email,
    required this.onOwnerSelected,
    required this.onTenantSelected,
    required this.onStaffSelected,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Akun Belum Terdaftar'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Akun Google Anda ($email) berhasil login, tetapi belum terdaftar di sistem.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          Text(
            'Silakan pilih peran Anda:',
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ],
      ),
      actions: [
        // Owner Button
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: onOwnerSelected,
            icon: const Icon(Icons.business),
            label: const Text('Pemilik Usaha'),
            style: FilledButton.styleFrom(
              alignment: Alignment.centerLeft,
            ),
          ),
        ),
        const SizedBox(height: 8),
        
        // Tenant Button
        SizedBox(
          width: double.infinity,
          child: FilledButton.tonalIcon(
            onPressed: onTenantSelected,
            icon: const Icon(Icons.store),
            label: const Text('Tenant'),
            style: FilledButton.styleFrom(
              alignment: Alignment.centerLeft,
            ),
          ),
        ),
        const SizedBox(height: 8),
        
        // Staff Button
        SizedBox(
          width: double.infinity,
          child: FilledButton.tonalIcon(
            onPressed: onStaffSelected,
            icon: const Icon(Icons.person),
            label: const Text('Staff'),
            style: FilledButton.styleFrom(
              alignment: Alignment.centerLeft,
            ),
          ),
        ),
        const SizedBox(height: 16),
        
        // Cancel Button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: onCancel,
            child: const Text('Batal'),
          ),
        ),
      ],
    );
  }
}
