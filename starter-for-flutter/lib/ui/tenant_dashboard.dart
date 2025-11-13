import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import 'package:kantin_app/data/repository/auth_repository.dart';
import 'package:kantin_app/data/repository/base_appwrite_repository.dart';
import 'package:kantin_app/data/repository/tenant_repository.dart';
import 'package:kantin_app/data/repository/product_repository.dart';
import 'package:kantin_app/data/repository/order_repository.dart';
import 'package:flutter/material.dart';

class TenantDashboard extends StatefulWidget {
  const TenantDashboard({super.key});

  @override
  State<TenantDashboard> createState() => _TenantDashboardState();
}

class _TenantDashboardState extends State<TenantDashboard> {
  final AuthRepository _authRepository = AuthRepository(BaseAppwriteRepository().client);
  final TenantRepository _tenantRepository = TenantRepository(BaseAppwriteRepository().client);
  final ProductRepository _productRepository = ProductRepository(BaseAppwriteRepository().client);
  final OrderRepository _orderRepository = OrderRepository(BaseAppwriteRepository().client);
  Document? _tenant;
  List<Document> _products = [];
  List<Document> _orders = [];

  @override
  void initState() {
    super.initState();
    _loadTenantAndData();
  }

  Future<void> _loadTenantAndData() async {
    try {
      final user = await _authRepository.getAccount();
      final tenant = await _tenantRepository.getTenantByOwner(user.$id);
      if (tenant != null) {
        final products = await _productRepository.getProducts(tenant.$id);
        final orders = await _orderRepository.getOrders(tenant.$id);
        setState(() {
          _tenant = tenant;
          _products = products;
          _orders = orders;
        });
      }
    } on AppwriteException catch (e) {
      debugPrint(e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(_tenant?.data['name'] ?? 'Tenant Dashboard'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Products'),
              Tab(text: 'Orders'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Products Tab
            ListView.builder(
              itemCount: _products.length,
              itemBuilder: (context, index) {
                final product = _products[index];
                return ListTile(
                  title: Text(product.data['name']),
                  subtitle: Text('\$${product.data['price']}'),
                  trailing: Switch(
                    value: product.data['is_available'],
                    onChanged: (value) async {
                      await _productRepository.updateProduct(
                        product.$id,
                        data: {'is_available': value},
                      );
                      _loadTenantAndData();
                    },
                  ),
                );
              },
            ),
            // Orders Tab
            ListView.builder(
              itemCount: _orders.length,
              itemBuilder: (context, index) {
                final order = _orders[index];
                return ListTile(
                  title: Text('Order #${order.$id}'),
                  subtitle: Text('Total: \$${order.data['total_amount']}'),
                  trailing: DropdownButton<String>(
                    value: order.data['status'],
                    onChanged: (String? newValue) async {
                      if (newValue != null) {
                        await _orderRepository.updateOrderStatus(
                          order.$id,
                          newValue,
                        );
                        _loadTenantAndData();
                      }
                    },
                    items: <String>['new', 'preparing', 'ready_for_pickup', 'completed', 'cancelled']
                        .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                  ),
                );
              },
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            _showAddProductDialog();
          },
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  void _showAddProductDialog() {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final categoryController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Add Product'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              TextField(
                controller: priceController,
                decoration: const InputDecoration(labelText: 'Price'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: categoryController,
                decoration: const InputDecoration(labelText: 'Category ID'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final navigatorState = Navigator.of(dialogContext); // Capture NavigatorState
                await _productRepository.createProduct(
                  nameController.text,
                  double.parse(priceController.text),
                  categoryController.text,
                  _tenant!.$id,
                );
                if (!mounted) return; // Check if _TenantDashboardState is still mounted
                navigatorState.pop(); // Use the captured NavigatorState
                _loadTenantAndData();
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }
}
