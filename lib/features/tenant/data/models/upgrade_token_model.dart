import 'package:uuid/uuid.dart';

/// Model for upgrade payment tokens
/// Used to grant temporary access to payment page for deactivated users
class UpgradeToken {
  final String token;
  final String userId;
  final String userEmail;
  final DateTime createdAt;
  final DateTime expiresAt;
  final bool isUsed;

  UpgradeToken({
    required this.token,
    required this.userId,
    required this.userEmail,
    required this.createdAt,
    required this.expiresAt,
    this.isUsed = false,
  });

  /// Generate a new upgrade token with 1 hour expiry
  factory UpgradeToken.generate({
    required String userId,
    required String userEmail,
  }) {
    final now = DateTime.now();
    const uuid = Uuid();
    
    return UpgradeToken(
      token: uuid.v4(), // Generate secure UUID
      userId: userId,
      userEmail: userEmail,
      createdAt: now,
      expiresAt: now.add(const Duration(hours: 1)),
      isUsed: false,
    );
  }

  /// Check if token is still valid
  bool get isValid {
    return !isUsed && DateTime.now().isBefore(expiresAt);
  }

  /// Check if token is expired
  bool get isExpired {
    return DateTime.now().isAfter(expiresAt);
  }

  /// Convert to map for storage (in-memory for now, can be database later)
  Map<String, dynamic> toMap() {
    return {
      'token': token,
      'user_id': userId,
      'user_email': userEmail,
      'created_at': createdAt.toIso8601String(),
      'expires_at': expiresAt.toIso8601String(),
      'is_used': isUsed,
    };
  }

  /// Create from map
  factory UpgradeToken.fromMap(Map<String, dynamic> map) {
    return UpgradeToken(
      token: map['token'] as String,
      userId: map['user_id'] as String,
      userEmail: map['user_email'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      expiresAt: DateTime.parse(map['expires_at'] as String),
      isUsed: map['is_used'] as bool? ?? false,
    );
  }

  /// Copy with modifications
  UpgradeToken copyWith({
    String? token,
    String? userId,
    String? userEmail,
    DateTime? createdAt,
    DateTime? expiresAt,
    bool? isUsed,
  }) {
    return UpgradeToken(
      token: token ?? this.token,
      userId: userId ?? this.userId,
      userEmail: userEmail ?? this.userEmail,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      isUsed: isUsed ?? this.isUsed,
    );
  }
}
