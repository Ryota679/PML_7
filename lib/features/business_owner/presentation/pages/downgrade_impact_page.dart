import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_app/shared/models/user_model.dart';
import 'package:kantin_app/shared/models/tenant_model.dart';
import 'package:kantin_app/features/business_owner/providers/tenant_provider.dart';
import 'package:kantin_app/features/business_owner/presentation/pages/tenant_selection_page.dart';
import 'package:kantin_app/features/business_owner/presentation/widgets/swap_used_banner.dart';

/// Downgrade Impact Page - Business Owner (MODERN UI)
/// 
/// Educational page explaining trial→free tier impact
/// Features: Modern gradients, glassmorphism, better visual hierarchy
class DowngradeImpactPage extends ConsumerWidget {
  final UserModel user;
  
  const DowngradeImpactPage({
    super.key,
    required this.user,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tenantsState = ref.watch(myTenantsProvider);
    
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text(
          'Penurunan ke Free Tier',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.purple.shade700, Colors.purple.shade500],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Header with countdown - MODERN
            _buildHeaderCard(context),
            
            const SizedBox(height: 24),
            
            // 2. Comparison Table - MODERN
            _buildComparisonSection(context),
            
            const SizedBox(height: 24),
            
            // 3. Examples with scenarios - MODERN
            _buildExamplesSection(context),
            
            const SizedBox(height: 32),
            
            // 4. Action Section - ONLY show if swap NOT used
            // If swap used, skip this section (upgrade CTA is enough)
            if (user.swapUsed != true) ...[
              Text(
                '🎯 Persiapan Downgrade',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Pilih tenant yang akan tetap aktif setelah trial berakhir.',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
              ),
              const SizedBox(height: 20),
              
              // 5. Tenant Selection Card - MODERN
              if (tenantsState.tenants.length > 2)
                _buildTenantSelectionCard(context, tenantsState.tenants)
              else
                _buildAutoSelectedCard(context, tenantsState.tenants.length),
              
              const SizedBox(height: 24),
            ],
            
            // Swap banner removed - upgrade CTA is enough
            
            // 6. Upgrade CTA - MODERN
            _buildUpgradeCard(context),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard(BuildContext context) {
    final daysRemaining = user.subscriptionExpiresAt
        ?.difference(DateTime.now()).inDays ?? 0;
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple.shade400, Colors.purple.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.schedule,
                size: 44,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Trial Premium',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Berakhir dalam $daysRemaining hari',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 26,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComparisonSection(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade400, Colors.blue.shade600],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.compare_arrows,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Perbandingan Fitur',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Table Header
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.grey.shade100, Colors.grey.shade50],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Expanded(flex: 2, child: Text('Fitur', style: TextStyle(fontWeight: FontWeight.bold))),
                  Expanded(flex: 2, child: Text('Premium', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green))),
                  Expanded(flex: 2, child: Text('Free', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange))),
                ],
              ),
            ),
            const SizedBox(height: 12),
            
            _buildComparisonRow('Kelola Tenant', premium: 'CRUD Unlimited', free: 'View + Delete'),
            const Divider(height: 24),
            _buildComparisonRow('Kelola User', premium: 'CRUD Unlimited', free: 'View + Delete'),
            const Divider(height: 24),
            _buildComparisonRow('Akses Tenant', premium: 'Semua tenant', free: 'Maksimal 2'),
            const Divider(height: 24),
            _buildComparisonRow('User/Tenant', premium: 'Unlimited', free: 'Maksimal 1'),
            const Divider(height: 24),
            _buildComparisonRow('Analytics', premium: 'Full Access', free: 'Terkunci'),
            const Divider(height: 24),
            _buildComparisonRow('Export', premium: 'PDF & Excel', free: 'No Export'),
          ],
        ),
      ),
    );
  }

  Widget _buildComparisonRow(String feature, {required String premium, required String free}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              feature,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.black87, // FIXED: Darker text for better contrast
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 18),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    premium,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.black87, // FIXED: Darker text
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Icon(
                  free.contains('Maksimal') ? Icons.warning : Icons.cancel,
                  color: free.contains('Maksimal') ? Colors.orange.shade700 : Colors.red.shade700,
                  size: 18,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    free,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.black87, // FIXED: Darker text
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExamplesSection(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade50, Colors.cyan.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.blue.shade200, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade600,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.lightbulb, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 12),
                Text(
                  'Contoh Dampak Free Tier',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.blue.shade900,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            _buildExampleItem(
              '📝 Tambah Tenant Baru',
              'Premium: Bisa buat tenant baru kapan saja\n'
              'Free: Tombol disabled jika sudah 2 tenant',
              Icons.store,
            ),
            _buildExampleItem(
              '✏️ Edit Data Tenant',
              'Premium: Edit semua tenant\n'
              'Free: Hanya 2 tenant terpilih. Lainnya view only',
              Icons.edit,
            ),
            _buildExampleItem(
              '👥 Kelola User',
              'Premium: Unlimited user per tenant\n'
              'Free: Maksimal 1 user per tenant',
              Icons.people,
            ),
            _buildExampleItem(
              '📊 Lihat Analytics',
              'Premium: Dashboard analytics lengkap\n'
              'Free: Menu terkunci',
              Icons.analytics,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExampleItem(String title, String description, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.blue.shade700, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Colors.black87, // FIXED: Darker title
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.black87, // FIXED: Much darker for readability
                    height: 1.6,
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

  Widget _buildTenantSelectionCard(BuildContext context, List<TenantModel> tenants) {
    final hasSelected = user.selectionSubmittedAt != null;
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: hasSelected 
              ? [Colors.green.shade400, Colors.green.shade600]
              : [Colors.orange.shade400, Colors.orange.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (hasSelected ? Colors.green : Colors.orange).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  hasSelected ? Icons.check_circle : Icons.warning_amber,
                  color: Colors.white,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    hasSelected ? 'Pilihan Tersimpan' : 'Pilih 2 Tenant',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              hasSelected
                  ? 'Anda sudah memilih 2 tenant. Bisa diubah sebelum trial berakhir.'
                  : 'Pilih 2 tenant berdasarkan performa untuk tetap aktif.',
              style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.95)),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () => _showTenantSelectionPage(context, tenants),
              icon: Icon(hasSelected ? Icons.edit : Icons.checklist),
              label: Text(hasSelected ? 'Ubah Pilihan' : 'Pilih Sekarang'),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: hasSelected ? Colors.green.shade700 : Colors.orange.shade700,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAutoSelectedCard(BuildContext context, int tenantCount) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade100, Colors.green.shade50],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.shade300, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green.shade700, size: 40),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Semua Tenant Sudah Sesuai',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.green.shade900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Anda punya $tenantCount tenant (≤2). Semua tetap aktif.',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpgradeCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.deepOrange.shade600, Colors.orange.shade500],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.4),
            blurRadius: 25,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            const Icon(Icons.workspace_premium, color: Colors.white, size: 56),
            const SizedBox(height: 16),
            const Text(
              'Upgrade ke Premium',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Rp 149.000',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const Text(
              '/bulan',
              style: TextStyle(
                fontSize: 18,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Unlimited tenants • Full analytics • Export reports',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 14),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('🚧 Payment integration coming soon')),
                );
              },
              icon: const Icon(Icons.arrow_forward),
              label: const Text('Upgrade Sekarang'),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.orange.shade700,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 18),
                textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTenantSelectionPage(BuildContext context, List<TenantModel> tenants) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TenantSelectionPage(
          userId: user.userId,
          tenants: tenants,
        ),
      ),
    );
  }
}
