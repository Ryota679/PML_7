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
  
  /// Whether user has used their 1x swap opportunity during D-7 window
  final bool? swapUsed;
  
  /// Reason user was disabled (grace_expired, free_tier_limit, manual)
  final String? disabledReason;
  
  // ===== NEW: Tiered Freemium Selection Fields =====
  
  /// Array of 2 tenant IDs selected by Business Owner for better limits
  /// Selected tenants: 20 products, 2 staff
  /// Non-selected: 10 products, 1 staff
  final List<String>? selectedTenantIds;
  
  /// When user submitted their tenant selection (vs auto-selected)
  final DateTime? selectionSubmittedAt;
  
  /// Map of tenant_id to array of staff user IDs
  /// Example: {"tenant_id_1": ["staff_1", "staff_2"], "tenant_id_2": ["staff_1"]}
  final Map<String, List<String>>? selectedStaffPerTenant;
  
  // ===== NEW: Single Device Login Fields =====
  
  /// Session ID from last login (for session tracking)
  final String? lastSessionId;
  
  /// Timestamp of last login
  final DateTime? lastLoginAt;
  
  /// Device platform of last login: "web", "android", "ios"
  final String? lastLoginDevice;
  
  /// Detailed device info (optional): "Chrome on Windows", "Android 11", etc.
  final String? lastLoginDeviceInfo;


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
    this.swapUsed,
    this.disabledReason,
    // Tiered freemium selection
    this.selectedTenantIds,
    this.selectionSubmittedAt,
    this.selectedStaffPerTenant,
    // Single device login
    this.lastSessionId,
    this.lastLoginAt,
    this.lastLoginDevice,
    this.lastLoginDeviceInfo,
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
      swapUsed: doc.data['swap_used'] as bool?,
      disabledReason: doc.data['disabled_reason'] as String?,
      // Tiered freemium selection
      selectedTenantIds: doc.data['selected_tenant_ids'] != null
          ? List<String>.from(doc.data['selected_tenant_ids'] as List)
          : null,
      selectionSubmittedAt: doc.data['selection_submitted_at'] != null
          ? DateTime.parse(doc.data['selection_submitted_at'] as String)
          : null,
      selectedStaffPerTenant: doc.data['selected_staff_per_tenant'] != null
          ? (doc.data['selected_staff_per_tenant'] as Map<String, dynamic>).map(
              (key, value) => MapEntry(key, List<String>.from(value as List)),
            )
          : null,
      // Single device login
      lastSessionId: doc.data['last_session_id'] as String?,
      lastLoginAt: doc.data['last_login_at'] != null
          ? DateTime.parse(doc.data['last_login_at'] as String)
          : null,
      lastLoginDevice: doc.data['last_login_device'] as String?,
      lastLoginDeviceInfo: doc.data['last_login_device_info'] as String?,
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
      swapUsed: json['swap_used'] as bool?,
      disabledReason: json['disabled_reason'] as String?,
      // Tiered freemium selection
      selectedTenantIds: json['selected_tenant_ids'] != null
          ? List<String>.from(json['selected_tenant_ids'] as List)
          : null,
      selectionSubmittedAt: json['selection_submitted_at'] != null
          ? DateTime.parse(json['selection_submitted_at'] as String)
          : null,
      selectedStaffPerTenant: json['selected_staff_per_tenant'] != null
          ? (json['selected_staff_per_tenant'] as Map<String, dynamic>).map(
              (key, value) => MapEntry(key, List<String>.from(value as List)),
            )
          : null,
      // Single device login
      lastSessionId: json['last_session_id'] as String?,
      lastLoginAt: json['last_login_at'] != null
          ? DateTime.parse(json['last_login_at'] as String)
          : null,
      lastLoginDevice: json['last_login_device'] as String?,
      lastLoginDeviceInfo: json['last_login_device_info'] as String?,
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
      'manual_tenant_selection': manualTenantSelection,
      'swap_used': swapUsed,
      'disabled_reason': disabledReason,
      // Tiered freemium selection
      'selected_tenant_ids': selectedTenantIds,
      'selection_submitted_at': selectionSubmittedAt?.toIso8601String(),
      'selected_staff_per_tenant': selectedStaffPerTenant,
      // Single device login
      'last_session_id': lastSessionId,
      'last_login_at': lastLoginAt?.toIso8601String(),
      'last_login_device': lastLoginDevice,
      'last_login_device_info': lastLoginDeviceInfo,
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

  // Convenience getters for subscription (updated to use payment_status)
  bool get isPremium => paymentStatus == 'premium' || paymentStatus == 'active';
  bool get isFree => paymentStatus == 'free' || paymentStatus == null;
  bool get isTrialActive => paymentStatus == 'trial' && 
      subscriptionExpiresAt != null && 
      subscriptionExpiresAt!.isAfter(DateTime.now());
  bool get isSubscriptionExpired => subscriptionExpiresAt != null && 
      subscriptionExpiresAt!.isBefore(DateTime.now());
  
  // D-7 Selection helpers
  bool get hasSubmittedSelection => selectionSubmittedAt != null;
  
  int get daysUntilTrialExpiry {
    if (subscriptionExpiresAt == null) return 0;
    final days = subscriptionExpiresAt!.difference(DateTime.now()).inDays;
    return days < 0 ? 0 : days;
  }
  
  bool get isInD7Window {
    if (paymentStatus != 'trial') return false;
    final days = daysUntilTrialExpiry;
    return days >= 0 && days <= 7 && !hasSubmittedSelection;
  }
  
  // ===== Phase 3: Enforcement Helpers =====
  
  /// Check if user is on free tier (for enforcement)
  /// Free tier = not premium/active AND (no trial OR trial expired)
  bool get isFreeTier {
    // If premium or active, not free tier
    if (paymentStatus == 'premium' || paymentStatus == 'active') return false;
    
    // If trial and active, not free tier
    if (paymentStatus == 'trial' && isTrialActive) return false;
    
    // Otherwise, free tier (free/null or expired)
    return true;
  }
  
  /// Check if user can create/edit content (Phase 3 enforcement)
  bool get canEdit => !isFreeTier;
  
  /// Check if user can create new content (Phase 3 enforcement)
  bool get canCreate => !isFreeTier;
  
  /// Get display name for current tier
  String get tierDisplayName {
    if (paymentStatus == 'premium') return 'Premium';
    if (isTrialActive) return 'Trial';
    return 'Free';
  }
}

