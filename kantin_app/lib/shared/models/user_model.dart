import 'package:appwrite/models.dart' as appwrite;

/// User Model
/// 
/// Model untuk data pengguna dari koleksi 'users'
class UserModel {
  final String? id;
  final String userId; // Reference to Appwrite Auth user
  final String role; // owner_business, tenant, adminsystem, guest
  final String? subRole; // NULL (tenant owner) | 'staff' (tenant staff)
  
  @Deprecated('Use invited_by instead for OAuth flow')
  final String? createdBy; // [DEPRECATED] User ID who created this user
  
  final String username; // Username for login
  final String fullName;
  final String email;
  final String? phone;
  final String? tenantId;
  final DateTime? contractEndDate;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // ===== NEW: OAuth & Freemium Fields =====
  
  /// Subscription tier: "free" | "premium"
  final String subscriptionTier;
  
  /// When subscription started (for premium users)
  final DateTime? subscriptionStartedAt;
  
  /// When subscription expires (for trial or premium)
  final DateTime? subscriptionExpiresAt;
  
  /// Payment status: "active" | "expired" | "trial"
  final String paymentStatus;
  
  /// Authentication provider: "email" | "google"
  final String authProvider;
  
  /// Google user ID (for OAuth users)
  final String? googleId;
  
  /// User ID who sent the invitation code
  final String? invitedBy;
  
  /// Current number of tenants (denormalized counter for freemium)
  final int currentTenantsCount;
  
  /// Whether user manually selected tenants (vs auto-selected)
  final bool? manualTenantSelection;
  
  /// Deadline for tenant swap opportunity (7 days after trial downgrade)
  final DateTime? swapAvailableUntil;
  
  /// Whether user has used their 1x swap opportunity
  final bool? swapUsed;


  // Convenience getters for role checking
  bool get isTenantOwner => role == 'tenant' && subRole == null;
  bool get isTenantStaff => role == 'tenant' && subRole == 'staff';
  bool get isBusinessOwner => role == 'owner_business' || role == 'owner_bussines';

  UserModel({
    this.id,
    required this.userId,
    required this.role,
    this.subRole,
    this.createdBy,
    required this.username,
    required this.fullName,
    required this.email,
    this.phone,
    this.tenantId,
    this.contractEndDate,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
    // OAuth & Freemium fields
    this.subscriptionTier = 'free',
    this.subscriptionStartedAt,
    this.subscriptionExpiresAt,
    this.paymentStatus = 'active',
    this.authProvider = 'email',
    this.googleId,
    this.invitedBy,
    this.currentTenantsCount = 0,
    this.manualTenantSelection,
    this.swapAvailableUntil,
    this.swapUsed,
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
      subRole: doc.data['sub_role'] as String?,
      createdBy: doc.data['created_by'] as String?,
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
      // OAuth & Freemium fields
      subscriptionTier: doc.data['subscription_tier'] as String? ?? 'free',
      subscriptionStartedAt: doc.data['subscription_started_at'] != null
          ? DateTime.parse(doc.data['subscription_started_at'] as String)
          : null,
      subscriptionExpiresAt: doc.data['subscription_expires_at'] != null
          ? DateTime.parse(doc.data['subscription_expires_at'] as String)
          : null,
      paymentStatus: doc.data['payment_status'] as String? ?? 'active',
      authProvider: doc.data['auth_provider'] as String? ?? 'email',
      googleId: doc.data['google_id'] as String?,
      invitedBy: doc.data['invited_by'] as String?,
      currentTenantsCount: doc.data['current_tenants_count'] as int? ?? 0,
      manualTenantSelection: doc.data['manual_tenant_selection'] as bool?,
      swapAvailableUntil: doc.data['swap_available_until'] != null
          ? DateTime.parse(doc.data['swap_available_until'] as String)
          : null,
      swapUsed: doc.data['swap_used'] as bool?,
    );
  }

