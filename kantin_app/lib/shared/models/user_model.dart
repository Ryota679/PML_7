import 'package:appwrite/models.dart' as appwrite;

/// User Model
/// 
/// Model untuk data pengguna dari koleksi 'users'
class UserModel {
  final String? id;
  final String userId; // Reference to Appwrite Auth user
  final String role; // owner_business, tenant, adminsystem, guest
  final String username; // Username for login
  final String fullName;
  final String email;
  final String? phone;
  final String? tenantId;
  final DateTime? contractEndDate;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  UserModel({
    this.id,
    required this.userId,
    required this.role,
    required this.username,
    required this.fullName,
    required this.email,
    this.phone,
    this.tenantId,
    this.contractEndDate,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  /// Create from Appwrite Document
  factory UserModel.fromDocument(appwrite.Document doc) {
    // Get username (required field)
    final username = doc.data['username'] as String;
    
    // Handle legacy data - full_name might be null (use username as fallback)
    final fullName = doc.data['full_name'] as String? ?? username;
    
    // Handle legacy data - email might be null
    final email = doc.data['email'] as String? ?? 
                  doc.data['user_id'] as String? ?? 
                  'no-email@example.com';
    
    return UserModel(
      id: doc.$id,
      userId: doc.data['user_id'] as String,
      role: doc.data['role'] as String,
      username: username,
      fullName: fullName,
      email: email,
      phone: doc.data['phone'] as String?,
      tenantId: doc.data['tenant_id'] as String?,
      contractEndDate: doc.data['contract_end_date'] != null
          ? DateTime.parse(doc.data['contract_end_date'] as String)
          : null,
      isActive: doc.data['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(doc.$createdAt),
      updatedAt: DateTime.parse(doc.$updatedAt),
    );
  }

  /// Create from JSON (for backward compatibility)
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['\$id'] as String?,
      userId: json['user_id'] as String,
      role: json['role'] as String,
      username: json['username'] as String,
      fullName: json['full_name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String?,
      tenantId: json['tenant_id'] as String?,
      contractEndDate: json['contract_end_date'] != null
          ? DateTime.parse(json['contract_end_date'] as String)
          : null,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['\$createdAt'] != null 
          ? DateTime.parse(json['\$createdAt'] as String)
          : json['created_at'] != null
              ? DateTime.parse(json['created_at'] as String)
              : null,
      updatedAt: json['\$updatedAt'] != null
          ? DateTime.parse(json['\$updatedAt'] as String)
          : json['updated_at'] != null
              ? DateTime.parse(json['updated_at'] as String)
              : null,
    );
  }

  /// Convert to Map for Appwrite
  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'role': role,
      'username': username,
      'full_name': fullName,
      'email': email,
      'phone': phone,
      'tenant_id': tenantId,
      'contract_end_date': contractEndDate?.toIso8601String(),
      'is_active': isActive,
    };
  }

  /// Copy with
  UserModel copyWith({
    String? id,
    String? userId,
    String? role,
    String? username,
    String? fullName,
    String? email,
    String? phone,
    String? tenantId,
    DateTime? contractEndDate,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      role: role ?? this.role,
      username: username ?? this.username,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      tenantId: tenantId ?? this.tenantId,
      contractEndDate: contractEndDate ?? this.contractEndDate,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
