import 'package:kantin_app/data/cart_provider.dart';
import 'package:kantin_app/data/repository/base_appwrite_repository.dart';
import 'package:kantin_app/data/repository/order_repository.dart';
import 'package:kantin_app/ui/order_tracking_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CartScreen extends ConsumerWidget {
  final String tenantId;
  const CartScreen({Key? key, required this.tenantId}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    final totalPrice = cart.fold<double>(
        0, (previousValue, element) => previousValue + element.data['price']);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cart'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: cart.length,
              itemBuilder: (context, index) {
                final product = cart[index];
                return ListTile(
                  title: Text(product.data['name']),
                  subtitle: Text('\$${product.data['price']}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.remove_shopping_cart),
                    onPressed: () {
                      ref.read(cartProvider.notifier).remove(product);
                    },
                  ),
                );
              },
            ),
          ),
          Text('Total: \$${totalPrice.toStringAsFixed(2)}'),
          ElevatedButton(
            onPressed: () async {
              final items = cart
                  .map((product) => {
                        'productId': product.$id,
                        'quantity': 1, // Assuming quantity is always 1 for now
                        'price_at_purchase': product.data['price'],
                      })
                  .toList();
              final order = await OrderRepository(BaseAppwriteRepository().client).createOrder(items, totalPrice, tenantId);
              ref.read(cartProvider.notifier).clear();
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => OrderTrackingScreen(orderId: order.$id),
                ),
              );
            },
            child: const Text('Checkout'),
          ),
        ],
      ),
    );
  }
}
