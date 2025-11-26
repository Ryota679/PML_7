import 'package:appwrite/models.dart';

/// Model representing a product category
class CategoryModel {
  final String id;
  final String tenantId;
  final String name;
  final String? description;
  final String? icon; // Emoji or icon identifier
  final int displayOrder;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  CategoryModel({
    required this.id,
    required this.tenantId,
    required this.name,
    this.description,
    this.icon,
    required this.displayOrder,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create CategoryModel from Appwrite Document
  factory CategoryModel.fromDocument(Document doc) {
    return CategoryModel(
      id: doc.$id,
      tenantId: doc.data['tenant_id'] as String,
      name: doc.data['name'] as String,
      description: doc.data['description'] as String?,
      icon: doc.data['icon'] as String?,
      displayOrder: doc.data['display_order'] as int? ?? 0,
      isActive: doc.data['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(doc.$createdAt),
      updatedAt: DateTime.parse(doc.$updatedAt),
    );
  }

  /// Convert to Map for Appwrite createDocument
  Map<String, dynamic> toMap() {
    return {
      'tenant_id': tenantId,
      'name': name,
      'description': description,
      'icon': icon,
      'display_order': displayOrder,
      'is_active': isActive,
    };
  }

  /// Create a copy with updated fields
  CategoryModel copyWith({
    String? id,
    String? tenantId,
    String? name,
    String? description,
    String? icon,
    int? displayOrder,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      name: name ?? this.name,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      displayOrder: displayOrder ?? this.displayOrder,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'CategoryModel(id: $id, name: $name, tenantId: $tenantId)';
  }
}
