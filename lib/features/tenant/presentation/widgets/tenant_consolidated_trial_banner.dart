import 'package:flutter/material.dart';
import 'package:kantin_app/shared/models/user_model.dart';
import 'package:kantin_app/shared/models/tenant_model.dart';
import 'package:kantin_app/features/tenant/presentation/pages/tenant_downgrade_impact_page.dart';

/// Consolidated Trial Warning Banner - Tenant Version
/// 
/// Shows educational banner for tenant users when BO's trial is ending
class TenantConsolidatedTrialBanner extends StatelessWidget {
  final UserModel ownerUser;
  final TenantModel tenant;
  
  const TenantConsolidatedTrialBanner({
    super.key,
    required this.ownerUser,
    required this.tenant,
  });

  @override
  Widget build(BuildContext context) {
    // Show for trial, premium, or active users approaching expiry
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
                        '⏰ ${ownerUser.paymentStatus == 'trial' ? 'Trial' : 'Premium'} Business Owner berakhir $daysRemaining hari lagi',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: urgencyColor,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Business Owner belum upgrade ke premium. Pelajari dampaknya untuk tenant Anda.',
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
            
            // Action button
            OutlinedButton.icon(
              onPressed: () => _showDowngradeImpactPage(context),
              icon: const Icon(Icons.help_outline),
              label: const Text('Apa dampaknya?'),
              style: OutlinedButton.styleFrom(
                foregroundColor: urgencyColor,
                side: BorderSide(color: borderColor, width: 1.5),
                minimumSize: const Size(double.infinity, 44),
              ),
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
        builder: (_) => TenantDowngradeImpactPage(tenant: tenant),
      ),
    );
  }
}
