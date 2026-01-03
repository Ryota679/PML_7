import 'package:appwrite/models.dart';
import 'package:kantin_app/core/utils/tenant_code_generator.dart';

/// Model representing a tenant/stand in the kantin
class TenantModel {
  final String id;
  final String ownerId;
  final String name;
  final TenantType type;
  final String? description;
  final bool isActive;
  final String? logoUrl;
  final String? phone;
  final int displayOrder;
  final String? tenantCode; // 6-character code for customer access
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // ===== NEW: Freemium Counter Fields =====
  
  /// Current number of products (denormalized counter)
  final int currentProductsCount;
  
  /// Current number of staff members (denormalized counter)
  final int currentStaffCount;
  
  /// Selected for free tier (when user downgraded from trial)
  final bool? selectedForFreeTier;
  
  /// Subscription tier for per-tenant premium model
  /// 'free' (default) or 'premium'
  final String subscriptionTier;
  
  /// When tenant's premium subscription expires (null = no subscription)
  final DateTime? subscriptionExpiresAt;

  TenantModel({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.type,
    this.description,
    required this.isActive,
    this.logoUrl,
    this.phone,
    required this.displayOrder,
    this.tenantCode,
    required this.createdAt,
    required this.updatedAt,
    this.currentProductsCount = 0,
    this.currentStaffCount = 0,
    this.selectedForFreeTier,
    this.subscriptionTier = 'free',
    this.subscriptionExpiresAt,
  });

  /// Create TenantModel from Appwrite Document
  factory TenantModel.fromDocument(Document doc) {
    return TenantModel(
      id: doc.$id,
      ownerId: doc.data['owner_id'] as String,
      name: doc.data['name'] as String,
      type: TenantTypeExtension.fromString(doc.data['type'] as String),
      description: doc.data['description'] as String?,
      isActive: doc.data['is_active'] as bool? ?? true,
      logoUrl: doc.data['logo_url'] as String?,
      phone: doc.data['phone'] as String?,
      displayOrder: doc.data['display_order'] as int? ?? 0,
      tenantCode: doc.data['tenant_code'] as String?,
      createdAt: DateTime.parse(doc.$createdAt),
      updatedAt: DateTime.parse(doc.$updatedAt),
      // Freemium counters
      currentProductsCount: doc.data['current_products_count'] as int? ?? 0,
      currentStaffCount: doc.data['current_staff_count'] as int? ?? 0,
      selectedForFreeTier: doc.data['selected_for_free_tier'] as bool?,
      // Subscription fields
      subscriptionTier: doc.data['subscription_tier'] as String? ?? 'free',
      subscriptionExpiresAt: doc.data['subscription_expires_at'] != null
          ? DateTime.parse(doc.data['subscription_expires_at'] as String)
          : null,
    );
  }

  /// Convert to Map for Appwrite createDocument
  Map<String, dynamic> toMap() {
    return {
      'owner_id': ownerId,
      'name': name,
      'type': type.value,
      'description': description,
      'is_active': isActive,
      'logo_url': logoUrl,
      'phone': phone,
      'display_order': displayOrder,
      'tenant_code': tenantCode,
      // Freemium counters
      'current_products_count': currentProductsCount,
      'current_staff_count': currentStaffCount,
    };
  }

  /// Get or generate tenant code
  String getCode() {
    return tenantCode ?? TenantCodeGenerator.generateCode(id);
  }
  
  /// Check if tenant has active premium subscription
  bool get hasPremiumSubscription {
    if (subscriptionTier != 'premium') return false;
    if (subscriptionExpiresAt == null) return true; // Permanent premium
    return subscriptionExpiresAt!.isAfter(DateTime.now());
  }

  /// Create a copy with updated fields
  TenantModel copyWith({
    String? id,
    String? ownerId,
    String? name,
    TenantType? type,
    String? description,
    bool? isActive,
    String? logoUrl,
    String? phone,
    int? displayOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? currentProductsCount,
    int? currentStaffCount,
  }) {
    return TenantModel(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      name: name ?? this.name,
      type: type ?? this.type,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
      logoUrl: logoUrl ?? this.logoUrl,
      phone: phone ?? this.phone,
      displayOrder: displayOrder ?? this.displayOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      currentProductsCount: currentProductsCount ?? this.currentProductsCount,
      currentStaffCount: currentStaffCount ?? this.currentStaffCount,
    );
  }

  @override
  String toString() {
    return 'TenantModel(id: $id, name: $name, type: ${type.label}, isActive: $isActive)';
  }
}

/// Enum for tenant types
enum TenantType {
  food,
  beverage,
  snack,
  dessert,
  other,
}

/// Extension for TenantType enum
extension TenantTypeExtension on TenantType {
  /// Get string value for database
  String get value {
    switch (this) {
      case TenantType.food:
        return 'food';
      case TenantType.beverage:
        return 'beverage';
      case TenantType.snack:
        return 'snack';
      case TenantType.dessert:
        return 'dessert';
      case TenantType.other:
        return 'other';
    }
  }

  /// Get display label
  String get label {
    switch (this) {
      case TenantType.food:
        return 'Makanan';
      case TenantType.beverage:
        return 'Minuman';
      case TenantType.snack:
        return 'Snack';
      case TenantType.dessert:
        return 'Dessert';
      case TenantType.other:
        return 'Lainnya';
    }
  }

  /// Get icon for UI
  String get icon {
    switch (this) {
      case TenantType.food:
        return '🍜';
      case TenantType.beverage:
        return '🥤';
      case TenantType.snack:
        return '🍿';
      case TenantType.dessert:
        return '🍰';
      case TenantType.other:
        return '🏪';
    }
  }

  /// Create TenantType from string value
  static TenantType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'food':
        return TenantType.food;
      case 'beverage':
        return TenantType.beverage;
      case 'snack':
        return TenantType.snack;
      case 'dessert':
        return TenantType.dessert;
      case 'other':
        return TenantType.other;
      default:
        return TenantType.other;
    }
  }
}
