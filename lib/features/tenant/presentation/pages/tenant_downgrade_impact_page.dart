import 'package:flutter/material.dart';
import 'package:kantin_app/shared/models/tenant_model.dart';

/// Tenant Downgrade Impact Page
/// 
/// Educational page for Tenant users explaining trial→free impact
/// Shows tenant-specific features, examples, and self-upgrade option only
class TenantDowngradeImpactPage extends StatelessWidget {
  final TenantModel tenant;
  
  const TenantDowngradeImpactPage({
    super.key,
    required this.tenant,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Penurunan ke Free Tier'),
        backgroundColor: Colors.purple.shade700,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Header
            _buildHeaderCard(context),
            
            const SizedBox(height: 24),
            
            // 2. Comparison Table - Tenant specific
            _buildComparisonSection(context),
            
            const SizedBox(height: 24),
            
            // 3. Examples - Tenant specific
            _buildExamplesSection(context),
            
            const SizedBox(height: 24),
            
            const Divider(thickness: 2),
            const SizedBox(height: 24),
            
            // 4. Upgrade Option (self-upgrade only)
            Text(
              '🎯 Upgrade ke Premium',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            Text(
              'Tetap gunakan fitur premium dengan berlangganan.',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            
            _buildUpgradeOption(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard(BuildContext context) {
    // TODO: Get actual trial expiry from tenant data
    const daysRemaining = 5; // Placeholder
    
    return Card(
      elevation: 4,
      color: Colors.purple.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.purple.shade300, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.purple.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.schedule,
                size: 40,
                color: Colors.purple.shade700,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Trial Premium',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: Colors.grey.shade700,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Berakhir dalam $daysRemaining hari',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.purple.shade900,
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.compare_arrows, color: Colors.purple.shade700),
                const SizedBox(width: 8),
                Text(
                  '📊 Perbandingan Fitur Tenant',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            _buildComparisonRow(
              'Kelola Produk',
              premium: '✅ Tambah/Edit Unlimited',
              free: '❌ View + Delete saja',
            ),
            _buildComparisonRow(
              'Kelola Kategori',
              premium: '✅ Tambah/Edit Unlimited',
              free: '❌ View + Delete saja',
            ),
            _buildComparisonRow(
              'Kelola Staff',
              premium: '✅ Tambah/Edit Unlimited',
              free: '❌ View + Delete saja',
            ),
            _buildComparisonRow(
              'Laporan Saya',
              premium: '✅ Analytics Lengkap',
              free: '❌ Terkunci',
            ),
            _buildComparisonRow(
              'Export Reports',
              premium: '✅ PDF & Excel',
              free: '❌ Tidak Bisa',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComparisonRow(String feature, {required String premium, required String free}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              feature,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              premium,
              style: const TextStyle(fontSize: 13),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              free,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExamplesSection(BuildContext context) {
    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb_outline, color: Colors.blue.shade700, size: 28),
                const SizedBox(width: 8),
                Text(
                  '💡 Contoh Dampak Free Tier',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade900,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            _buildExampleItem(
              '🍔 Tambah Produk Baru',
              'Premium: Bisa tambah produk baru kapan saja, misal menu spesial "Nasi Goreng Pete"\n'
              'Free: Tombol "Tambah Produk" disabled. Klik = muncul upgrade dialog',
            ),
            _buildExampleItem(
              '✏️ Edit Harga Produk',
              'Premium: Harga naik? Langsung edit aja, misal "Es Teh" dari 3rb jadi 5rb\n'
              'Free: Tombol "Edit" disabled. Hanya bisa lihat harga lama. Mau ganti? Upgrade dulu!',
            ),
            _buildExampleItem(
              '👨‍🍳 Tambah Staff',
              'Premium: Bisa invite staff baru untuk bantu kelola warung\n'
              'Free: Menu "Kelola Staff" terkunci. Tidak bisa tambah/edit staff',
            ),
            _buildExampleItem(
              '📊 Lihat Laporan Penjualan',
              'Premium: Menu "Laporan Saya" tampil grafik penjualan harian, produk terlaris, omset bulanan\n'
              'Free: Menu terkunci dengan ikon gembok. Klik = upgrade dialog',
            ),
            _buildExampleItem(
              '📂 Export Data',
              'Premium: Bisa download laporan dalam PDF atau Excel untuk arsip\n'
              'Free: Tombol export tidak muncul sama sekali',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExampleItem(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade700,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpgradeOption(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.workspace_premium, color: Colors.purple.shade700, size: 28),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Upgrade Tenant Premium',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Rp 49.000/bulan',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.purple.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Premium untuk tenant "${tenant.name}" saja.',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            
            // IMPORTANT: Pause mechanism explanation
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Keuntungan Subscription Pause',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade900,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Jika sewaktu-waktu Business Owner upgrade ke premium saat tenant Anda sudah berlangganan:',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 6),
                  _buildPausePoint('Subscription Anda otomatis PAUSE (tidak hilang)'),
                  _buildPausePoint('Anda tetap dapat premium (via BO, GRATIS)'),
                  _buildPausePoint('Sisa hari langganan tersimpan untuk nanti'),
                  _buildPausePoint('Jika BO downgrade lagi, subscription Anda auto-resume', bold: true),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => _showPayment(context),
              icon: const Icon(Icons.credit_card),
              label: const Text('Bayar Rp 49.000/bulan'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.purple.shade700,
                side: BorderSide(color: Colors.purple.shade300),
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPausePoint(String text, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontSize: 14)),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showPayment(BuildContext context) {
    // TODO: Navigate to payment page
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('🚧 Payment integration coming soon')),
    );
  }
}
