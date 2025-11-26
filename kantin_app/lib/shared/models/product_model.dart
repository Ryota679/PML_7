import 'package:appwrite/models.dart';

/// Model representing a product/menu item
class ProductModel {
  final String id;
  final String tenantId;
  final String categoryId; // Required - every product must have category
  final String name;
  final String? description;
  final int price;
  final String? imageUrl;
  final bool isAvailable;
  final bool isActive; // Product active/archived status
  final int? stock; // Null = unlimited stock
  final int displayOrder;
  final DateTime createdAt;
  final DateTime updatedAt;

  ProductModel({
    required this.id,
    required this.tenantId,
    required this.categoryId,
    required this.name,
    this.description,
    required this.price,
    this.imageUrl,
    required this.isAvailable,
    required this.isActive,
    this.stock,
    required this.displayOrder,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create ProductModel from Appwrite Document
  factory ProductModel.fromDocument(Document doc) {
    return ProductModel(
      id: doc.$id,
      tenantId: doc.data['tenant_id'] as String,
      categoryId: doc.data['category_id'] as String,
      name: doc.data['name'] as String,
      description: doc.data['description'] as String?,
      price: doc.data['price'] as int? ?? 0,
      imageUrl: doc.data['image_url'] as String?,
      isAvailable: doc.data['is_available'] as bool? ?? true,
      isActive: doc.data['is_active'] as bool? ?? true,
      stock: doc.data['stock'] as int?,
      displayOrder: doc.data['display_order'] as int? ?? 0,
      createdAt: DateTime.parse(doc.$createdAt),
      updatedAt: DateTime.parse(doc.$updatedAt),
    );
  }

  /// Convert to Map for Appwrite createDocument
  Map<String, dynamic> toMap() {
    return {
      'tenant_id': tenantId,
      'category_id': categoryId,
      'name': name,
      'description': description,
      'price': price,
      'image_url': imageUrl,
      'is_available': isAvailable,
      'is_active': isActive,
      'stock': stock,
      'display_order': displayOrder,
    };
  }

  /// Get formatted price in Rupiah
  String get formattedPrice {
    return 'Rp ${price.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        )}';
  }

  /// Check if product has stock tracking
  bool get hasStockTracking => stock != null;

  /// Check if product is out of stock
  bool get isOutOfStock => hasStockTracking && (stock ?? 0) <= 0;

  /// Create a copy with updated fields
  ProductModel copyWith({
    String? id,
    String? tenantId,
    String? categoryId,
    String? name,
    String? description,
    int? price,
    String? imageUrl,
    bool? isAvailable,
    bool? isActive,
    int? stock,
    int? displayOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProductModel(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      categoryId: categoryId ?? this.categoryId,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      imageUrl: imageUrl ?? this.imageUrl,
      isAvailable: isAvailable ?? this.isAvailable,
      isActive: isActive ?? this.isActive,
      stock: stock ?? this.stock,
      displayOrder: displayOrder ?? this.displayOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'ProductModel(id: $id, name: $name, price: $formattedPrice, available: $isAvailable)';
  }
}
