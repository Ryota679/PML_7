import 'package:appwrite/models.dart' as appwrite;

/// Invitation Code Model
/// 
/// Model for invitation codes used in OAuth registration flow
class InvitationCodeModel {
  final String? id;
  final String code; // TN-XXXXXX or ST-XXXXXX
  final InvitationType type;
  final String createdBy; // User ID who created this code
  final String? tenantId; // Null for tenant invites, set for staff invites
  final InvitationStatus status;
  final DateTime expiresAt;
  final String? usedBy; // User ID who used this code
  final DateTime? usedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  InvitationCodeModel({
    this.id,
    required this.code,
    required this.type,
    required this.createdBy,
    this.tenantId,
    this.status = InvitationStatus.active,
    required this.expiresAt,
    this.usedBy,
    this.usedAt,
    this.createdAt,
    this.updatedAt,
  });

  /// Create from Appwrite Document
  factory InvitationCodeModel.fromDocument(appwrite.Document doc) {
    return InvitationCodeModel(
      id: doc.$id,
      code: doc.data['code'] as String,
      type: InvitationTypeExtension.fromString(doc.data['type'] as String),
      createdBy: doc.data['created_by'] as String,
      tenantId: doc.data['tenant_id'] as String?,
      status: InvitationStatusExtension.fromString(doc.data['status'] as String),
      expiresAt: DateTime.parse(doc.data['expires_at'] as String),
      usedBy: doc.data['used_by'] as String?,
      usedAt: doc.data['used_at'] != null
          ? DateTime.parse(doc.data['used_at'] as String)
          : null,
      createdAt: DateTime.parse(doc.$createdAt),
      updatedAt: DateTime.parse(doc.$updatedAt),
    );
  }

  /// Convert to Map for Appwrite
  Map<String, dynamic> toMap() {
    return {
      'code': code,
      'type': type.value,
      'created_by': createdBy,
      'tenant_id': tenantId,
      'status': status.value,
      'expires_at': expiresAt.toIso8601String(),
      'used_by': usedBy,
      'used_at': usedAt?.toIso8601String(),
    };
  }

  /// Copy with
  InvitationCodeModel copyWith({
    String? id,
    String? code,
    InvitationType? type,
    String? createdBy,
    String? tenantId,
    InvitationStatus? status,
    DateTime? expiresAt,
    String? usedBy,
    DateTime? usedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return InvitationCodeModel(
      id: id ?? this.id,
      code: code ?? this.code,
      type: type ?? this.type,
      createdBy: createdBy ?? this.createdBy,
      tenantId: tenantId ?? this.tenantId,
      status: status ?? this.status,
      expiresAt: expiresAt ?? this.expiresAt,
      usedBy: usedBy ?? this.usedBy,
      usedAt: usedAt ?? this.usedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Convenience getters
  bool get isActive => status == InvitationStatus.active && expiresAt.isAfter(DateTime.now());
  bool get isExpired => expiresAt.isBefore(DateTime.now()) || status == InvitationStatus.expired;
  bool get isUsed => status == InvitationStatus.used;
  bool get isTenantInvite => type == InvitationType.tenant;
  bool get isStaffInvite => type == InvitationType.staff;

  @override
  String toString() {
    return 'InvitationCodeModel(code: $code, type: ${type.value}, status: ${status.value})';
  }
}

/// Invitation type enum
enum InvitationType {
  tenant, // For inviting new tenant users
  staff,  // For inviting staff members
}

/// Extension for InvitationType
extension InvitationTypeExtension on InvitationType {
  String get value {
    switch (this) {
      case InvitationType.tenant:
        return 'tenant';
      case InvitationType.staff:
        return 'staff';
    }
  }

  String get label {
    switch (this) {
      case InvitationType.tenant:
        return 'Tenant';
      case InvitationType.staff:
        return 'Staff';
    }
  }

  String get prefix {
    switch (this) {
      case InvitationType.tenant:
        return 'TN';
      case InvitationType.staff:
        return 'ST';
    }
  }

  static InvitationType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'tenant':
        return InvitationType.tenant;
      case 'staff':
        return InvitationType.staff;
      default:
        return InvitationType.tenant;
    }
  }
}

/// Invitation status enum
enum InvitationStatus {
  active,
  used,
  expired,
}

/// Extension for InvitationStatus
extension InvitationStatusExtension on InvitationStatus {
  String get value {
    switch (this) {
      case InvitationStatus.active:
        return 'active';
      case InvitationStatus.used:
        return 'used';
      case InvitationStatus.expired:
        return 'expired';
    }
  }

  String get label {
    switch (this) {
      case InvitationStatus.active:
        return 'Aktif';
      case InvitationStatus.used:
        return 'Terpakai';
      case InvitationStatus.expired:
        return 'Kadaluarsa';
    }
  }

  static InvitationStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'active':
        return InvitationStatus.active;
      case 'used':
        return InvitationStatus.used;
      case 'expired':
        return InvitationStatus.expired;
      default:
        return InvitationStatus.active;
    }
  }
}
