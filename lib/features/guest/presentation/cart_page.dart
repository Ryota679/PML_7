import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kantin_app/features/guest/providers/cart_provider.dart';
import 'package:kantin_app/features/guest/presentation/widgets/cart_item_card.dart';

/// Cart Page
/// Shows cart items and allows quantity management
class CartPage extends ConsumerWidget {
  final String tenantId;

  const CartPage({
    super.key,
    required this.tenantId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartItems = ref.watch(cartItemsListProvider);
    final totalAmount = ref.watch(cartFormattedTotalProvider);
    final isEmpty = ref.watch(cartIsEmptyProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Keranjang'),
        actions: [
          if (!isEmpty)
            TextButton(
              onPressed: () => _showClearCartDialog(context, ref),
              child: const Text('Kosongkan'),
            ),
        ],
      ),
      body: isEmpty
          ? _buildEmptyCart(context)
          : Column(
              children: [
                // Cart Items List
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: cartItems.length,
                    itemBuilder: (context, index) {
                      final item = cartItems[index];
                      return CartItemCard(
                        item: item,
                        onIncrement: () {
                          ref.read(cartProvider.notifier).incrementQuantity(item.product.id);
                        },
                        onDecrement: () {
                          ref.read(cartProvider.notifier).decrementQuantity(item.product.id);
                        },
                        onRemove: () {
                          ref.read(cartProvider.notifier).removeItem(item.product.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${item.product.name} dihapus'),
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),

                // Bottom Summary & Checkout
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(16),
                  child: SafeArea(
                    top: false,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Total
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              totalAmount,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Checkout Button
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: FilledButton.icon(
                            onPressed: () {
                              // Navigate to checkout page
                              context.push('/checkout/$tenantId');
                            },
                            icon: const Icon(Icons.shopping_bag),
                            label: const Text('Lanjut ke Checkout'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildEmptyCart(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 96,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Keranjang Kosong',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tambahkan menu untuk melanjutkan',
            style: TextStyle(color: Colors.grey[500]),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back),
            label: const Text('Kembali ke Menu'),
          ),
        ],
      ),
    );
  }

  void _showClearCartDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kosongkan Keranjang?'),
        content: const Text('Semua item akan dihapus dari keranjang.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () {
              ref.read(cartProvider.notifier).clearCart();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Keranjang dikosongkan'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
            child: const Text('Kosongkan'),
          ),
        ],
      ),
    );
  }
}
