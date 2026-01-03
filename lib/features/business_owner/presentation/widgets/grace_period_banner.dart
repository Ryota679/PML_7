import 'package:flutter/material.dart';
import 'package:kantin_app/shared/models/user_model.dart';

/// Grace Period Banner for Business Owner Dashboard
/// 
/// Shows during 7-day grace period after trial expires with excess users
class GracePeriodBanner extends StatelessWidget {
  final UserModel user;
  final int daysRemaining;
  final VoidCallback onChooseUsers;

  const GracePeriodBanner({
    super.key,
    required this.user,
    required this.daysRemaining,
    required this.onChooseUsers,
  });

  @override
  Widget build(BuildContext context) {
    // Determine urgency color
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
        child: Row(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '⏰ Masa Tenggang: $daysRemaining ${daysRemaining == 1 ? 'hari' : 'hari'} tersisa',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Trial Anda telah berakhir. Pilih 1 user per tenant sebelum akun dinonaktifkan.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            FilledButton(
              onPressed: onChooseUsers,
              style: FilledButton.styleFrom(
                backgroundColor: color,
              ),
              child: const Text('Pilih Sekarang'),
            ),
          ],
        ),
      ),
    );
  }

  Color _getUrgencyColor() {
    if (daysRemaining >= 4) return Colors.blue; // Day 0-3
    if (daysRemaining >= 2) return Colors.orange; // Day 4-5
    return Colors.red; // Day 6-7
  }

  IconData _getUrgencyIcon() {
    if (daysRemaining >= 4) return Icons.info_outline;
    if (daysRemaining >= 2) return Icons.warning_amber;
    return Icons.error_outline;
  }
}
