import 'package:appwrite/appwrite.dart';
import 'package:kantin_app/core/config/appwrite_config.dart';
import 'package:kantin_app/core/services/api_error_interceptor.dart';
import 'package:kantin_app/shared/models/order_item_model.dart';
import 'package:kantin_app/shared/models/order_model.dart';

/// Repository for Order operations
class OrderRepository {
  final Databases _databases;

  OrderRepository({required Databases databases}) : _databases = databases;

  /// Create a new order with items
  /// Returns the created order with ID
  Future<OrderModel> createOrder({
    required OrderModel order,
    required List<OrderItemModel> items,
  }) async {
    try {
      // 1. Create order document
      final orderDoc = await ApiErrorInterceptor.wrapApiCall(
        apiCall: () => _databases.createDocument(
          databaseId: AppwriteConfig.databaseId,
          collectionId: AppwriteConfig.ordersCollectionId,
          documentId: ID.unique(),
          data: order.toMap(),
        ),
        context: 'Create Order',
      );

      final createdOrder = OrderModel.fromDocument(orderDoc);

      // 2. Create order items
      final createdItems = <OrderItemModel>[];
      for (final item in items) {
        final itemWithOrderId = item.copyWith(orderId: createdOrder.id);
        final itemDoc = await ApiErrorInterceptor.wrapApiCall(
          apiCall: () => _databases.createDocument(
            databaseId: AppwriteConfig.databaseId,
            collectionId: AppwriteConfig.orderItemsCollectionId,
            documentId: ID.unique(),
            data: itemWithOrderId.toMap(),
          ),
          context: 'Create Order Item',
        );
        createdItems.add(OrderItemModel.fromDocument(itemDoc));
      }

      // 3. Return order with items
      return createdOrder.copyWith(items: createdItems);
    } catch (e) {
      throw Exception('Failed to create order: $e');
    }
  }

  /// Get order by ID with items
  Future<OrderModel> getOrderById(String orderId) async {
    try {
      // 1. Get order document
      final orderDoc = await ApiErrorInterceptor.wrapApiCall(
        apiCall: () => _databases.getDocument(
          databaseId: AppwriteConfig.databaseId,
          collectionId: AppwriteConfig.ordersCollectionId,
          documentId: orderId,
        ),
        context: 'Get Order',
      );

      final order = OrderModel.fromDocument(orderDoc);

      // 2. Get order items
      final itemsResponse = await ApiErrorInterceptor.wrapApiCall(
        apiCall: () => _databases.listDocuments(
          databaseId: AppwriteConfig.databaseId,
          collectionId: AppwriteConfig.orderItemsCollectionId,
          queries: [
            Query.equal('order_id', orderId),
          ],
        ),
        context: 'Get Order Items',
      );

      final items = itemsResponse.documents
          .map((doc) => OrderItemModel.fromDocument(doc))
          .toList();

      return order.copyWith(items: items);
    } catch (e) {
      throw Exception('Failed to get order: $e');
    }
  }

  /// Get orders by tenant ID
  Future<List<OrderModel>> getOrdersByTenant(
    String tenantId, {
    OrderStatus? status,
    int limit = 50,
  }) async {
    try {
      final queries = [
        Query.equal('tenant_id', tenantId),
        Query.orderDesc('\$createdAt'),
        Query.limit(limit),
      ];

      if (status != null) {
        queries.add(Query.equal('order_status', status.name));
      }

      final response = await ApiErrorInterceptor.wrapApiCall(
        apiCall: () => _databases.listDocuments(
          databaseId: AppwriteConfig.databaseId,
          collectionId: AppwriteConfig.ordersCollectionId,
          queries: queries,
        ),
        context: 'Get Orders by Tenant',
      );

      return response.documents
          .map((doc) => OrderModel.fromDocument(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get orders: $e');
    }
  }

  /// Update order status
  Future<OrderModel> updateOrderStatus(
    String orderId,
    OrderStatus newStatus,
  ) async {
    try {
      final updatedDoc = await ApiErrorInterceptor.wrapApiCall(
        apiCall: () => _databases.updateDocument(
          databaseId: AppwriteConfig.databaseId,
          collectionId: AppwriteConfig.ordersCollectionId,
          documentId: orderId,
          data: {
            'order_status': newStatus.name,
          },
        ),
        context: 'Update Order Status',
      );

      return OrderModel.fromDocument(updatedDoc);
    } catch (e) {
      throw Exception('Failed to update order status: $e');
    }
  }

  /// Cancel order
  Future<OrderModel> cancelOrder(String orderId) async {
    return updateOrderStatus(orderId, OrderStatus.cancelled);
  }
}
