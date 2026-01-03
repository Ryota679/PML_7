import 'dart:convert';
import 'package:appwrite/appwrite.dart';
import 'package:kantin_app/core/config/appwrite_config.dart';
import 'package:kantin_app/core/constants/app_constants.dart';
import 'package:kantin_app/core/utils/logger.dart';
import 'package:kantin_app/shared/models/user_model.dart';

/// User Management Repository
/// 
/// Repository untuk Admin mengelola users (CRUD)
/// NOTE: Due to SDK limitations, this only manages database records
/// For Auth operations, use Appwrite Console or Functions
class UserManagementRepository {
  final Databases _databases;
  final Functions _functions;

  UserManagementRepository({
    required Databases databases,
    required Functions functions,
  }) : _databases = databases,
       _functions = functions;

  /// Get all business owners
  Future<List<UserModel>> getAllBusinessOwners() async {
    try {
      AppLogger.info('Fetching all business owners');
      
      final response = await _databases.listDocuments(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.usersCollectionId,
        queries: [
          Query.equal('role', AppConstants.roleOwnerBusiness), // 'owner_bussines' (matches DB typo)
          Query.orderDesc('\$createdAt'),
          Query.limit(100),
        ],
      );

      final users = response.documents
          .map((doc) => UserModel.fromDocument(doc))
          .toList();

      AppLogger.info('Found ${users.length} business owners');
      return users;
    } catch (e, stackTrace) {
      AppLogger.error('Error fetching business owners', e, stackTrace);
      rethrow;
    }
  }

  /// Get single user by ID
  Future<UserModel?> getUserById(String userId) async {
    try {
      AppLogger.info('Fetching user: $userId');
      
      final response = await _databases.listDocuments(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.usersCollectionId,
        queries: [
          Query.equal('user_id', userId),
          Query.limit(1),
        ],
      );

      if (response.documents.isEmpty) {
        return null;
      }

      return UserModel.fromDocument(response.documents.first);
    } catch (e, stackTrace) {
      AppLogger.error('Error fetching user', e, stackTrace);
      rethrow;
    }
  }

  /// Update user information
  Future<void> updateUser({
    required String documentId,
    required String fullName,
    String? phone,
  }) async {
    try {
      AppLogger.info('Updating user: $documentId');

      await _databases.updateDocument(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.usersCollectionId,
        documentId: documentId,
        data: {
          'full_name': fullName,
          'phone': phone,
        },
      );

      AppLogger.info('User updated successfully');
    } catch (e, stackTrace) {
      AppLogger.error('Error updating user', e, stackTrace);
      rethrow;
    }
  }

  /// Delete user (via Appwrite Function)
  Future<void> deleteUser({
    required String authUserId,
    required String documentId,
    bool force = false,
    required String adminId,
  }) async {
    try {
      AppLogger.info('Deleting user: $authUserId (force: $force)');

      final execution = await _functions.createExecution(
        functionId: AppwriteConfig.deleteUserFunctionId,
        body: jsonEncode({
          'userId': authUserId,
          'force': force,
          'deletedBy': adminId,
        }),
      );

      AppLogger.info('Delete function executed: ${execution.$id}');

      final response = jsonDecode(execution.responseBody);
      
      if (response['success'] != true) {
        // Check for specific error code
        if (response['code'] == 'HAS_ACTIVE_TENANTS') {
          throw Exception('HAS_ACTIVE_TENANTS');
        }
        throw Exception(response['error'] ?? 'Failed to delete user');
      }
      
      AppLogger.info('User deleted successfully');
    } catch (e, stackTrace) {
      AppLogger.error('Error deleting user', e, stackTrace);
      rethrow;
    }
  }

