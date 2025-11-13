import 'package:kantin_app/data/cart_provider.dart';
import 'package:kantin_app/data/repository/base_appwrite_repository.dart';
import 'package:kantin_app/data/repository/order_repository.dart';
import 'package:kantin_app/ui/order_tracking_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CartScreen extends ConsumerStatefulWidget {
  final String tenantId;
  const CartScreen({super.key, required this.tenantId});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  final TextEditingController _customerNameController = TextEditingController();

  @override
  void dispose() {
    _customerNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextFormField(
              controller: _customerNameController,
              decoration: const InputDecoration(
                labelText: 'Your Name',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Text('Total: \$${totalPrice.toStringAsFixed(2)}'),
          ElevatedButton(
            onPressed: () async {
              if (_customerNameController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter your name')),
                );
                return;
              }

              final items = cart
                  .map((product) => {
                        'productId': product.$id,
                        'quantity': 1, // Assuming quantity is always 1 for now
                        'price_at_purchase': product.data['price'],
                      })
                  .toList();
              final order = await OrderRepository(BaseAppwriteRepository().client).createOrder(
                items,
                totalPrice,
                widget.tenantId,
                _customerNameController.text,
              );
              ref.read(cartProvider.notifier).clear();
              if (!context.mounted) return;
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
