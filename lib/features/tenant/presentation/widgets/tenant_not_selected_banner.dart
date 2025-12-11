import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_app/shared/models/user_model.dart';

/// Tenant D-0 Not Selected Banner
/// 
/// Shows to tenants who are NOT in the selected list after trial expires
class TenantNotSelectedBanner extends ConsumerWidget {
  final UserModel ownerUser;

  const TenantNotSelectedBanner({
    super.key,
    required this.ownerUser,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.orange.shade300,
          width: 1.5,
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
                  Icons.lock_outline,
                  color: Colors.orange.shade700,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '🔒 Tenant Tidak Termasuk Aktif',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade900,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Anda tidak termasuk dalam 2 tenant yang dipilih owner bisnis. Akses akan terbatas (view + delete saja).',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade800,
                  ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showOwnerContact(context),
                    icon: const Icon(Icons.phone, size: 18),
                    label: const Text('Hubungi Owner'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.orange.shade700,
                      side: BorderSide(color: Colors.orange.shade300),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    onPressed: () => _showUpgradeDialog(context),
                    icon: const Icon(Icons.stars, size: 18),
                    label: const Text('Upgrade (Rp 49k/bln)'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.orange.shade600,
                    ),
                  ),
                ),
              ],
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
            Icon(Icons.contact_phone, color: Colors.orange.shade700),
            const SizedBox(width: 8),
            const Text('Kontak Business Owner'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Hubungi pemilik bisnis untuk dimask dalam tenant aktif:',
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

  void _showUpgradeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.stars, color: Colors.orange.shade600),
            const SizedBox(width: 8),
            const Text('Upgrade ke Premium Tenant'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Dengan Tenant Premium, Anda mendapat:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildFeature('✅ Full manajemen produk & kategori'),
            _buildFeature('✅ Full manajemen staff'),
            _buildFeature('✅ Analytics & Laporan lengkap'),
            _buildFeature('✅ Export PDF/Excel'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.local_offer, color: Colors.green, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Hanya Rp 49.000/bulan',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade900,
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
            child: const Text('Nanti'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Navigate to payment page
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Fitur pembayaran akan segera tersedia!'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: const Text('Upgrade Sekarang'),
          ),
        ],
      ),
    );
  }

  Widget _buildFeature(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(text, style: const TextStyle(fontSize: 14)),
    );
  }
}
