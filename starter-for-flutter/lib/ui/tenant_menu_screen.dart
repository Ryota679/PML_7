import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import 'package:kantin_app/data/cart_provider.dart';
import 'package:kantin_app/src/features/tenant_management/data/datasources/repositories/tenant_repository_impl.dart';
import 'package:kantin_app/data/repository/product_repository_provider.dart';
import 'package:kantin_app/ui/cart_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TenantMenuScreen extends ConsumerStatefulWidget {
  final String tenantId;

  const TenantMenuScreen({super.key, required this.tenantId});

  @override
  ConsumerState<TenantMenuScreen> createState() => _TenantMenuScreenState();
}

class _TenantMenuScreenState extends ConsumerState<TenantMenuScreen> {
  Document? _tenant;
  List<Document> _products = [];

  @override
  void initState() {
    super.initState();
    _loadTenantAndProducts();
  }

  Future<void> _loadTenantAndProducts() async {
    try {
      final tenant = await ref.read(tenantRepositoryProvider).getTenantById(widget.tenantId);
      final products = await ref.read(productRepositoryProvider).getProducts(widget.tenantId);
      setState(() {
        _tenant = tenant;
        _products = products;
      });
    } on AppwriteException catch (e) {
      debugPrint(e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_tenant?.data['name'] ?? 'Menu'),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => CartScreen(tenantId: widget.tenantId),
                ),
              );
            },
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: _products.length,
        itemBuilder: (context, index) {
          final product = _products[index];
          return ListTile(
            title: Text(product.data['name']),
            subtitle: Text('\$${product.data['price']}'),
            trailing: IconButton(
              icon: const Icon(Icons.add_shopping_cart),
              onPressed: () {
                ref.read(cartProvider.notifier).add(product);
              },
            ),
          );
        },
      ),
    );
  }
}