  /// Reset user password (requires manual action in Appwrite Console)
  Future<void> resetUserPassword({
    required String authUserId,
    required String newPassword,
  }) async {
    try {
      AppLogger.info('Password reset requested for user: $authUserId');
      
      // NOTE: Password reset via API requires Users API (not available in SDK 13.x)
      // This is a placeholder - admin must manually reset in Appwrite Console
      AppLogger.warning(
        'MANUAL ACTION REQUIRED: Reset password for user $authUserId to "$newPassword" '
        'in Appwrite Console > Auth > Users > Edit User'
      );
      
      // For now, just log the request
      // In production, implement via Appwrite Function
      throw UnimplementedError(
        'Password reset requires manual action in Appwrite Console.\n'
        'Go to: Auth > Users > Find user > Edit > Set new password'
      );
    } catch (e, stackTrace) {
      AppLogger.error('Error resetting password', e, stackTrace);
      rethrow;
    }
  }

  /// Toggle user status (requires manual action)
  Future<void> toggleUserStatus({
    required String authUserId,
    required bool enable,
  }) async {
    try {
      AppLogger.info('Status toggle requested for user: $authUserId');
      
      // Update is_active in database
      final response = await _databases.listDocuments(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.usersCollectionId,
        queries: [
          Query.equal('user_id', authUserId),
          Query.limit(1),
        ],
      );

      if (response.documents.isNotEmpty) {
        await _databases.updateDocument(
          databaseId: AppwriteConfig.databaseId,
          collectionId: AppwriteConfig.usersCollectionId,
          documentId: response.documents.first.$id,
          data: {
            'is_active': enable,
          },
        );
        AppLogger.info('User status updated in database');
      }
    } catch (e, stackTrace) {
      AppLogger.error('Error toggling user status', e, stackTrace);
      rethrow;
    }
  }

  /// Update contract end date (Token system)
  /// Automatically sets is_active based on contract status
  Future<void> updateContractEndDate({
    required String documentId,
    required DateTime contractEndDate,
  }) async {
    try {
      AppLogger.info('Updating contract end date for: $documentId');
      
      // Check if contract is expired
      final now = DateTime.now();
      final isActive = contractEndDate.isAfter(now);
      
      await _databases.updateDocument(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.usersCollectionId,
        documentId: documentId,
        data: {
          'contract_end_date': contractEndDate.toIso8601String(),
          'is_active': isActive,
        },
      );

      AppLogger.info(
        'Contract updated: End date = ${contractEndDate.toIso8601String()}, '
        'Active = $isActive'
      );
    } catch (e, stackTrace) {
      AppLogger.error('Error updating contract end date', e, stackTrace);
      rethrow;
    }
  }

  /// Check and auto-disable expired contracts
  /// Should be called periodically (e.g., daily cron job)
  Future<void> checkAndDisableExpiredContracts() async {
    try {
      AppLogger.info('Checking for expired contracts');
      
      final now = DateTime.now();
      
      // Get all business owners
      final response = await _databases.listDocuments(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.usersCollectionId,
        queries: [
          Query.equal('role', AppConstants.roleOwnerBusiness), // 'owner_bussines'
          Query.equal('is_active', true),
          Query.limit(1000),
        ],
      );

      int disabledCount = 0;
      
      for (final doc in response.documents) {
        final contractEndDateStr = doc.data['contract_end_date'] as String?;
        
        if (contractEndDateStr != null) {
          final contractEndDate = DateTime.parse(contractEndDateStr);
          
          // If expired, disable
          if (contractEndDate.isBefore(now)) {
            await _databases.updateDocument(
              databaseId: AppwriteConfig.databaseId,
              collectionId: AppwriteConfig.usersCollectionId,
              documentId: doc.$id,
              data: {
                'is_active': false,
              },
            );
            
            AppLogger.info('Disabled expired user: ${doc.data['user_id']}');
            disabledCount++;
          }
        }
      }
      
      AppLogger.info('Disabled $disabledCount expired contracts');
    } catch (e, stackTrace) {
      AppLogger.error('Error checking expired contracts', e, stackTrace);
      rethrow;
    }
  }
}
