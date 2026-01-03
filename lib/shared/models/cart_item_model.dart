import 'package:kantin_app/shared/models/product_model.dart';

/// Model for cart items (local state only, not saved to database)
class CartItemModel {
  final ProductModel product;
  final int quantity;
  final String? notes;

  CartItemModel({
    required this.product,
    required this.quantity,
    this.notes,
  });

  /// Calculate subtotal
  int get subtotal => product.price * quantity;

  /// Get formatted subtotal
  String get formattedSubtotal {
    return 'Rp ${subtotal.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        )}';
  }

  /// Create a copy with updated fields
  CartItemModel copyWith({
    ProductModel? product,
    int? quantity,
    String? notes,
  }) {
    return CartItemModel(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      notes: notes ?? this.notes,
    );
  }

  /// Convert to JSON for cart persistence
  Map<String, dynamic> toJson() => {
    'product_id': product.id,
    'product_name': product.name,
    'price': product.price,
    'quantity': quantity,
    'image_url': product.imageUrl,
    'notes': notes,
  };
  
  /// Create from JSON (for cart persistence)
  /// Note: This creates a minimal ProductModel for cart purposes
  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    final product = ProductModel(
      id: json['product_id'] as String,
      name: json['product_name'] as String,
      price: json['price'] as int,
      imageUrl: json['image_url'] as String?,
      categoryId: '', // Not needed for cart display
      stock: 0, // Not needed for cart display
      tenantId: '', // Not needed for cart display
      isAvailable: true, // Required parameter
      isActive: true, // Required parameter
      displayOrder: 0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    
    return CartItemModel(
      product: product,
      quantity: json['quantity'] as int,
      notes: json['notes'] as String?,
    );
  }

  @override
  String toString() {
    return 'CartItemModel(product: ${product.name}, qty: $quantity, subtotal: $formattedSubtotal)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CartItemModel && other.product.id == product.id;
  }

  @override
  int get hashCode => product.id.hashCode;
}
