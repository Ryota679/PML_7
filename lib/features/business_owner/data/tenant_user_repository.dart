import 'dart:convert';

import 'package:appwrite/appwrite.dart';
import '../../../core/config/appwrite_config.dart';
import '../../../core/utils/app_logger.dart';
import '../../../shared/models/user_model.dart';

/// Repository for tenant user management
class TenantUserRepository {
  final Databases _databases;
  final Functions _functions;

  TenantUserRepository(this._databases, this._functions);

  /// Get all tenant users for tenants owned by a specific owner
  Future<List<UserModel>> getTenantUsersByOwner(String ownerId) async {
    try {
      AppLogger.info('Fetching tenant users for owner: $ownerId');

      // First, get all tenants owned by this owner
      final tenantsResponse = await _databases.listDocuments(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.tenantsCollectionId,
        queries: [
          Query.equal('owner_id', ownerId),
          Query.limit(100),
        ],
      );

      if (tenantsResponse.documents.isEmpty) {
        AppLogger.info('No tenants found for owner');
        return [];
      }

      // Get tenant IDs
      final tenantIds = tenantsResponse.documents
          .map((doc) => doc.$id)
          .toList();

      // Get all users assigned to these tenants
      final usersResponse = await _databases.listDocuments(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.usersCollectionId,
        queries: [
          Query.equal('role', 'tenant'),
          Query.limit(100),
        ],
      );

      // Filter users that belong to owner's tenants
      final tenantUsers = usersResponse.documents
          .map((doc) => UserModel.fromDocument(doc))
          .where((user) => 
            user.tenantId != null && 
            tenantIds.contains(user.tenantId) &&
            user.subRole != 'staff' // Exclude staff users
          )
          .toList();

      AppLogger.info('Found ${tenantUsers.length} tenant users');
      return tenantUsers;
    } catch (e, stackTrace) {
      AppLogger.error('Error fetching tenant users', e, stackTrace);
      rethrow;
    }
  }

  /// Get users assigned to a specific tenant
  Future<List<UserModel>> getUsersByTenantId(String tenantId) async {
    try {
      AppLogger.info('Fetching users for tenant: $tenantId');

      final response = await _databases.listDocuments(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.usersCollectionId,
        queries: [
          Query.equal('tenant_id', tenantId),
          Query.equal('role', 'tenant'),
          Query.limit(100),
        ],
      );

      final users = response.documents
          .map((doc) => UserModel.fromDocument(doc))
          .toList();

      AppLogger.info('Found ${users.length} users for tenant');
      return users;
    } catch (e, stackTrace) {
      AppLogger.error('Error fetching users by tenant', e, stackTrace);
      rethrow;
    }
  }

  /// Assign user to tenant
  Future<UserModel> assignUserToTenant(
    String userDocId,
    String tenantId,
  ) async {
    try {
      AppLogger.info('Assigning user $userDocId to tenant $tenantId');

      final doc = await _databases.updateDocument(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.usersCollectionId,
        documentId: userDocId,
        data: {
          'tenant_id': tenantId,
          'role': 'tenant',
        },
      );

      AppLogger.info('User assigned to tenant successfully');
      return UserModel.fromDocument(doc);
    } catch (e, stackTrace) {
      AppLogger.error('Error assigning user to tenant', e, stackTrace);
      rethrow;
    }
  }

  /// Remove user from tenant
  Future<UserModel> removeUserFromTenant(String userDocId) async {
    try {
      AppLogger.info('Removing user $userDocId from tenant');

      final doc = await _databases.updateDocument(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.usersCollectionId,
        documentId: userDocId,
        data: {
          'tenant_id': null,
        },
      );

      AppLogger.info('User removed from tenant successfully');
      return UserModel.fromDocument(doc);
    } catch (e, stackTrace) {
      AppLogger.error('Error removing user from tenant', e, stackTrace);
      rethrow;
    }
  }

  /// Get available users (users without tenant assignment)
  Future<List<UserModel>> getAvailableUsers() async {
    try {
      AppLogger.info('Fetching available users (no tenant assigned)');

      // Fetch all users with role 'tenant'
      final response = await _databases.listDocuments(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.usersCollectionId,
        queries: [
          Query.equal('role', 'tenant'),
          Query.limit(100),
        ],
      );

      // Filter users that don't have tenant_id assigned (client-side filtering)
      final users = response.documents
          .map((doc) => UserModel.fromDocument(doc))
          .where((user) => user.tenantId == null || user.tenantId!.isEmpty)
          .toList();

      AppLogger.info('Found ${users.length} available users');
      return users;
    } catch (e, stackTrace) {
      AppLogger.error('Error fetching available users', e, stackTrace);
      rethrow;
    }
  }

  /// Toggle user active status
  Future<UserModel> toggleUserStatus(String userDocId, bool isActive) async {
    try {
      AppLogger.info('Toggling user $userDocId status to $isActive');

      final doc = await _databases.updateDocument(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.usersCollectionId,
        documentId: userDocId,
        data: {
          'is_active': isActive,
        },
      );

      AppLogger.info('User status updated successfully');
      return UserModel.fromDocument(doc);
    } catch (e, stackTrace) {
      AppLogger.error('Error toggling user status', e, stackTrace);
      rethrow;
    }
  }

  /// Delete user permanently via Appwrite function
  /// This will cascade delete all related data (staff, products, orders)
  Future<void> deleteUserPermanent(String userDocId, String deletedBy) async {
    try {
      AppLogger.info('Deleting user $userDocId permanently by $deletedBy');

      // Call delete-user Appwrite function
      final execution = await _functions.createExecution(
        functionId: AppwriteConfig.deleteUserFunctionId,
        body: jsonEncode({
          'userId': userDocId,
          'deletedBy': deletedBy,
          'force': false,
        }),
      );

      AppLogger.info('Delete user function executed: ${execution.$id}');

      // Parse response
      final responseBody = jsonDecode(execution.responseBody);
      
      if (responseBody['success'] != true) {
        throw Exception(responseBody['error'] ?? 'Failed to delete user');
      }

      AppLogger.info('User deleted permanently: ${responseBody['message']}');
    } catch (e, stackTrace) {
      AppLogger.error('Error deleting user permanently', e, stackTrace);
      rethrow;
    }
  }
}
