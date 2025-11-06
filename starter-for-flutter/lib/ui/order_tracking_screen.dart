import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import 'package:kantin_app/data/repository/base_appwrite_repository.dart';
import 'package:kantin_app/data/repository/order_repository.dart';
import 'package:flutter/material.dart';

class OrderTrackingScreen extends StatefulWidget {
  final String orderId;

  const OrderTrackingScreen({Key? key, required this.orderId}) : super(key: key);

  @override
  _OrderTrackingScreenState createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  final OrderRepository _orderRepository = OrderRepository(BaseAppwriteRepository().client);
  Document? _order;

  @override
  void initState() {
    super.initState();
    _loadOrder();
    _orderRepository.subscribeToOrderUpdates(widget.orderId).listen((event) {
      if (event.events.contains('databases.*.collections.orders.documents.*.update')) {
        setState(() {
          _order = Document.fromMap(event.payload);
        });
      }
    });
  }

  Future<void> _loadOrder() async {
    try {
      final order = await _orderRepository.getOrderById(widget.orderId);
      setState(() {
        _order = order;
      });
    } on AppwriteException catch (e) {
      print(e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Track Order'),
      ),
      body: Center(
        child: _order == null
            ? const CircularProgressIndicator()
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Order ID: ${widget.orderId}'),
                  Text('Status: ${_order!.data['status']}'),
                  Text('Total: \$${_order!.data['totalPrice']}'),
                ],
              ),
      ),
    );
  }
}
