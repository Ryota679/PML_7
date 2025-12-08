import 'package:flutter/material.dart';
import 'package:kantin_app/shared/models/tenant_model.dart';
import 'package:kantin_app/features/business_owner/services/tenant_swap_service.dart';
import 'package:kantin_app/features/business_owner/services/tenant_stats_service.dart';
import 'package:kantin_app/features/business_owner/models/tenant_stats_model.dart';

/// Tenant Selection Page with Performance Stats
/// 
/// Full-page view for selecting 2 active tenants with data-driven insights
class TenantSelectionPage extends StatefulWidget {
  final String userId;
  final List<TenantModel> tenants;
  final bool isSwap;

  const TenantSelectionPage({
    super.key,
    required this.userId,
    required this.tenants,
    this.isSwap = false,
  });

  @override
  State<TenantSelectionPage> createState() => _TenantSelectionPageState();
}

class _TenantSelectionPageState extends State<TenantSelectionPage> {
  final _swapService = TenantSwapService();
  final _statsService = TenantStatsService();
  final Set<String> _selectedTenantIds = {};
  final Map<String, TenantStats> _stats = {};
  bool _isLoading = false;
  bool _statsLoading = true;

  @override
  void initState() {
    super.initState();
    
    // Pre-select based on current selection or newest 2
    if (widget.isSwap) {
      _selectedTenantIds.addAll(
        widget.tenants
            .where((t) => t.selectedForFreeTier == true)
            .map((t) => t.id)
            .take(2),
      );
    } else {
      _selectedTenantIds.addAll(
        widget.tenants.take(2).map((t) => t.id),
      );
    }
    
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final tenantIds = widget.tenants.map((t) => t.id).toList();
      final stats = await _statsService.getBatchStats(tenantIds);
      
      if (mounted) {
        setState(() {
          _stats.addAll(stats);
          _statsLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _statsLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final canSave = _selectedTenantIds.length == 2;

    return Scaffold(
      backgroundColor: Colors.grey.shade900,
      appBar: AppBar(
        backgroundColor: Colors.grey.shade900,
        foregroundColor: Colors.white,
        title: Text(widget.isSwap ? 'Tukar Pilihan Tenant' : 'Pilih 2 Tenant Aktif'),
        actions: [
          if (canSave)
            TextButton.icon(
              onPressed: _isLoading ? null : _saveSelection,
              icon: _isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.check, color: Colors.greenAccent),
              label: Text(
                _isLoading ? 'Menyimpan...' : 'Simpan',
                style: const TextStyle(color: Colors.greenAccent),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Info banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.blue.shade900.withOpacity(0.3),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.lightBlueAccent, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.isSwap
                            ? 'Pilih 2 tenant berdasarkan performa 30 hari terakhir'
                            : 'Akun free hanya bisa memiliki 2 tenant aktif',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: canSave ? Colors.green.shade800 : Colors.orange.shade800,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        canSave ? Icons.check_circle : Icons.error_outline,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Dipilih: ${_selectedTenantIds.length} / 2',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Tenant list
          Expanded(
            child: _statsLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: widget.tenants.length,
                    itemBuilder: (context, index) {
                      final tenant = widget.tenants[index];
                      final isSelected = _selectedTenantIds.contains(tenant.id);
                      final isNewest = index < 2;
                      final stats = _stats[tenant.id];

                      return _buildTenantCard(
                        tenant: tenant,
                        stats: stats,
                        isSelected: isSelected,
                        isNewest: isNewest && !widget.isSwap,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTenantCard({
    required TenantModel tenant,
    required TenantStats? stats,
    required bool isSelected,
    required bool isNewest,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: isSelected ? Colors.blue.shade900.withOpacity(0.5) : Colors.grey.shade800,
      elevation: isSelected ? 4 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isSelected
            ? BorderSide(color: Colors.blueAccent, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: () => _toggleSelection(tenant.id),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  // Checkbox
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.blueAccent : Colors.transparent,
                      border: Border.all(
                        color: isSelected ? Colors.blueAccent : Colors.grey.shade600,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, color: Colors.white, size: 16)
                        : null,
                  ),
                  const SizedBox(width: 12),

                  // Tenant icon
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.blue.shade700,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.store, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),

                  // Tenant info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tenant.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          tenant.type.label ?? 'Tenant',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade400,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Badges
                  if (isNewest)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.shade700,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        '✨ Terbaru',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),

              // Stats section
              if (stats != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade700, width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Performance header
                      Row(
                        children: [
                          const Text(
                            '📊 Performa 30 Hari',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            stats.trendIcon,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // 2-column stats
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatItem(
                              '💰',
                              stats.formattedRevenue,
                              'Omset',
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildStatItem(
                              '🛒',
                              '${stats.transactionCount}x',
                              'Transaksi',
                            ),
                          ),
                        ],
                      ),

                      // Top products
                      if (stats.topProducts.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        Divider(height: 1, color: Colors.grey.shade700),
                        const SizedBox(height: 10),
                        const Text(
                          '🏆 Top 5 Produk Terlaris:',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...stats.topProducts.asMap().entries.map((e) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              children: [
                                Container(
                                  width: 20,
                                  height: 20,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: _getProductBadgeColor(e.key),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    '${e.key + 1}',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    e.value.productName,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.white,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade800,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '${e.value.soldCount}x',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String icon, String value, String label) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade800,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade700),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(icon, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade400,
            ),
          ),
        ],
      ),
    );
  }

  Color _getProductBadgeColor(int index) {
    switch (index) {
      case 0:
        return Colors.amber.shade700; // Gold
      case 1:
        return Colors.grey.shade400;  // Silver
      case 2:
        return Colors.brown.shade600; // Bronze
      default:
        return Colors.blue.shade600;  // Blue for 4-5
    }
  }

  void _toggleSelection(String tenantId) {
    setState(() {
      if (_selectedTenantIds.contains(tenantId)) {
        _selectedTenantIds.remove(tenantId);
      } else {
        if (_selectedTenantIds.length < 2) {
          _selectedTenantIds.add(tenantId);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Maksimal 2 tenant yang bisa dipilih'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    });
  }

  Future<void> _saveSelection() async {
    setState(() => _isLoading = true);

    try {
      if (widget.isSwap) {
        await _swapService.useSwapOpportunity(
          userId: widget.userId,
          newSelectedTenantIds: _selectedTenantIds.toList(),
        );
      } else {
        await _swapService.saveSelection(
          userId: widget.userId,
          selectedTenantIds: _selectedTenantIds.toList(),
        );
      }

      if (mounted) {
        Navigator.pop(context, true);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.isSwap
                  ? '✅ Pilihan tenant berhasil diubah!'
                  : '✅ Pilihan tenant berhasil disimpan!',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Gagal menyimpan: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}