  /// Create from JSON (for backward compatibility)
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['\$id'] as String?,
      userId: json['user_id'] as String,
      role: json['role'] as String,
      subRole: json['sub_role'] as String?,
      createdBy: json['created_by'] as String?,
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
      // OAuth & Freemium fields
      subscriptionTier: json['subscription_tier'] as String? ?? 'free',
      subscriptionStartedAt: json['subscription_started_at'] != null
          ? DateTime.parse(json['subscription_started_at'] as String)
          : null,
      subscriptionExpiresAt: json['subscription_expires_at'] != null
          ? DateTime.parse(json['subscription_expires_at'] as String)
          : null,
      paymentStatus: json['payment_status'] as String? ?? 'active',
      authProvider: json['auth_provider'] as String? ?? 'email',
      googleId: json['google_id'] as String?,
      invitedBy: json['invited_by'] as String?,
      currentTenantsCount: json['current_tenants_count'] as int? ?? 0,
      manualTenantSelection: json['manual_tenant_selection'] as bool?,
      swapAvailableUntil: json['swap_available_until'] != null
          ? DateTime.parse(json['swap_available_until'] as String)
          : null,
      swapUsed: json['swap_used'] as bool?,
    );
  }

  /// Convert to Map for Appwrite
  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'role': role,
      'sub_role': subRole,
      'created_by': createdBy, // Deprecated but keep for backward compatibility
      'username': username,
      'full_name': fullName,
      'email': email,
      'phone': phone,
      'tenant_id': tenantId,
      'contract_end_date': contractEndDate?.toIso8601String(),
      'is_active': isActive,
      // OAuth & Freemium fields
      'subscription_tier': subscriptionTier,
      'subscription_started_at': subscriptionStartedAt?.toIso8601String(),
      'subscription_expires_at': subscriptionExpiresAt?.toIso8601String(),
      'payment_status': paymentStatus,
      'auth_provider': authProvider,
      'google_id': googleId,
      'invited_by': invitedBy,
      'current_tenants_count': currentTenantsCount,
    };
  }

  /// Copy with
  UserModel copyWith({
    String? id,
    String? userId,
    String? role,
    String? subRole,
    String? createdBy,
    String? username,
    String? fullName,
    String? email,
    String? phone,
    String? tenantId,
    DateTime? contractEndDate,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    // OAuth & Freemium fields
    String? subscriptionTier,
    DateTime? subscriptionStartedAt,
    DateTime? subscriptionExpiresAt,
    String? paymentStatus,
    String? authProvider,
    String? googleId,
    String? invitedBy,
    int? currentTenantsCount,
  }) {
    return UserModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      role: role ?? this.role,
      subRole: subRole ?? this.subRole,
      createdBy: createdBy ?? this.createdBy,
      username: username ?? this.username,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      tenantId: tenantId ?? this.tenantId,
      contractEndDate: contractEndDate ?? this.contractEndDate,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      // OAuth & Freemium fields
      subscriptionTier: subscriptionTier ?? this.subscriptionTier,
      subscriptionStartedAt: subscriptionStartedAt ?? this.subscriptionStartedAt,
      subscriptionExpiresAt: subscriptionExpiresAt ?? this.subscriptionExpiresAt,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      authProvider: authProvider ?? this.authProvider,
      googleId: googleId ?? this.googleId,
      invitedBy: invitedBy ?? this.invitedBy,
      currentTenantsCount: currentTenantsCount ?? this.currentTenantsCount,
    );
  }

  // Convenience getters for subscription
  bool get isPremium => subscriptionTier == 'premium';
  bool get isFree => subscriptionTier == 'free';
  bool get isTrialActive => paymentStatus == 'trial' && 
      subscriptionExpiresAt != null && 
      subscriptionExpiresAt!.isAfter(DateTime.now());
  bool get isSubscriptionExpired => subscriptionExpiresAt != null && 
      subscriptionExpiresAt!.isBefore(DateTime.now());
}
