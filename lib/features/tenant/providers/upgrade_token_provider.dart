import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_app/features/tenant/data/models/upgrade_token_model.dart';

/// Provider for managing upgrade payment tokens
/// In-memory storage for now (can be moved to database if needed)
class UpgradeTokenNotifier extends StateNotifier<Map<String, UpgradeToken>> {
  UpgradeTokenNotifier() : super({});

  /// Generate a new upgrade token for a user
  String generateToken({
    required String userId,
    required String userEmail,
  }) {
    final token = UpgradeToken.generate(
      userId: userId,
      userEmail: userEmail,
    );

    // Store in state
    state = {...state, token.token: token};

    if (kDebugMode) print('✅ [TOKEN] Generated upgrade token for $userEmail');
    if (kDebugMode) print('   - Token: ${token.token}');
    if (kDebugMode) print('   - Expires: ${token.expiresAt}');

    return token.token;
  }

  /// Validate a token and return user data if valid
  UpgradeToken? validateToken(String tokenString) {
    final token = state[tokenString];

    if (token == null) {
      if (kDebugMode) print('❌ [TOKEN] Token not found: $tokenString');
      return null;
    }

    if (token.isExpired) {
      if (kDebugMode) print('❌ [TOKEN] Token expired: $tokenString');
      return null;
    }

    if (token.isUsed) {
      if (kDebugMode) print('❌ [TOKEN] Token already used: $tokenString');
      return null;
    }

    if (kDebugMode) print('✅ [TOKEN] Token valid for user: ${token.userEmail}');
    return token;
  }

  /// Mark token as used after successful payment
  void markTokenAsUsed(String tokenString) {
    final token = state[tokenString];
    if (token != null) {
      state = {
        ...state,
        tokenString: token.copyWith(isUsed: true),
      };
      if (kDebugMode) print('✅ [TOKEN] Token marked as used: $tokenString');
    }
  }

  /// Clear expired tokens (cleanup)
  void clearExpiredTokens() {
    final now = DateTime.now();
    state = Map.fromEntries(
      state.entries.where((entry) => entry.value.expiresAt.isAfter(now)),
    );
    if (kDebugMode) print('🧹 [TOKEN] Cleared expired tokens');
  }
}

/// Provider for upgrade token management
final upgradeTokenProvider =
    StateNotifierProvider<UpgradeTokenNotifier, Map<String, UpgradeToken>>(
  (ref) => UpgradeTokenNotifier(),
);
