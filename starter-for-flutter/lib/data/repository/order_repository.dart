import 'dart:convert';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import 'package:kantin_app/config/environment.dart';

class OrderRepository {
  final Databases _databases;
  final Functions _functions;
  final Realtime _realtime;

  OrderRepository(Client client) : _databases = Databases(client), _functions = Functions(client), _realtime = Realtime(client);

  Future<Document> createOrder(List<Map<String, dynamic>> items, double totalAmount, String tenantId, String customerName) async {
    final execution = await _functions.createExecution(
      functionId: 'createOrder',
      body: jsonEncode({
        'order_items': items,
        'total_amount': totalAmount,
        'tenant_id': tenantId,
        'customer_name': customerName,
      }),
      headers: {'Content-Type': 'application/json'},
    );
    return Document.fromMap(jsonDecode(execution.responseBody));
  }

  Future<List<Document>> getOrders(String tenantId) async {
    final response = await _databases.listDocuments(
      databaseId: Environment.appwriteDatabaseId,
      collectionId: 'orders',
      queries: [Query.equal('tenant_id', tenantId)],
    );
    return response.documents;
  }

  Future<void> updateOrderStatus(String orderId, String status) async {
    await _functions.createExecution(
      functionId: 'updateOrderStatus',
      body: jsonEncode({'orderId': orderId, 'status': status}),
      headers: {'Content-Type': 'application/json'},
    );
  }

  Future<Document> getOrderById(String orderId) async {
    return await _databases.getDocument(
      databaseId: Environment.appwriteDatabaseId,
      collectionId: 'orders',
      documentId: orderId,
    );
  }

  Stream<RealtimeMessage> subscribeToOrderUpdates(String orderId) {
    final channel = 'databases.${Environment.appwriteDatabaseId}.collections.orders.documents.$orderId';
    return _realtime.subscribe([channel]).stream;
  }
}
