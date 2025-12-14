import 'package:flutter/material.dart';
import '../../providers/tenant_subscription_provider.dart';

/// Banner shown to non-selected tenants to contact their Business Owner
class ContactOwnerBanner extends StatelessWidget {
  final TenantSubscriptionStatus subscriptionStatus;
  
  const ContactOwnerBanner({
    super.key,
    required this.subscriptionStatus,
  });

  @override
  Widget build(BuildContext context) {
    // Only show for non-selected tenants under free tier BO
    if (subscriptionStatus.isBusinessOwnerFreeTier && !subscriptionStatus.isTenantSelected) {
      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.orange.shade800,
              Colors.deepOrange.shade700,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.orange.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Status: Non-Prioritas',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Akses terbatas (Limit: ${subscriptionStatus.productLimit} produk)',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tenant ini belum dipilih sebagai prioritas oleh pemilik bisnis dalam mode Free Tier.',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _showContactDialog(context),
              icon: const Icon(Icons.phone, size: 18),
              label: const Text('Hubungi Pemilik'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.deepOrange.shade700,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      );
    }
    
    // Don't show for selected tenants or premium BO
    return const SizedBox.shrink();
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
