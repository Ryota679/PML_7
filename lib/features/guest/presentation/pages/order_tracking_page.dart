import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kantin_app/features/guest/providers/order_provider.dart';
import 'package:kantin_app/features/guest/providers/tenant_detail_provider.dart';
import 'package:kantin_app/shared/models/order_model.dart';

/// Order Tracking Page
/// Display order details and status for guest users
class OrderTrackingPage extends ConsumerWidget {
  final String orderNumber;

  const OrderTrackingPage({
    super.key,
    required this.orderNumber,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(orderByNumberProvider(orderNumber));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lacak Pesanan'),
      ),
      body: orderAsync.when(
        data: (order) {
          if (order == null) {
            return _buildOrderNotFound(context);
          }
          return _buildOrderDetails(context, ref, order);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _buildError(context, error.toString()),
      ),
    );
  }

  Widget _buildOrderDetails(BuildContext context, WidgetRef ref, OrderModel order) {
    final tenantAsync = ref.watch(tenantDetailProvider(order.tenantId));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Success Icon & Message
          Center(
            child: Column(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 48,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Pesanan Berhasil Dibuat!',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Simpan nomor pesanan Anda',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                tenantAsync.when(
                  data: (tenant) => Text(
                    'Pesan di: ${tenant?.name ?? "Kantin"}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  loading: () => const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Order Number Card
          Card(
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Nomor Pesanan',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    order.orderNumber,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Order Status
          _buildSectionHeader('Status Pesanan', Icons.info_outline),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: order.status.color.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _getStatusIcon(order.status),
                      color: order.status.color,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.status.label,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _getStatusDescription(order.status),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Customer Info
          _buildSectionHeader('Informasi Pelanggan', Icons.person_outline),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildInfoRow('Nama', order.customerName),
                  const Divider(height: 24),
                  _buildInfoRow('No. Telepon', order.customerContact),
                  const Divider(height: 24),
                  _buildInfoRow('No. Antrian', _getQueueNumber(order.orderNumber)),
                  if (order.tableNumber != null && order.tableNumber!.isNotEmpty) ...[
                    const Divider(height: 24),
                    _buildInfoRow('Lokasi', order.tableNumber!),
                  ],
                  if (order.notes != null && order.notes!.isNotEmpty) ...[
                    const Divider(height: 24),
                    _buildInfoRow('Catatan', order.notes!),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Order Items
          _buildSectionHeader('Detail Pesanan', Icons.receipt_long_outlined),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  if (order.items != null)
                    ...order.items!.map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${item.quantity}x',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.productName),
                                if (item.notes != null && item.notes!.isNotEmpty)
                                  Text(
                                    item.notes!,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Text(
                            'Rp ${item.subtotal.toString().replaceAllMapped(
                              RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                              (Match m) => '${m[1]}.',
                            )}',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    )),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        order.formattedTotal,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 32),

          // Action Buttons
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => context.go('/guest'),
              icon: const Icon(Icons.home),
              label: const Text('Kembali ke Beranda'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderNotFound(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 96,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Pesanan Tidak Ditemukan',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Nomor pesanan: $orderNumber',
              style: TextStyle(color: Colors.grey[500]),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => context.go('/guest'),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Kembali ke Beranda'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(BuildContext context, String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 96,
              color: Colors.red[300],
            ),
            const SizedBox(height: 16),
            const Text(
              'Terjadi Kesalahan',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => context.go('/guest'),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Kembali ke Beranda'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  IconData _getStatusIcon(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Icons.schedule;
      case OrderStatus.confirmed:
        return Icons.check_circle_outline;
      case OrderStatus.preparing:
        return Icons.restaurant;
      case OrderStatus.ready:
        return Icons.done_all;
      case OrderStatus.completed:
        return Icons.check_circle;
      case OrderStatus.cancelled:
        return Icons.cancel;
    }
  }

  String _getStatusDescription(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return 'Pesanan Anda sedang menunggu konfirmasi';
      case OrderStatus.confirmed:
        return 'Pesanan telah dikonfirmasi';
      case OrderStatus.preparing:
        return 'Pesanan sedang disiapkan';
      case OrderStatus.ready:
        return 'Pesanan siap diambil';
      case OrderStatus.completed:
        return 'Pesanan selesai';
      case OrderStatus.cancelled:
        return 'Pesanan dibatalkan';
    }
  }


  String _getQueueNumber(String orderNumber) {
    // Format: ORD-YYYYMMDD-HHMMSS-XXX
    // Return last 3 digits
    try {
      final parts = orderNumber.split('-');
      if (parts.isNotEmpty) {
        return parts.last;
      }
    } catch (e) {
      // Ignore
    }
    return '---';
  }
}
