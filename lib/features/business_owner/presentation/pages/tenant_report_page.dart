import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_app/features/business_owner/models/tenant_stats_model.dart';
import 'package:kantin_app/features/business_owner/services/tenant_stats_service.dart';
import 'package:kantin_app/shared/models/tenant_model.dart';
import 'package:kantin_app/features/business_owner/providers/tenant_provider.dart';

/// Tenant Report Page
/// 
/// Shows detailed statistics and performance data for a single tenant
class TenantReportPage extends ConsumerStatefulWidget {
  final String? tenantId; // Optional - if null, show tenant list

  const TenantReportPage({
    super.key,
    this.tenantId,
  });

  @override
  ConsumerState<TenantReportPage> createState() => _TenantReportPageState();
}

class _TenantReportPageState extends ConsumerState<TenantReportPage> {
  final _statsService = TenantStatsService();
  TenantStats? _stats;
  bool _isLoading = true;
  String? _selectedTenantId;

  @override
  void initState() {
    super.initState();
    _selectedTenantId = widget.tenantId;
    
    if (_selectedTenantId != null) {
      _loadStats(_selectedTenantId!);
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadStats(String tenantId) async {
    setState(() => _isLoading = true);
    
    try {
      final stats = await _statsService.getTenantStats(tenantId);
      if (mounted) {
        setState(() {
          _stats = stats;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat statistik: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // If no tenant selected, show tenant list
    if (_selectedTenantId == null) {
      return _buildTenantListView();
    }

    // Show tenant report
    final tenantState = ref.watch(myTenantsProvider);
    final tenant = tenantState.tenants.firstWhere(
      (t) => t.id == _selectedTenantId,
      orElse: () => tenantState.tenants.first,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('Laporan - ${tenant.name}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadStats(_selectedTenantId!),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildReportContent(tenant),
    );
  }

  Widget _buildTenantListView() {
    final tenantState = ref.watch(myTenantsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan Tenant'),
      ),
      body: tenantState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : tenantState.tenants.isEmpty
              ? const Center(child: Text('Belum ada tenant'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: tenantState.tenants.length,
                  itemBuilder: (context, index) {
                    final tenant = tenantState.tenants[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue.shade100,
                          child: Text(
                            tenant.type.icon,
                            style: const TextStyle(fontSize: 24),
                          ),
                        ),
                        title: Text(tenant.name),
                        subtitle: Text(tenant.type.label),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          setState(() {
                            _selectedTenantId = tenant.id;
                          });
                          _loadStats(tenant.id);
                        },
                      ),
                    );
                  },
                ),
    );
  }

  Widget _buildReportContent(TenantModel tenant) {
    if (_stats == null) {
      return const Center(child: Text('Gagal memuat data'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Period info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today, color: Colors.blue.shade700),
                const SizedBox(width: 12),
                Text(
                  'Periode: 30 Hari Terakhir',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.blue.shade900,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Summary Section
          Text(
            '📊 Ringkasan',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  icon: Icons.attach_money,
                  iconColor: Colors.green,
                  label: 'Total Pendapatan',
                  value: _stats!.formattedRevenue,
                  trend: _stats!.trendIcon,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.receipt_long,
                  iconColor: Colors.blue,
                  label: 'Total Transaksi',
                  value: '${_stats!.transactionCount}',
                  trend: null,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          _buildStatCard(
            icon: Icons.calculate,
            iconColor: Colors.purple,
            label: 'Rata-rata per Transaksi',
            value: _stats!.formattedAverage,
            trend: null,
          ),

          const SizedBox(height: 32),

          // Top Products Section
          Row(
            children: [
              Text(
                '⭐ Top 5 Produk Terlaris',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          if (_stats!.topProducts.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.inventory_2_outlined,
                        size: 48, color: Colors.grey.shade400),
                    const SizedBox(height: 12),
                    Text(
                      'Belum ada transaksi',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ...List.generate(_stats!.topProducts.length, (index) {
              final product = _stats!.topProducts[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.orange.shade100,
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade700,
                      ),
                    ),
                  ),
                  title: Text(
                    product.productName,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text('${product.soldCount} terjual'),
                  trailing: Icon(
                    Icons.trending_up,
                    color: Colors.green.shade600,
                  ),
                ),
              );
            }),

          const SizedBox(height: 32),

          // Info footer
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.grey.shade700, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Data dihitung berdasarkan transaksi yang sudah selesai (completed)',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade700,
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

  Widget _buildStatCard({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    String? trend,
  }) {
    return Card(
      elevation: 0,
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
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                if (trend != null) ...[
                  const Spacer(),
                  Text(trend, style: const TextStyle(fontSize: 20)),
                ],
              ],
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
