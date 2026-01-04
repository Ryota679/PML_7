import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kantin_app/features/auth/providers/auth_provider.dart';
import 'package:kantin_app/features/tenant/providers/upgrade_token_provider.dart';
import 'package:kantin_app/features/tenant/providers/billing_provider.dart';

/// Public payment page for tenant premium upgrade
/// Accessible without authentication via secure token
class TenantUpgradePaymentPage extends ConsumerStatefulWidget {
  final String token;

  const TenantUpgradePaymentPage({
    super.key,
    required this.token,
  });

  @override
  ConsumerState<TenantUpgradePaymentPage> createState() =>
      _TenantUpgradePaymentPageState();
}

class _TenantUpgradePaymentPageState
    extends ConsumerState<TenantUpgradePaymentPage> {
  bool _isLoading = true;
  String? _errorMessage;
  String? _userEmail;

  @override
  void initState() {
    super.initState();
    _validateToken();
  }

  Future<void> _validateToken() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // Validate token
    final tokenData =
        ref.read(upgradeTokenProvider.notifier).validateToken(widget.token);

    if (tokenData == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Token tidak valid atau sudah kadaluarsa';
      });
      return;
    }

    setState(() {
      _isLoading = false;
      _userEmail = tokenData.userEmail;
    });

    // Clear deactivated flag now that we're successfully on payment page
    ref.read(authProvider.notifier).clearDeactivatedFlag();
    
if (kDebugMode) print('✅ [PAYMENT] Token validated for: ${tokenData.userEmail}');
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red,
                ),
                const SizedBox(height: 24),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => context.go('/guest'),
                  child: const Text('Kembali ke Halaman Utama'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Upgrade Premium'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/guest'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            const Icon(
              Icons.workspace_premium,
              size: 80,
              color: Colors.amber,
            ),
            const SizedBox(height: 16),
            const Text(
              'Upgrade ke Premium',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Akun: $_userEmail',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 32),

            // Pricing Card
            _buildPricingCard(),
            const SizedBox(height: 24),

            // Self-Paid Benefits Explanation
            _buildSelfPaidExplanation(),
            const SizedBox(height: 24),

            // Benefits
            _buildBenefits(),
            const SizedBox(height: 32),

            // Payment Section
            _buildBillingSection(),
            const SizedBox(height: 16),

            // Return to Login
            TextButton(
              onPressed: () => context.go('/login'),
              child: const Text('Kembali ke Login'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBillingSection() {
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

        // Filter specifically for Tenant Product
        final tenantProducts = billingState.products.where((p) => p.id == 'premium_tenant_monthly');

        if (tenantProducts.isEmpty) {
             // Fallback UI if specifically tenant product is missing but others exist
             return const Card(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('Paket Tenant tidak ditemukan di Google Play.'),
                ),
             );
        }

        final product = tenantProducts.first;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green),
          ),
          child: Column(
            children: [
              const Icon(
                Icons.android,
                color: Colors.green,
                size: 32,
              ),
              // ... existing UI code ...
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                   // Pass the specific product ID
                   ref.read(billingServiceProvider.notifier).purchaseSubscription(product.id);
                },
                icon: const Icon(Icons.shopping_cart),
                label: Text('Langganan ${product.price}'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  textStyle: const TextStyle(fontSize: 16),
                  backgroundColor: Colors.green,
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

  Widget _buildPricingCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Text(
              'Premium Tenant',
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
                  '49.000',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber,
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

  Widget _buildSelfPaidExplanation() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: Colors.blue.shade700,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Tentang Akun Premium Mandiri',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Dengan upgrade sendiri, akun Anda akan menjadi:',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 12),
          _buildExplanationPoint(
            Icons.check_circle,
            'Aktif Otomatis',
            'Akun langsung aktif setelah pembayaran berhasil',
          ),
          const SizedBox(height: 8),
          _buildExplanationPoint(
            Icons.shield,
            'Tidak Bisa Di-nonaktifkan',
            'Business Owner tidak bisa menonaktifkan akun Anda',
          ),
          const SizedBox(height: 8),
          _buildExplanationPoint(
            Icons.account_circle,
            'Akun Independen',
            'Anda yang mengontrol status premium, bukan Business Owner',
          ),
          const SizedBox(height: 8),
          _buildExplanationPoint(
            Icons.trending_up,
            'Tidak Dihitung Kuota',
            'Tidak masuk hitungan batas tenant gratis Business Owner',
          ),
        ],
      ),
    );
  }

  Widget _buildExplanationPoint(IconData icon, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: Colors.green.shade700,
          size: 20,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBenefits() {
    final benefits = [
      'Unlimited products',
      'Unlimited categories',
      'Real-time menu updates',
      'Priority support',
      'Custom branding',
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
}
