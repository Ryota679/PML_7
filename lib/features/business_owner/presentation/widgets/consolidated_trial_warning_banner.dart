import 'package:flutter/material.dart';
import 'package:kantin_app/shared/models/user_model.dart';
import 'package:kantin_app/features/business_owner/presentation/pages/downgrade_impact_page.dart';

/// Consolidated Trial Warning Banner
/// 
/// Replaces multiple separate banners with single educational banner
/// Shows "Apa penurunannya?" button leading to dedicated info page
class ConsolidatedTrialWarningBanner extends StatelessWidget {
  final UserModel user;
  
  const ConsolidatedTrialWarningBanner({
    super.key,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    // Show for trial OR premium users approaching expiry
    // Skip for free tier users
    if (user.paymentStatus != 'trial' && user.paymentStatus != 'premium' && user.paymentStatus != 'active') {
      return const SizedBox.shrink();
    }

    // Calculate days remaining
    if (user.subscriptionExpiresAt == null) {
      return const SizedBox.shrink();
    }

    final now = DateTime.now();
    final expiresAt = user.subscriptionExpiresAt!;
    final daysRemaining = expiresAt.difference(now).inDays;

    // Only show from D-7 to D-0 (H-7 warning period)
    if (daysRemaining > 7 || daysRemaining < 0) {
      return const SizedBox.shrink();
    }

    // Color based on urgency
    final Color urgencyColor = _getUrgencyColor(daysRemaining);
    final Color backgroundColor = urgencyColor.withOpacity(0.1);
    final Color borderColor = urgencyColor.withOpacity(0.3);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            backgroundColor,
            backgroundColor.withOpacity(0.5),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: borderColor,
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with icon + countdown
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: urgencyColor.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.info_outline,
                    color: urgencyColor,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '⏰ ${user.paymentStatus == 'trial' ? 'Trial' : 'Premium'} berakhir dalam $daysRemaining hari',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: urgencyColor,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Nikmati fitur premium selamanya dengan berlangganan',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey.shade700,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showDowngradeImpactPage(context),
                    icon: const Icon(Icons.help_outline),
                    label: const Text('Apa penurunannya?'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: urgencyColor,
                      side: BorderSide(color: borderColor, width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _showUpgradePage(context),
                    icon: const Icon(Icons.workspace_premium),
                    label: const Text('Upgrade'),
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

  Color _getUrgencyColor(int daysRemaining) {
    if (daysRemaining <= 2) {
      return Colors.red; // D-2 to D-0: Red (urgent!)
    } else if (daysRemaining <= 4) {
      return Colors.orange; // D-4 to D-3: Orange (warning)
    } else {
      return Colors.purple; // D-7 to D-5: Purple (info)
    }
  }

  void _showDowngradeImpactPage(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DowngradeImpactPage(user: user),
      ),
    );
  }

  void _showUpgradePage(BuildContext context) {
    // TODO: Navigate to payment/upgrade page
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🚧 Payment integration coming soon'),
        backgroundColor: Colors.orange,
      ),
    );
  }
}
