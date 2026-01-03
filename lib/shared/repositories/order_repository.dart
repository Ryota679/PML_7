import 'package:appwrite/appwrite.dart';
import 'package:kantin_app/core/config/appwrite_config.dart';
import 'package:kantin_app/core/utils/logger.dart';
import 'package:kantin_app/shared/models/cart_item_model.dart';
import 'package:kantin_app/shared/models/order_item_model.dart';
import 'package:kantin_app/shared/models/order_model.dart';

/// Repository for order operations
class OrderRepository {
  final Databases _databases;

  OrderRepository(this._databases);

  /// Create a new order (guest checkout - no auth required)
  Future<OrderModel> createOrder({
    required String tenantId,
    required String customerName,
    required String customerPhone,
    required List<CartItemModel> cartItems,
    String? tableNumber,
    String? notes,
  }) async {
    try {
      // Validate cart not empty
      if (cartItems.isEmpty) {
        throw Exception('Cart is empty');
      }

      // Generate unique order number
      final orderNumber = OrderModel.generateOrderNumber();

      // Convert cart items to order items
      final orderItems = cartItems.map((cartItem) {
        return OrderItemModel(
          productId: cartItem.product.id,
          productName: cartItem.product.name,
          productPrice: cartItem.product.price,
          quantity: cartItem.quantity,
          notes: cartItem.notes,
        );
      }).toList();

      // Calculate total price
      final totalPrice = orderItems.fold<int>(
        0,
        (sum, item) => sum + item.subtotal,
      );

      // Create order model for serialization
      final orderModel = OrderModel(
        orderNumber: orderNumber,
        tenantId: tenantId,
        customerName: customerName,
        customerContact: customerPhone,
        tableNumber: tableNumber,
        totalAmount: totalPrice,
        status: OrderStatus.pending,
        notes: notes,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        items: orderItems,
      );

      // Create document in Appwrite
      final doc = await _databases.createDocument(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.ordersCollectionId,
        documentId: ID.unique(),
        data: orderModel.toMap(),
      );

      // Return created order
      return OrderModel.fromDocument(doc);
    } on AppwriteException catch (e) {
      throw Exception('Failed to create order: ${e.message}');
    } catch (e) {
      throw Exception('Failed to create order: $e');
    }
  }

  /// Get order by order number (for tracking)
  Future<OrderModel?> getOrderByOrderNumber(String orderNumber) async {
    try {
      AppLogger.info('📦 [ORDER-REPO] Getting order: $orderNumber');

      final result = await _databases.listDocuments(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.ordersCollectionId,
        queries: [
          Query.equal('invoice_number', orderNumber),
          Query.limit(1),
        ],
      );

      if (result.documents.isEmpty) {
        AppLogger.warning('⚠️ [ORDER-REPO] Order not found: $orderNumber');
        return null;
      }

      final order = OrderModel.fromDocument(result.documents.first);
      AppLogger.info('✅ [ORDER-REPO] Order found: ${order.orderNumber}');
      return order;
    } catch (e, stackTrace) {
      AppLogger.error('❌ [ORDER-REPO] Failed to get order', e, stackTrace);
      rethrow;
    }
  }

  /// Get order by ID
  Future<OrderModel> getOrderById(String orderId) async {
    try {
      final doc = await _databases.getDocument(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.ordersCollectionId,
        documentId: orderId,
      );

      return OrderModel.fromDocument(doc);
    } on AppwriteException catch (e) {
      throw Exception('Failed to fetch order: ${e.message}');
    } catch (e) {
      throw Exception('Failed to fetch order: $e');
    }
  }

  /// Get orders by tenant (for tenant dashboard - Sprint 4)
  Future<List<OrderModel>> getOrdersByTenant({
    required String tenantId,
    List<String>? statuses,
    int limit = 50,
  }) async {
    try {
      final queries = [
        Query.equal('tenant_id', tenantId),
        Query.orderDesc('\$createdAt'),
        Query.limit(limit),
      ];

      // Filter by status if provided
      if (statuses != null && statuses.isNotEmpty) {
        queries.add(Query.equal('order_status', statuses));
      }

      final response = await _databases.listDocuments(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.ordersCollectionId,
        queries: queries,
      );

      return response.documents
          .map((doc) => OrderModel.fromDocument(doc))
          .toList();
    } on AppwriteException catch (e) {
      throw Exception('Failed to fetch tenant orders: ${e.message}');
    } catch (e) {
      throw Exception('Failed to fetch tenant orders: $e');
    }
  }

  /// Update order status (Sprint 4 - will use Appwrite Function)
  Future<OrderModel> updateOrderStatus({
    required String orderId,
    required OrderStatus newStatus,
  }) async {
    try {
      final doc = await _databases.updateDocument(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.ordersCollectionId,
        documentId: orderId,
        data: {
          'order_status': newStatus.name,
        },
      );

      return OrderModel.fromDocument(doc);
    } on AppwriteException catch (e) {
      throw Exception('Failed to update order status: ${e.message}');
    } catch (e) {
      throw Exception('Failed to update order status: $e');
    }
  }

  /// Cancel/delete order (for tenant/staff)
  Future<void> deleteOrder(String orderId) async {
    try {
      await _databases.deleteDocument(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.ordersCollectionId,
        documentId: orderId,
      );
    } on AppwriteException catch (e) {
      throw Exception('Failed to delete order: ${e.message}');
    } catch (e) {
      throw Exception('Failed to delete order: $e');
    }
  }
}
