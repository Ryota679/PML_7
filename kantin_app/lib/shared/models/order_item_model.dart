import 'package:appwrite/models.dart';

/// Model representing an order item
class OrderItemModel {
  final String? id;
  final String orderId;
  final String productId;
  final String productName;
  final int productPrice;
  final int quantity;
  final int subtotal;
  final String? notes;

  OrderItemModel({
    this.id,
    required this.orderId,
    required this.productId,
    required this.productName,
    required this.productPrice,
    required this.quantity,
    required this.subtotal,
    this.notes,
  });

  /// Create OrderItemModel from Appwrite Document
  factory OrderItemModel.fromDocument(Document doc) {
    return OrderItemModel(
      id: doc.$id,
      orderId: doc.data['order_id'] as String,
      productId: doc.data['product_id'] as String,
      productName: doc.data['product_name'] as String,
      productPrice: doc.data['product_price'] as int? ?? 0,
      quantity: doc.data['quantity'] as int? ?? 1,
      subtotal: doc.data['subtotal'] as int? ?? 0,
      notes: doc.data['notes'] as String?,
    );
  }

  /// Convert to Map for Appwrite createDocument
  Map<String, dynamic> toMap() {
    return {
      'order_id': orderId,
      'product_id': productId,
      'product_name': productName,
      'product_price': productPrice,
      'quantity': quantity,
      'subtotal': subtotal,
      'notes': notes,
    };
  }

  /// Create a copy with updated fields
  OrderItemModel copyWith({
    String? id,
    String? orderId,
    String? productId,
    String? productName,
    int? productPrice,
    int? quantity,
    int? subtotal,
    String? notes,
  }) {
    return OrderItemModel(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      productPrice: productPrice ?? this.productPrice,
      quantity: quantity ?? this.quantity,
      subtotal: subtotal ?? this.subtotal,
      notes: notes ?? this.notes,
    );
  }

  @override
  String toString() {
    return 'OrderItemModel(product: $productName, qty: $quantity, subtotal: $subtotal)';
  }
}
