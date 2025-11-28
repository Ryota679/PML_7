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
