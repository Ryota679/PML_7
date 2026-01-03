import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_app/shared/models/tenant_model.dart';
import 'package:kantin_app/features/business_owner/services/tenant_swap_service.dart';
import 'package:kantin_app/features/business_owner/services/tenant_stats_service.dart';
import 'package:kantin_app/features/business_owner/models/tenant_stats_model.dart';
import 'package:kantin_app/features/auth/providers/auth_provider.dart';
import 'package:kantin_app/features/business_owner/presentation/pages/downgrade_impact_page.dart';

/// Tenant Selection Page with Performance Stats
/// 
/// Full-page view for selecting 2 active tenants with data-driven insights
class TenantSelectionPage extends ConsumerStatefulWidget {
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
  ConsumerState<TenantSelectionPage> createState() => _TenantSelectionPageState();
}

class _TenantSelectionPageState extends ConsumerState<TenantSelectionPage> {
  final _statsService = TenantStatsService();
  final Set<String> _selectedTenantIds = {};
  final Set<String> _initialSelectedTenantIds = {}; // Track initial selection
  final Map<String, TenantStats> _stats = {};
  bool _isLoading = false;
  bool _statsLoading = true;

  @override
  void initState() {
    super.initState();
    
    // Pre-select based on current selection
    final currentlySelected = widget.tenants
        .where((t) => t.selectedForFreeTier == true)
        .map((t) => t.id)
        .toList();
    
    if (currentlySelected.isNotEmpty) {
      // Use existing selection if available
      _selectedTenantIds.addAll(currentlySelected.take(2));
    } else {
      // First-time selection: pre-select first 2
      _selectedTenantIds.addAll(
        widget.tenants.take(2).map((t) => t.id),
      );
    }
    
    // Save initial selection for comparison
    _initialSelectedTenantIds.addAll(_selectedTenantIds);
    
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
    // Validate: Check if selection has changed
    final hasChanged = _selectedTenantIds.length != _initialSelectedTenantIds.length ||
        !_selectedTenantIds.every((id) => _initialSelectedTenantIds.contains(id));
    
    if (!hasChanged) {
      // No changes detected
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.isSwap
                        ? 'Anda memilih tenant yang sama. Tidak ada perubahan.'
                        : 'Pilihan Anda sama dengan pilihan sebelumnya.',
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 3),
          ),
        );
      }
      return; // Don't save if no changes
    }
    
    // IMPORTANT: Show warning dialog if this is a swap (selection changed)
    // User only has 1x swap during trial, so confirm before using it
    if (hasChanged && _initialSelectedTenantIds.isNotEmpty) {
      // This is a SWAP (not first selection)
      final confirmed = await _showSwapWarningDialog();
      if (!confirmed) {
        return; // User cancelled
      }
    }
    
    setState(() => _isLoading = true);

    try {
      // Get swap service from provider
      final swapService = ref.read(tenantSwapServiceProvider);
      
      final result = await swapService.saveSelection(
        userId: widget.userId,
        selectedTenantIds: _selectedTenantIds.toList(),
      );

      // Handle result
      if (result['success'] == true) {
        // Success - refresh user data and show message
        if (mounted) {
          // IMPORTANT: Refresh user profile to update dashboard banners
          await ref.read(authProvider.notifier).refreshUserProfile();
          
          final swapUsed = result['swapUsed'] == true;
          
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                swapUsed
                    ? '✅ Pilihan tenant berhasil diubah! (Swap terpakai)'
                    : '✅ Pilihan tenant berhasil disimpan!',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
          
          // Just pop back to DowngradeImpactPage
          // (it's already in the navigation stack from the correct flow)
          Navigator.pop(context, true);
        }
      } else {
        // Error - check error type
        if (mounted) {
          setState(() => _isLoading = false);
          
          final errorCode = result['error'];
          if (errorCode == 'swap_limit_exceeded') {
            // Show upgrade dialog
            _showUpgradeDialog();
          } else {
            // Show generic error
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('❌ ${result['message'] ?? 'Gagal menyimpan'}'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Terjadi kesalahan: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
  
  /// Show warning dialog before using the single swap opportunity
  Future<bool> _showSwapWarningDialog() async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber, color: Colors.orange, size: 28),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                '⚠️ Ini Kesempatan Terakhir Anda',
                maxLines: 2,
                overflow: TextOverflow.visible,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Anda hanya bisa mengubah pilihan tenant 1x selama trial.',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, size: 18, color: Colors.orange.shade700),
                      const SizedBox(width: 6),
                      Text(
                        'Yang perlu Anda ketahui:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade900,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• Setelah ini, pilihan tidak bisa diubah lagi\n'
                    '• Untuk swap lagi, perlu upgrade ke Premium\n'
                    '• Pastikan pilihan Anda sudah tepat',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade800),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.orange.shade600,
            ),
            child: const Text('Lanjut Ubah'),
          ),
        ],
      ),
    ) ?? false; // Default to false if dismissed
  }
  
  /// Show upgrade dialog when swap limit exceeded
  void _showUpgradeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.lock, color: Colors.orange),
            const SizedBox(width: 8),
            const Text('Batas Swap Tercapai'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Anda sudah menggunakan kesempatan swap gratis Anda.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.purple.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.purple.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.diamond, color: Colors.purple.shade700, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Upgrade ke Premium',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.purple.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text('✅ Ubah tenant tanpa batas', style: TextStyle(fontSize: 13)),
                  const Text('✅ Unlock semua fitur premium', style: TextStyle(fontSize: 13)),
                  const Text('✅ Rp 149.000/bulan', style: TextStyle(fontSize: 13)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Navigate to upgrade page
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('💡 Upgrade page coming soon'),
                  backgroundColor: Colors.blue,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
            ),
            child: const Text('Upgrade Sekarang'),
          ),
        ],
      ),
    );
  }
}
