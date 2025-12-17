import 'package:flutter/material.dart';
import '../../providers/tenant_subscription_provider.dart';

/// Unified Free Tier Banner for all free tier tenants
/// Shows same messaging for selected & non-selected tenants
/// Difference is only in counter: 15 vs 10 product limit
class ContactOwnerBanner extends StatelessWidget {
  final TenantSubscriptionStatus subscriptionStatus;
  
  const ContactOwnerBanner({
    super.key,
    required this.subscriptionStatus,
  });

  @override
  Widget build(BuildContext context) {
    // User feedback: Remove duplicate banner
    // Keep only first FreeTierBanner, this one hidden
    // Counter shown only in Kelola Menu AppBar
    return const SizedBox.shrink();
  }

  void _showUpgradeInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF101010),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: Colors.grey.shade900, width: 1),
        ),
        title: const Row(
          children: [
            Icon(Icons.workspace_premium, color: Colors.teal, size: 28),
            SizedBox(width: 12),
            Text(
              'Upgrade ke Premium',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dapatkan akses unlimited untuk semua fitur:',
              style: TextStyle(
                color: Colors.grey.shade300,
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            _buildFeatureItem('✅ Unlimited produk'),
            _buildFeatureItem('✅ Unlimited staff'),
            _buildFeatureItem('✅ Unlimited categories'),
            _buildFeatureItem('✅ Analytics premium'),
            const SizedBox(height: 16),
            Text(
              'Cara upgrade:',
              style: TextStyle(
                color: Colors.grey.shade300,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subscriptionStatus.isTenantSelected
                  ? '• Upgrade akun Anda sendiri, atau\n• Hubungi pemilik bisnis untuk upgrade'
                  : '• Hubungi pemilik bisnis untuk upgrade, atau\n• Upgrade akun Anda sendiri',
              style: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(foregroundColor: Colors.grey),
            child: const Text('Tutup'),
          ),
          if (!subscriptionStatus.isTenantSelected)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _showContactDialog(context);
              },
              style: TextButton.styleFrom(foregroundColor: Colors.teal),
              child: const Text('Hubungi Owner'),
            ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
        ),
      ),
    );
  }

  void _showContactDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF101010),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: Colors.grey.shade900, width: 1),
        ),
        title: const Row(
          children: [
            Icon(Icons.business, color: Colors.orange, size: 28),
            SizedBox(width: 12),
            Text(
              'Hubungi Pemilik Bisnis',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Untuk upgrade tenant atau meminta dipilih sebagai tenant prioritas, hubungi pemilik bisnis:',
              style: TextStyle(
                color: Colors.grey.shade300,
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            if (subscriptionStatus.businessOwnerEmail != null) ...[
              _buildContactItem(
                Icons.email_outlined,
                'Email',
                subscriptionStatus.businessOwnerEmail!,
              ),
              const SizedBox(height: 12),
            ],
            if (subscriptionStatus.businessOwnerPhone != null) ...[
              _buildContactItem(
                Icons.phone_outlined,
                'Telepon',
                subscriptionStatus.businessOwnerPhone!,
              ),
            ],
            if (subscriptionStatus.businessOwnerEmail == null &&
                subscriptionStatus.businessOwnerPhone == null)
              Text(
                'Info kontak tidak tersedia.',
                style: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(foregroundColor: Colors.grey),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  Widget _buildContactItem(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade900.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade800, width: 1),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.orange.shade400, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
