import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_app/shared/models/user_model.dart';

/// Tenant D-7 Warning Banner
/// 
/// Shows to ALL tenants 7 days before BO trial expires
/// Soft warning + inform to contact owner
class TenantD7WarningBanner extends ConsumerWidget {
  final UserModel ownerUser;  // Business Owner user

  const TenantD7WarningBanner({
    super.key,
    required this.ownerUser,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Show if owner is in trial, premium, or active (approaching expiry)
    if (ownerUser.paymentStatus != 'trial' && 
        ownerUser.paymentStatus != 'premium' && 
        ownerUser.paymentStatus != 'active') {
      return const SizedBox.shrink();
    }

    // Calculate days remaining
    if (ownerUser.subscriptionExpiresAt == null) {
      return const SizedBox.shrink();
    }

    final now = DateTime.now();
    final expiresAt = ownerUser.subscriptionExpiresAt!;
    final daysRemaining = expiresAt.difference(now).inDays;

    // Only show from D-7 to D-0
    if (daysRemaining > 7 || daysRemaining < 0) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.blue.shade200,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Colors.blue.shade700,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                     'ℹ️ ${ownerUser.paymentStatus == 'trial' ? 'Trial' : 'Premium'} Owner Berakhir dalam $daysRemaining Hari',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade900,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Pastikan performa tenant Anda baik agar terpilih sebagai salah satu dari 2 tenant aktif.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade800,
                  ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.lightbulb_outline,
                    color: Colors.amber.shade700,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Owner bisnis akan memilih 2 tenant yang tetap bisa login dengan akses penuh. Hubungi owner untuk memastikan tenant Anda terpilih.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.amber.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () => _showOwnerContact(context),
              icon: const Icon(Icons.phone, size: 18),
              label: const Text('Hubungi Owner'),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showOwnerContact(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.contact_phone, color: Colors.blue.shade700),
            const SizedBox(width: 8),
            const Text('Kontak Business Owner'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Hubungi pemilik bisnis:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: Icon(Icons.person, color: Colors.grey.shade700),
              title: Text(ownerUser.fullName),
              contentPadding: EdgeInsets.zero,
            ),
            if (ownerUser.email.isNotEmpty && ownerUser.email != 'no-email@example.com')
              ListTile(
                leading: Icon(Icons.email, color: Colors.grey.shade700),
                title: Text(ownerUser.email),
                contentPadding: EdgeInsets.zero,
              ),
            if (ownerUser.phone != null && ownerUser.phone!.isNotEmpty)
              ListTile(
                leading: Icon(Icons.phone, color: Colors.grey.shade700),
                title: Text(ownerUser.phone!),
                contentPadding: EdgeInsets.zero,
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }
}
