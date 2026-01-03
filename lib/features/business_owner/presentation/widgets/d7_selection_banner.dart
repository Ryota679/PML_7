import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_app/shared/models/user_model.dart';
import 'package:kantin_app/features/business_owner/presentation/pages/downgrade_impact_page.dart';
import 'package:kantin_app/features/business_owner/providers/tenant_provider.dart';

/// D-7 Selection Banner
/// 
/// Shows 7 days before trial expires, prompting BO to select 2 active tenants
class D7SelectionBanner extends ConsumerWidget {
  final UserModel user;

  const D7SelectionBanner({
    super.key,
    required this.user,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Show for trial, premium, or active users approaching expiry
    if (user.paymentStatus != 'trial' && 
        user.paymentStatus != 'premium' && 
        user.paymentStatus != 'active') {
      return const SizedBox.shrink();
    }

    // Only show if user hasn't submitted selection yet
    if (user.selectionSubmittedAt != null) {
      return const SizedBox.shrink();
    }

    // Calculate days remaining
    if (user.subscriptionExpiresAt == null) {
      return const SizedBox.shrink();
    }

    final now = DateTime.now();
    final expiresAt = user.subscriptionExpiresAt!;
    final daysRemaining = expiresAt.difference(now).inDays;

    // Only show from D-7 to D-0
    if (daysRemaining > 7 || daysRemaining < 0) {
      return const SizedBox.shrink();
    }

    // NEW: Auto-skip selection if tenant count ≤ 2
    // Get tenant count from provider
    final tenantsState = ref.watch(myTenantsProvider);
    final tenantCount = tenantsState.tenants.length;
    
    if (tenantCount <= 2) {
      // Don't show selection banner - all tenants will auto-selected
      // NoSelectionNeededBanner will be shown instead by business_owner_dashboard
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.purple.shade50,
            Colors.blue.shade50,
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.purple.shade200,
          width: 1.5,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _navigateToDowngradeImpact(context),
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
                        color: Colors.purple.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.stars,
                        color: Colors.purple.shade700,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '🎯 Pilih 2 Tenant Terbaik Anda',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.purple.shade900,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${user.paymentStatus == 'trial' ? 'Trial' : 'Premium'} berakhir dalam $daysRemaining hari',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: _getCountdownColor(daysRemaining),
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Pilih 2 tenant untuk tetap dapat akses penuh setelah trial berakhir.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade800,
                      ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, 
                        color: Colors.orange.shade700,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Jika tidak memilih, sistem akan otomatis memilih 2 tenant dengan pendapatan tertinggi (30 hari terakhir).',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.schedule, size: 18),
                        label: const Text('Nanti'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.grey.shade700,
                          side: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: FilledButton.icon(
                        onPressed: () => _navigateToDowngradeImpact(context),
                        icon: const Icon(Icons.checklist, size: 20),
                        label: const Text('Pilih Sekarang'),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.purple.shade600,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToDowngradeImpact(BuildContext context) {
    // Navigate to educational page first (better UX)
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DowngradeImpactPage(user: user),
      ),
    );
  }

  /// Get countdown color based on days remaining (creates urgency)
  Color _getCountdownColor(int days) {
    if (days == 0) return Colors.red.shade700;      // D-0: Red (urgent!)
    if (days <= 2) return Colors.orange.shade700;   // D-1, D-2: Orange
    if (days <= 4) return Colors.purple.shade600;   // D-3, D-4: Purple
    return Colors.purple.shade800;                  // D-5+: Dark purple
  }
}
