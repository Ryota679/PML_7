import 'package:flutter/material.dart';
import 'package:kantin_app/shared/models/user_model.dart';

/// Tenant Grace Period Warning Banner
/// 
/// Shows when tenant user's BO is in grace period
/// Encourages contacting BO or upgrading to Tenant Premium
class TenantGraceWarningBanner extends StatelessWidget {
  final UserModel tenantUser;
  final UserModel businessOwner;
  final int daysRemaining;
  final VoidCallback onUpgrade;

  const TenantGraceWarningBanner({
    super.key,
    required this.tenantUser,
    required this.businessOwner,
    required this.daysRemaining,
    required this.onUpgrade,
  });

  @override
  Widget build(BuildContext context) {
    final color = _getUrgencyColor();
    final icon = _getUrgencyIcon();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(icon, color: color, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '⚠️ Peringatan Akun: $daysRemaining ${daysRemaining == 1 ? 'hari' : 'hari'} tersisa',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Warning message
            Text(
              'Akun Anda mungkin dinonaktifkan karena Business Owner Anda dalam masa tenggang free tier.',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 16),
            
            // BO Contact Info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Hubungi Business Owner:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.person, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Text(
                        businessOwner.fullName,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                  if (businessOwner.phone != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.phone, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 8),
                        Text(
                          businessOwner.phone!,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.email, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          businessOwner.email,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            
            // Upgrade option
            const Text(
              'Atau upgrade ke Tenant Premium untuk akses tanpa batas:',
              style: TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onUpgrade,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.purple,
                ),
                icon: const Icon(Icons.star, size: 18),
                label: const Text('Upgrade Sekarang'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getUrgencyColor() {
    if (daysRemaining >= 4) return Colors.blue;
    if (daysRemaining >= 2) return Colors.orange;
    return Colors.red;
  }

  IconData _getUrgencyIcon() {
    if (daysRemaining >= 4) return Icons.info_outline;
    if (daysRemaining >= 2) return Icons.warning_amber;
    return Icons.error_outline;
  }
}
