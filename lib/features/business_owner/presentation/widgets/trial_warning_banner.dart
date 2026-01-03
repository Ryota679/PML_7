import 'package:flutter/material.dart';
import 'package:kantin_app/shared/models/user_model.dart';

/// Trial Warning Banner
/// 
/// Shows warning messages when trial is about to expire
/// - Red banner at D-1 (Last day!)
/// - Orange banner at D-3 (3 days warning)
/// - Yellow banner at D-7 (Week warning)
class TrialWarningBanner extends StatelessWidget {
  final UserModel user;

  const TrialWarningBanner({
    super.key,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    // Show for trial, premium, or active users approaching expiry  
    if (user.paymentStatus != 'trial' &&
        user.paymentStatus != 'premium' && 
        user.paymentStatus != 'active') {
      return const SizedBox.shrink();
    }

    // Calculate days remaining
    if (user.subscriptionExpiresAt == null) {
      return const SizedBox.shrink();
    }

    final now = DateTime.now();
    final expiresAt = user.subscriptionExpiresAt!;
    final daysRemaining = expiresAt.difference(now).inDays;

    // Don't show if more than 7 days or already expired
    if (daysRemaining > 7 || daysRemaining < 0) {
      return const SizedBox.shrink();
    }

    // Determine warning level
    Color backgroundColor;
    Color textColor;
    IconData icon;
    String title;
    String message;

    if (daysRemaining <= 1) {
      // D-1: Red / Critical
      backgroundColor = Colors.red.shade50;
      textColor = Colors.red.shade900;
      icon = Icons.error_outline;
      title = daysRemaining == 0 
          ? '${user.paymentStatus == 'trial' ? 'Trial' : 'Premium'} berakhir hari ini!' 
          : '${user.paymentStatus == 'trial' ? 'Trial' : 'Premium'} berakhir besok!';
      message = 'Upgrade ke PREMIUM sekarang untuk tetap menggunakan semua fitur';
    } else if (daysRemaining <= 3) {
      // D-3: Orange / Warning
      backgroundColor = Colors.orange.shade50;
      textColor = Colors.orange.shade900;
      icon = Icons.warning_amber;
      title = '${user.paymentStatus == 'trial' ? 'Trial' : 'Premium'} berakhir dalam $daysRemaining hari';
      message = 'Jangan sampai kehilangan akses! Upgrade ke PREMIUM sekarang';
    } else {
      // D-7: Yellow / Info
      backgroundColor = Colors.amber.shade50;
      textColor = Colors.amber.shade900;
      icon = Icons.info_outline;
      title = '${user.paymentStatus == 'trial' ? 'Trial' : 'Premium'} berakhir dalam $daysRemaining hari';
      message = 'Nikmati fitur premium selamanya dengan berlangganan';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: textColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showUpgradeDialog(context),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: textColor.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        icon,
                        color: textColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            message,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: textColor.withOpacity(0.8),
                                ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: textColor.withOpacity(0.6),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => _showUpgradeDialog(context),
                    icon: const Icon(Icons.stars, size: 20),
                    label: const Text('Upgrade ke PREMIUM'),
                    style: FilledButton.styleFrom(
                      backgroundColor: textColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showUpgradeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.stars, color: Colors.amber),
            SizedBox(width: 8),
            Text('Upgrade ke PREMIUM'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Dapatkan akses unlimited dengan PREMIUM:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildFeatureItem('✅ Unlimited tenants (basic user: max 2)'),
            const SizedBox(height: 8),
            _buildFeatureItem('✅ Unlimited products per tenant (basic user: max 30)'),
            const SizedBox(height: 8),
            _buildFeatureItem('✅ Unlimited staff per tenant (basic user: max 3)'),
            const SizedBox(height: 8),
            _buildFeatureItem('✅ Priority support'),
            const SizedBox(height: 8),
            _buildFeatureItem('✅ Advanced analytics'),
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
                    'Hanya Rp 99.000/bulan',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
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
          FilledButton.icon(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Navigate to payment page
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Fitur pembayaran akan tersegera!'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            icon: const Icon(Icons.payment),
            label: const Text('Upgrade Sekarang'),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(String text) {
    return Row(
      children: [
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 14),
          ),
        ),
      ],
    );
  }
}
