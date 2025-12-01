import 'dart:async';
import 'package:appwrite/appwrite.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:kantin_app/core/config/appwrite_config.dart';
import 'package:kantin_app/core/providers/appwrite_provider.dart';
import 'package:kantin_app/shared/models/order_model.dart';
import 'package:kantin_app/features/tenant/providers/tenant_orders_provider.dart';

/// Tenant Order Dashboard Page
/// 
/// Menampilkan semua pesanan untuk tenant dengan real-time updates via WebSocket
class TenantOrderDashboardPage extends ConsumerStatefulWidget {
  const TenantOrderDashboardPage({super.key});

  @override
  ConsumerState<TenantOrderDashboardPage> createState() =>
      _TenantOrderDashboardPageState();
}

class _TenantOrderDashboardPageState
    extends ConsumerState<TenantOrderDashboardPage> {
  RealtimeSubscription? _realtimeSubscription;
  OrderStatus? _selectedStatus;

  @override
  void initState() {
    super.initState();
    _setupRealtimeListener();
  }

  @override
  void dispose() {
    _realtimeSubscription?.close();
    super.dispose();
  }

  void _setupRealtimeListener() {
    // Setup Appwrite Realtime untuk listen perubahan di orders collection
    final realtime = ref.read(realtimeProvider);
    
    _realtimeSubscription = realtime.subscribe([
      'databases.${AppwriteConfig.databaseId}.collections.${AppwriteConfig.ordersCollectionId}.documents'
    ]);

    _realtimeSubscription!.stream.listen((response) {
      if (mounted) {
        // Check event type
        final events = response.events;
        
        // Auto-refresh jika ada order baru, update, atau delete
        if (events.any((event) => 
            event.contains('databases.*.collections.*.documents.*.create') ||
            event.contains('databases.*.collections.*.documents.*.update') ||
            event.contains('databases.*.collections.*.documents.*.delete'))) {
          
          // Refresh order list
          ref.invalidate(tenantOrdersProvider);
          
          // Optional: Show snackbar untuk new orders
          if (events.any((e) => e.contains('.create'))) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('📋 Pesanan baru masuk!'),
                duration: Duration(seconds: 2),
                backgroundColor: Colors.blue,
              ),
            );
          }
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(tenantOrdersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pesanan Masuk'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(tenantOrdersProvider);
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Status Filter Tabs
          _buildStatusFilter(),
          
          // Orders List
          Expanded(
            child: ordersAsync.when(
              data: (orders) {
                // Filter by selected status
                final filteredOrders = _selectedStatus == null
                    ? orders
                    : orders
                        .where((order) => order.status == _selectedStatus)
                        .toList();

                if (filteredOrders.isEmpty) {
                  return _buildEmptyState();
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(tenantOrdersProvider);
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredOrders.length,
                    itemBuilder: (context, index) {
                      return _buildOrderCard(filteredOrders[index]);
                    },
                  ),
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red.shade300,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Gagal memuat pesanan',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      error.toString(),
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: () {
                        ref.invalidate(tenantOrdersProvider);
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusFilter() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            _buildFilterChip(
              label: 'Semua',
              isSelected: _selectedStatus == null,
              onTap: () {
                setState(() {
                  _selectedStatus = null;
                });
              },
            ),
            const SizedBox(width: 8),
            _buildFilterChip(
              label: 'Menunggu',
              color: OrderStatus.pending.color,
              isSelected: _selectedStatus == OrderStatus.pending,
              onTap: () {
                setState(() {
                  _selectedStatus = OrderStatus.pending;
                });
              },
            ),
            const SizedBox(width: 8),
            _buildFilterChip(
              label: 'Dikonfirmasi',
              color: OrderStatus.confirmed.color,
              isSelected: _selectedStatus == OrderStatus.confirmed,
              onTap: () {
                setState(() {
                  _selectedStatus = OrderStatus.confirmed;
                });
              },
            ),
            const SizedBox(width: 8),
            _buildFilterChip(
              label: 'Diproses',
              color: OrderStatus.preparing.color,
              isSelected: _selectedStatus == OrderStatus.preparing,
              onTap: () {
                setState(() {
                  _selectedStatus = OrderStatus.preparing;
                });
              },
            ),
            const SizedBox(width: 8),
            _buildFilterChip(
              label: 'Siap',
              color: OrderStatus.ready.color,
              isSelected: _selectedStatus == OrderStatus.ready,
              onTap: () {
                setState(() {
                  _selectedStatus = OrderStatus.ready;
                });
              },
            ),
            const SizedBox(width: 8),
            _buildFilterChip(
              label: 'Selesai',
              color: OrderStatus.completed.color,
              isSelected: _selectedStatus == OrderStatus.completed,
              onTap: () {
                setState(() {
                  _selectedStatus = OrderStatus.completed;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    Color? color,
  }) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
      backgroundColor: color?.withOpacity(0.1),
      selectedColor: color ?? Theme.of(context).colorScheme.primaryContainer,
      checkmarkColor: isSelected
          ? (color ?? Theme.of(context).colorScheme.onPrimaryContainer)
          : null,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 80,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            _selectedStatus == null
                ? 'Belum ada pesanan'
                : 'Tidak ada pesanan ${_selectedStatus!.label}',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.grey.shade600,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Pesanan akan muncul di sini secara otomatis',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade500,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(OrderModel order) {
    final queueNumber = order.getQueueNumber();
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          _showOrderDetails(order);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Order Number & Status
              Row(
                children: [
                  // Queue Number Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: order.status.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: order.status.color.withOpacity(0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.confirmation_number,
                          size: 18,
                          color: order.status.color,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          queueNumber,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: order.status.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Status Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: order.status.color,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      order.status.label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Time
                  Text(
                    DateFormat('HH:mm').format(order.createdAt),
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Customer Info
              Row(
                children: [
                  Icon(Icons.person, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      order.customerName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
              ),
              if (order.tableNumber != null && order.tableNumber!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.table_bar, size: 16, color: Colors.grey.shade600),
                    const SizedBox(width: 8),
                    Text(
                      'Meja ${order.tableNumber}',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
              
              const Divider(height: 24),
              
              // Items Summary
              Text(
                '${order.items?.length ?? 0} Item',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 8),
              // Item list (max 3 items shown)
              ...((order.items ?? []).take(3).map((item) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Center(
                          child: Text(
                            '${item.quantity}x',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item.productName,
                          style: const TextStyle(fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              })),
              if ((order.items?.length ?? 0) > 3)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '+${(order.items!.length - 3)} item lainnya',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              
              const Divider(height: 24),
              
              // Total & Action
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          formatter.format(order.totalAmount),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Action Button (Next Status)
                  if (order.status != OrderStatus.completed && 
                      order.status != OrderStatus.cancelled)
                    FilledButton.icon(
                      onPressed: () {
                        _showStatusUpdateDialog(order);
                      },
                      icon: const Icon(Icons.arrow_forward, size: 18),
                      label: Text(_getNextStatusLabel(order.status)),
                      style: FilledButton.styleFrom(
                        backgroundColor: _getNextStatusColor(order.status),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getNextStatusLabel(OrderStatus currentStatus) {
    switch (currentStatus) {
      case OrderStatus.pending:
        return 'Konfirmasi';
      case OrderStatus.confirmed:
        return 'Proses';
      case OrderStatus.preparing:
        return 'Siap';
      case OrderStatus.ready:
        return 'Selesai';
      default:
        return 'Update';
    }
  }

  Color _getNextStatusColor(OrderStatus currentStatus) {
    switch (currentStatus) {
      case OrderStatus.pending:
        return OrderStatus.confirmed.color;
      case OrderStatus.confirmed:
        return OrderStatus.preparing.color;
      case OrderStatus.preparing:
        return OrderStatus.ready.color;
      case OrderStatus.ready:
        return OrderStatus.completed.color;
      default:
        return Colors.grey;
    }
  }

  void _showOrderDetails(OrderModel order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        final formatter = NumberFormat.currency(
          locale: 'id_ID',
          symbol: 'Rp ',
          decimalDigits: 0,
        );

        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                // Handle bar
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Content
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(24),
                    children: [
                      Text(
                        'Detail Pesanan',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Customer Info
                      _buildDetailRow('Customer', order.customerName),
                      _buildDetailRow('No. HP', order.customerContact),
                      if (order.tableNumber != null && order.tableNumber!.isNotEmpty)
                        _buildDetailRow('Lokasi', order.tableNumber!),
                      _buildDetailRow('No. Antrian', order.getQueueNumber()),
                      _buildDetailRow('No. Pesanan', order.orderNumber),
                      _buildDetailRow(
                        'Waktu',
                        DateFormat('dd MMM yyyy, HH:mm').format(order.createdAt),
                      ),
                      
                      const Divider(height: 32),
                      
                      // Items
                      Text(
                        'Pesanan',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 16),
                      ...(order.items ?? []).map((item) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primaryContainer,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Center(
                                  child: Text(
                                    '${item.quantity}x',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onPrimaryContainer,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.productName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    if (item.notes != null && item.notes!.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: Text(
                                          'Catatan: ${item.notes}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade600,
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              Text(
                                formatter.format(item.subtotal),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                      
                      const Divider(height: 24),
                      
                      // Total
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            formatter.format(order.totalAmount),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      
                      if (order.notes != null && order.notes!.isNotEmpty) ...[
                        const Divider(height: 32),
                        Text(
                          'Catatan',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            order.notes!,
                            style: TextStyle(color: Colors.grey.shade700),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showStatusUpdateDialog(OrderModel order) {
    // TODO: Implement in Phase 2
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Fitur update status akan tersedia di Phase 2'),
      ),
    );
  }
}
