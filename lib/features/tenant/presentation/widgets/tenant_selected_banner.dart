import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_app/features/tenant/providers/billing_provider.dart';

/// Tenant Selected Banner
/// 
/// Shows to tenants who ARE in the selected list (positive reinforcement)
/// Shows after D-0 when trial expires
class TenantSelectedBanner extends ConsumerWidget {
  const TenantSelectedBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.green.shade50,
            Colors.teal.shade50,
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.green.shade200,
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
                  Icons.check_circle,
                  color: Colors.green.shade700,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '✅ Anda Termasuk Tenant Aktif!',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade900,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Selamat! Anda terpilih sebagai salah satu dari 2 tenant aktif. Tetap nikmati akses penuh (Free Basic Tier).',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade800,
                  ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline,
                    color: Colors.blue.shade700,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Ingin akses unlimited tanpa batasan? Upgrade ke Tenant Premium untuk analytics lengkap & export PDF.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.blue.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () => _showUpgradeDialog(context, ref),
              icon: const Icon(Icons.stars, size: 18),
              label: const Text('Upgrade ke Premium (Rp 49k/bln)'),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.green.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showUpgradeDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.stars, color: Colors.green.shade600),
            const SizedBox(width: 8),
            const Text('Upgrade ke Premium Tenant'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tingkatkan ke Premium untuk:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildFeature('✅ Analytics & Laporan lengkap'),
            _buildFeature('✅ Export PDF/Excel'),
            _buildFeature('✅ Tanpa batasan apapun'),
            _buildFeature('✅ Priority support'),
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
              _triggerPurchase(context, ref);
            },
            child: const Text('Upgrade Sekarang'),
          ),
        ],
      ),
    );
  }

  void _triggerPurchase(BuildContext context, WidgetRef ref) {
    print('[SELECTED_TENANT] Upgrade button clicked');
    
    final billingAsyncValue = ref.read(billingServiceProvider);
    
    if (!billingAsyncValue.hasValue) {
      print('[SELECTED_TENANT] Billing not ready yet');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Memuat produk...')),
      );
      return;
    }
    
    final billingState = billingAsyncValue.value!;
    print('[SELECTED_TENANT] Products available: ${billingState.products.length}');
    
    if (!billingState.isAvailable || billingState.products.isEmpty) {
      print('[SELECTED_TENANT] No products available');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Produk langganan tidak tersedia')),
      );
      return;
    }
    
    print('[SELECTED_TENANT] Triggering purchase for premium_tenant_monthly');
    
    // Trigger purchase
    ref.read(billingServiceProvider.notifier).purchaseSubscription('premium_tenant_monthly');
    
    // Show feedback
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Membuka Google Play Billing...')),
    );
  }

  Widget _buildFeature(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(text, style: const TextStyle(fontSize: 14)),
    );
  }
}
