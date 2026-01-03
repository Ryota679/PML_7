/// Registration Request Model
/// 
/// Model untuk pendaftaran Business Owner yang menunggu approval
class RegistrationRequestModel {
  final String id;
  final String fullName;
  final String email;
  final String passwordHash;
  final String businessName;
  final String businessType;
  final String? phone;
  final String status; // 'pending', 'approved', 'rejected'
  final String? adminNotes;
  final String? reviewedBy;
  final DateTime? reviewedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  RegistrationRequestModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.passwordHash,
    required this.businessName,
    required this.businessType,
    this.phone,
    required this.status,
    this.adminNotes,
    this.reviewedBy,
    this.reviewedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  // From Appwrite Document
  factory RegistrationRequestModel.fromJson(Map<String, dynamic> json) {
    return RegistrationRequestModel(
      id: json['\$id'] ?? '',
      fullName: json['full_name'] ?? '',
      email: json['email'] ?? '',
      passwordHash: json['password_hash'] ?? '',
      businessName: json['business_name'] ?? '',
      businessType: json['business_type'] ?? '',
      phone: json['phone'],
      status: json['status'] ?? 'pending',
      adminNotes: json['admin_notes'],
      reviewedBy: json['reviewed_by'],
      reviewedAt: json['reviewed_at'] != null 
          ? DateTime.parse(json['reviewed_at']) 
          : null,
      createdAt: DateTime.parse(json['\$createdAt']),
      updatedAt: DateTime.parse(json['\$updatedAt']),
    );
  }

  // To Appwrite Document
  Map<String, dynamic> toJson() {
    return {
      'full_name': fullName,
      'email': email,
      'password_hash': passwordHash,
      'business_name': businessName,
      'business_type': businessType,
      'phone': phone,
      'status': status,
      'admin_notes': adminNotes,
      'reviewed_by': reviewedBy,
      'reviewed_at': reviewedAt?.toIso8601String(),
    };
  }

  // Copy with
  RegistrationRequestModel copyWith({
    String? id,
    String? fullName,
    String? email,
    String? passwordHash,
    String? businessName,
    String? businessType,
    String? phone,
    String? status,
    String? adminNotes,
    String? reviewedBy,
    DateTime? reviewedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RegistrationRequestModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      passwordHash: passwordHash ?? this.passwordHash,
      businessName: businessName ?? this.businessName,
      businessType: businessType ?? this.businessType,
      phone: phone ?? this.phone,
      status: status ?? this.status,
      adminNotes: adminNotes ?? this.adminNotes,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Helper getters
  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';

  String get statusLabel {
    switch (status) {
      case 'pending':
        return 'Menunggu Review';
      case 'approved':
        return 'Disetujui';
      case 'rejected':
        return 'Ditolak';
      default:
        return status;
    }
  }
}
