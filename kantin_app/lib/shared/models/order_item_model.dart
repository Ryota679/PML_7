/// Model representing an order item
/// Stored as JSON array in orders.items field
class OrderItemModel {
  final String productId;
  final String productName;
  final int productPrice;
  final int quantity;
  final String? notes;

  OrderItemModel({
    required this.productId,
    required this.productName,
    required this.productPrice,
    required this.quantity,
    this.notes,
  });

  /// Calculate subtotal for this item
  int get subtotal => productPrice * quantity;

  /// Create OrderItemModel from JSON (for deserializing from database)
  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      productId: json['product_id'] as String,
      productName: json['product_name'] as String,
      productPrice: json['price'] as int,
      quantity: json['quantity'] as int,
      notes: json['notes'] as String?,
    );
  }

  /// Convert to JSON (for serializing to database)
  Map<String, dynamic> toJson() {
    return {
      'product_id': productId,
      'product_name': productName,
      'price': productPrice,
      'quantity': quantity,
      'subtotal': subtotal,
      if (notes != null) 'notes': notes,
    };
  }

  /// Create a copy with updated fields
  OrderItemModel copyWith({
    String? productId,
    String? productName,
    int? productPrice,
    int? quantity,
    String? notes,
  }) {
    return OrderItemModel(
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      productPrice: productPrice ?? this.productPrice,
      quantity: quantity ?? this.quantity,
      notes: notes ?? this.notes,
    );
  }

  @override
  String toString() {
    return 'OrderItemModel(product: $productName, qty: $quantity, price: $productPrice, subtotal: $subtotal)';
  }
}
