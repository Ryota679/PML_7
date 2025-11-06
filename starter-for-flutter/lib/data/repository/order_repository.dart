import 'dart:convert';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import 'package:kantin_app/config/environment.dart';

class OrderRepository {
  final Databases _databases;
  final Functions _functions;
  final Realtime _realtime;

  OrderRepository(Client client) : _databases = Databases(client), _functions = Functions(client), _realtime = Realtime(client);

  Future<Document> createOrder(List<Map<String, dynamic>> items, double totalPrice, String tenantId) async {
    final execution = await _functions.createExecution(
      functionId: 'createOrder',
      body: '{"items": $items, "totalPrice": $totalPrice, "tenantId": "$tenantId"}',
    );
    return Document.fromMap(jsonDecode(execution.responseBody));
  }

  Future<List<Document>> getOrders(String tenantId) async {
    final response = await _databases.listDocuments(
      databaseId: Environment.appwriteDatabaseId,
      collectionId: 'orders',
      queries: [Query.equal('tenantId', tenantId)],
    );
    return response.documents;
  }

  Future<void> updateOrderStatus(String orderId, String status) async {
    await _functions.createExecution(
      functionId: 'updateOrderStatus',
      body: '{"orderId": "$orderId", "status": "$status"}',
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
    return _realtime.subscribe(['databases.${Environment.appwriteDatabaseId}.collections.orders.documents.$orderId']).stream;
  }
}
