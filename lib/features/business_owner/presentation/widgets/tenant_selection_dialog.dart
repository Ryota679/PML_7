import 'package:flutter/material.dart';
import 'package:kantin_app/shared/models/tenant_model.dart';
import 'package:kantin_app/features/business_owner/services/tenant_swap_service.dart';
import 'package:kantin_app/features/business_owner/services/tenant_stats_service.dart';
import 'package:kantin_app/features/business_owner/models/tenant_stats_model.dart';

/// Tenant Selection Dialog with Inline Stats
/// 
/// Shows performance metrics to help business owners make informed decisions
class TenantSelectionDialog extends StatefulWidget {
  final String userId;
  final List<TenantModel> tenants;
  final bool isSwap;

  const TenantSelectionDialog({
    super.key,
    required this.userId,
    required this.tenants,
    this.isSwap = false,
  });

  @override
  State<TenantSelectionDialog> createState() => _TenantSelectionDialogState();
}

class _TenantSelectionDialogState extends State<TenantSelectionDialog> {
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
    
    // Load stats for all tenants
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

    return AlertDialog(
      title: Row(
        children: [
          Icon(
            widget.isSwap ? Icons.swap_horiz : Icons.check_circle_outline,
            color: Colors.blue,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              widget.isSwap ? 'Tukar Pilihan Tenant' : 'Pilih 2 Tenant Aktif',
              style: const TextStyle(fontSize: 18),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Instruction
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.isSwap
                          ? 'Pilih 2 tenant berdasarkan performa 30 hari terakhir.'
                          : 'Pilih 2 tenant terbaik berdasarkan omset dan transaksi.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.blue.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Selection counter
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: canSave ? Colors.green.shade50 : Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    canSave ? Icons.check_circle : Icons.error_outline,
                    color: canSave ? Colors.green : Colors.orange,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Dipilih: ${_selectedTenantIds.length} / 2',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: canSave ? Colors.green.shade900 : Colors.orange.shade900,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Tenant list
            Flexible(
              child: _statsLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      child: Column(
                        children: widget.tenants.asMap().entries.map((entry) {
                          final index = entry.key;
                          final tenant = entry.value;
                          final isSelected = _selectedTenantIds.contains(tenant.id);
                          final isNewest = index < 2;
                          final stats = _stats[tenant.id];

                          return _buildTenantCard(
                            tenant: tenant,
                            stats: stats,
                            isSelected: isSelected,
                            isNewest: isNewest && !widget.isSwap,
                          );
                        }).toList(),
                      ),
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        FilledButton.icon(
          onPressed: canSave && !_isLoading ? _saveSelection : null,
          icon: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Icon(Icons.save),
          label: Text(_isLoading ? 'Menyimpan...' : 'Simpan Pilihan'),
        ),
      ],
    );
  }

  Widget _buildTenantCard({
    required TenantModel tenant,
    required TenantStats? stats,
    required bool isSelected,
    required bool isNewest,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: isSelected ? Colors.blue.shade50 : null,
      elevation: isSelected ? 3 : 1,
      child: InkWell(
        onTap: () => _toggleSelection(tenant.id),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  // Checkbox
                  Checkbox(
                    value: isSelected,
                    onChanged: (_) => _toggleSelection(tenant.id),
                  ),
                  const SizedBox(width: 8),

                  // Tenant icon
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.store,
                      color: Colors.blue.shade700,
                      size: 20,
                    ),
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
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          tenant.type.label ?? 'Tenant',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Badges
                  if (isNewest)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '✨ Terbaru',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ),
                ],
              ),

              // Stats section
              if (stats != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade200),
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
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            stats.trendIcon,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

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
                          const SizedBox(width: 8),
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
                        const SizedBox(height: 10),
                        const Divider(height: 1),
                        const SizedBox(height: 8),
                        const Text(
                          '🏆 Top 5 Produk Terlaris:',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        ...stats.topProducts.asMap().entries.map((e) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 3),
                            child: Row(
                              children: [
                                Container(
                                  width: 16,
                                  height: 16,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: _getProductBadgeColor(e.key),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    '${e.key + 1}',
                                    style: const TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    e.value.productName,
                                    style: const TextStyle(fontSize: 11),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(
                                  '${e.value.soldCount}x',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey.shade600,
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
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(icon, style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Color _getProductBadgeColor(int index) {
    switch (index) {
      case 0:
        return Colors.amber.shade600;
      case 1:
        return Colors.grey.shade500;
      case 2:
        return Colors.brown.shade400;
      default:
        return Colors.blue.shade400;
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
                  ? 'Pilihan tenant berhasil diubah!'
                  : 'Pilihan tenant berhasil disimpan!',
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
            content: Text('Gagal menyimpan: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
