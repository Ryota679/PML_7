import 'package:flutter/foundation.dart';
import 'package:appwrite/appwrite.dart';
import 'package:kantin_app/core/config/appwrite_config.dart';
import 'package:kantin_app/shared/models/user_model.dart';
import 'package:kantin_app/shared/models/tenant_model.dart';

/// Grace Period Service
/// 
/// Handles 7-day grace period when trial expires to free tier
/// with excess users per tenant (>1 user)
class GracePeriodService {
  final Databases _databases;

  GracePeriodService(this._databases);

  /// Check if user is currently in grace period (DISABLED)
  bool isInGracePeriod(UserModel user) {
    // Grace period removed - always return false
    return false;
  }

  /// Get days remaining in grace period (0-7) (DISABLED)
  int getDaysRemaining(UserModel user) {
    // Grace period removed - always return 0
    return 0;
  }

  /// Check if grace period has expired (>= 7 days) (DISABLED)
  bool isGracePeriodExpired(UserModel user) {
    // Grace period removed - always return false
    return false;
  }

  /// Start grace period for user (set free_tier_grace_started_at)
  Future<bool> startGracePeriod(String userId) async {
    try {
      await _databases.updateDocument(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.usersCollectionId,
        documentId: userId,
        data: {
          'free_tier_grace_started_at': DateTime.now().toIso8601String(),
          'free_tier_users_chosen': false,
        },
      );
      return true;
    } catch (e) {
      if (kDebugMode) print('Error starting grace period: $e');
      return false;
    }
  }

  /// Get excess users per tenant (users beyond 1 per tenant)
  /// Returns Map<tenantId, List<UserModel>>
  Future<Map<String, List<UserModel>>> getExcessUsers(
    String ownerId,
    List<TenantModel> tenants,
  ) async {
    final Map<String, List<UserModel>> excessUsers = {};

    for (final tenant in tenants) {
      // Get all users for this tenant
      final response = await _databases.listDocuments(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.usersCollectionId,
        queries: [
          Query.equal('tenant_id', tenant.id),
          Query.equal('role', 'tenant'),
          Query.limit(100),
        ],
      );

      final users = response.documents
          .map((doc) => UserModel.fromDocument(doc))
          .toList();

      // If more than 1 user, all others are excess
      if (users.length > 1) {
        excessUsers[tenant.id] = users;
      }
    }

    return excessUsers;
  }

  /// Auto-disable excess users (keep oldest or chosen user)
  Future<bool> autoDisableExcessUsers(
    String ownerId,
    List<TenantModel> tenants,
  ) async {
    try {
      final excessMap = await getExcessUsers(ownerId, tenants);

      for (final entry in excessMap.entries) {
        final tenantId = entry.key;
        final users = entry.value;

        if (users.length <= 1) continue;

        // Sort by created_at to find oldest
        users.sort((a, b) {
          if (a.createdAt == null && b.createdAt == null) return 0;
          if (a.createdAt == null) return 1;
          if (b.createdAt == null) return -1;
          return a.createdAt!.compareTo(b.createdAt!);
        });
        final oldestUser = users.first;

        // Disable all except oldest
        for (final user in users) {
          if (user.id != oldestUser.id) {
            await _disableUser(user.id!, 'grace_expired');
          }
        }
      }

      // Mark as processed
      await _databases.updateDocument(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.usersCollectionId,
        documentId: ownerId,
        data: {
          'free_tier_users_chosen': true,
        },
      );

      return true;
    } catch (e) {
      if (kDebugMode) print('Error auto-disabling excess users: $e');
      return false;
    }
  }

  /// Disable a user with reason
  Future<bool> _disableUser(String userId, String reason) async {
    try {
      await _databases.updateDocument(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.usersCollectionId,
        documentId: userId,
        data: {
          'is_active': false,
          'disabled_reason': reason,
        },
      );
      return true;
    } catch (e) {
      if (kDebugMode) print('Error disabling user: $e');
      return false;
    }
  }

  /// Save user choices (which users to keep active per tenant)
  /// choices: Map<tenantId, userId>
  Future<bool> saveUserChoices(
    String ownerId,
    Map<String, String> choices,
  ) async {
    try {
      // For each tenant, disable all users except chosen one
      for (final entry in choices.entries) {
        final tenantId = entry.key;
        final chosenUserId = entry.value;

        // Get all users for this tenant
        final response = await _databases.listDocuments(
          databaseId: AppwriteConfig.databaseId,
          collectionId: AppwriteConfig.usersCollectionId,
          queries: [
            Query.equal('tenant_id', tenantId),
            Query.equal('role', 'tenant'),
          ],
        );

        // Disable all except chosen
        for (final doc in response.documents) {
          if (doc.$id != chosenUserId) {
            await _disableUser(doc.$id, 'free_tier_limit');
          }
        }
      }

      // Mark as chosen
      await _databases.updateDocument(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.usersCollectionId,
        documentId: ownerId,
        data: {
          'free_tier_users_chosen': true,
        },
      );

      return true;
    } catch (e) {
      if (kDebugMode) print('Error saving user choices: $e');
      return false;
    }
  }

  /// Check and enforce grace period (main entry point)
  Future<void> checkAndEnforceGracePeriod(UserModel user) async {
    // Grace period feature removed - no enforcement needed
    return;
  }

  /// Helper: Check if trial just expired
  bool _isTrialJustExpired(UserModel user) {
    if (user.subscriptionExpiresAt == null) return false;
    
    final now = DateTime.now();
    final expiresAt = user.subscriptionExpiresAt!;
    
    // Trial expired if expires_at is in the past
    return expiresAt.isBefore(now) && user.subscriptionTier == 'trial';
  }
}
