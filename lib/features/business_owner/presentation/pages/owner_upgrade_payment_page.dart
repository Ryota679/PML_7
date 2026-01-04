import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kantin_app/features/tenant/providers/billing_provider.dart';

/// Owner Business Premium upgrade payment page
class OwnerUpgradePaymentPage extends ConsumerWidget {
  const OwnerUpgradePaymentPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upgrade ke Owner Premium'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            const Icon(
              Icons.diamond,
              size: 80,
              color: Colors.purple,
            ),
            const SizedBox(height: 16),
            const Text(
              'Upgrade ke Owner Premium',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 32),

            // Pricing Card
            _buildPricingCard(),
            const SizedBox(height: 24),

            // Benefits
            _buildBenefits(),
            const SizedBox(height: 32),

            // Payment Section
            _buildBillingSection(ref),
            const SizedBox(height: 16),

            // Return
            TextButton(
              onPressed: () => context.pop(),
              child: const Text('Kembali'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPricingCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Text(
              'Owner Business Premium',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Rp',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 4),
                const Text(
                  '99.000',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '/bulan',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBenefits() {
    final benefits = [
      'Unlimited tenants',
      'Unlimited users',
      'Edit tenant & user data',
      'Advanced analytics (coming soon)',
      'Export reports (coming soon)',
      'Priority support',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Keuntungan Premium:',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ...benefits.map((benefit) => Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      benefit,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }

  Widget _buildBillingSection(WidgetRef ref) {
    final billingStateVal = ref.watch(billingServiceProvider);

    return billingStateVal.when(
      data: (billingState) {
        if (!billingState.isAvailable) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Google Play Billing tidak tersedia di perangkat ini.',
                style: TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        if (billingState.products.isEmpty) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 8),
                  Text('Memuat produk langganan...'),
                ],
              ),
            ),
          );
        }

        // Filter specifically for Owner Product
        final ownerProducts =
            billingState.products.where((p) => p.id == 'owner_pro_monthly');

        if (ownerProducts.isEmpty) {
          // Fallback UI if specifically owner product is missing but others exist
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('Paket Owner tidak ditemukan di Google Play.'),
            ),
          );
        }

        final product = ownerProducts.first;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.purple.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.purple),
          ),
          child: Column(
            children: [
              const Icon(
                Icons.android,
                color: Colors.purple,
                size: 32,
              ),
              const SizedBox(height: 12),
              Text(
                product.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                product.description,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  // Pass the specific product ID
                  ref
                      .read(billingServiceProvider.notifier)
                      .purchaseSubscription(product.id);
                },
                icon: const Icon(Icons.shopping_cart),
                label: Text('Langganan ${product.price}'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  textStyle: const TextStyle(fontSize: 16),
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  ref.read(billingServiceProvider.notifier).restorePurchases();
                },
                child: const Text('Pulihkan Pembelian (Restore)'),
              ),
            ],
          ),
        );
      },
      error: (err, stack) => Card(
        color: Colors.red.shade50,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text('Error: $err'),
        ),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
    );
  }
}
