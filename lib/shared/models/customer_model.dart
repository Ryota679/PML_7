import 'package:appwrite/models.dart';

/// Customer Model
/// Represents a registered customer/pembeli
class CustomerModel {
  final String id;           // Document ID in users collection
  final String userId;       // Appwrite account user ID
  final String name;
  final String email;
  final String phone;
  final String? address;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;

  CustomerModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.email,
    required this.phone,
    this.address,
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
  });

  /// Create from Appwrite Document (users collection with role='customer')
  factory CustomerModel.fromDocument(Document doc) {
    return CustomerModel(
      id: doc.$id,
      userId: doc.data['user_id'] as String,
      name: doc.data['username'] as String, // Reuse username field for customer name
      email: doc.data['email'] as String? ?? '',
      phone: doc.data['phone'] as String? ?? '',
      address: doc.data['address'] as String?,
      createdAt: DateTime.parse(doc.$createdAt),
      updatedAt: DateTime.parse(doc.$updatedAt),
      isActive: doc.data['is_active'] as bool? ?? true,
    );
  }

  /// Convert to Map for database
  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'username': name,
      'role': 'customer',
      'email': email,
      'phone': phone,
      'address': address,
      'is_active': isActive,
    };
  }

  /// Getters
  String get displayName => name;
  bool get hasAddress => address != null && address!.isNotEmpty;
  bool get hasPhone => phone.isNotEmpty;

  /// Copy with
  CustomerModel copyWith({
    String? id,
    String? userId,
    String? name,
    String? email,
    String? phone,
    String? address,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
  }) {
    return CustomerModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  String toString() {
    return 'CustomerModel(name: $name, email: $email, phone: $phone)';
  }
}
