import 'dart:convert';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/enums.dart';
import 'package:appwrite/models.dart' as models;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_app/core/config/appwrite_config.dart';
import 'package:kantin_app/core/utils/logger.dart';
import 'package:kantin_app/shared/models/user_model.dart';
import 'package:kantin_app/shared/providers/appwrite_provider.dart';

/// Auth Repository Provider
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final account = ref.watch(appwriteAccountProvider);
  final database = ref.watch(appwriteDatabaseProvider);
  final functions = ref.watch(appwriteFunctionsProvider);
  return AuthRepository(
    account: account, 
    database: database,
    functions: functions,
  );
});

/// Auth Repository
/// 
/// Repository untuk menangani authentication logic
class AuthRepository {
  final Account account;
  final Databases database;
  final Functions functions;

  AuthRepository({
    required this.account,
    required this.database,
    required this.functions,
  });

  /// Login dengan email dan password
  Future<models.Session> login({
    required String email,
    required String password,
  }) async {
    try {
      AppLogger.info('🔐 === LOGIN ATTEMPT ===');
      AppLogger.info('📧 Email: $email');
      AppLogger.info('🔑 Password length: ${password.length} chars');
      AppLogger.info('⏳ Creating email/password session...');
      
      final session = await account.createEmailPasswordSession(
        email: email,
        password: password,
      );
      
      AppLogger.info('✅ Session created successfully!');
      AppLogger.info('📝 Session ID: ${session.$id}');
      AppLogger.info('👤 User ID: ${session.userId}');
      AppLogger.info('⏰ Expires: ${session.expire}');
      AppLogger.info('🔐 === LOGIN SUCCESS ===');
      return session;
    } catch (e, stackTrace) {
      AppLogger.error('❌ === LOGIN FAILED ===', e, stackTrace);
      AppLogger.error('💥 Error Type: ${e.runtimeType}');
      if (e is AppwriteException) {
        AppLogger.error('📛 Appwrite Error Code: ${e.code}');
        AppLogger.error('📄 Appwrite Error Message: ${e.message}');
        AppLogger.error('🔍 Appwrite Error Type: ${e.type}');
      }
      rethrow;
    }
  }

  /// Logout
  Future<void> logout() async {
    try {
      AppLogger.info('Attempting logout');
      await account.deleteSession(sessionId: 'current');
      AppLogger.info('Logout successful');
    } catch (e, stackTrace) {
      AppLogger.error('Logout failed', e, stackTrace);
      rethrow;
    }
  }

  /// Get current session
  Future<models.Session?> getCurrentSession() async {
    try {
      final session = await account.getSession(sessionId: 'current');
      return session;
    } catch (e) {
      AppLogger.warning('No active session found');
      return null;
    }
  }

  /// Get current user account
  Future<models.User?> getCurrentUser() async {
    try {
      final user = await account.get();
      return user;
    } catch (e) {
      AppLogger.warning('Failed to get current user');
      return null;
    }
  }

  /// Update Account Labels via Appwrite Function
  /// 
  /// Calls create-user function with set_oauth_labels action
  /// NOTE: Labels can only be updated server-side via Users API
  Future<void> updateAccountLabels({
    required String userId,
    required String role,
  }) async {
    try {
      AppLogger.info('🏷️ Setting Auth label for role: $role');
      
      final execution = await functions.createExecution(
        functionId: 'create-user',
        body: jsonEncode({
          'action': 'set_oauth_labels',
          'userId': userId,
          'role': role,
        }),
      );
      
      // Parse response
      final response = jsonDecode(execution.responseBody);
      
      if (response['success'] == true) {
        AppLogger.info('✅ Label set: ${response['data']['label']}');
      } else {
        AppLogger.warning('⚠️ Label failed: ${response['error']}');
      }
      
    } catch (e, stackTrace) {
      AppLogger.error('❌ Failed to set label', e, stackTrace);
      // Don't rethrow - labels are optional
    }
  }

  /// Create OAuth2 Session
  /// 
  /// Initialize OAuth2 flow for social login (Google)
  /// For Flutter mobile apps, Appwrite SDK handles OAuth redirect automatically
  Future<bool> createOAuth2Session({required String provider}) async {
    try {
      AppLogger.info('🔐 Creating OAuth2 session for provider: $provider');
      
      // Create OAuth2 session - will open browser/webview
      // For Flutter, don't specify success/failure URLs
      // SDK will handle OAuth redirect automatically
      await account.createOAuth2Session(
        provider: OAuthProvider.google,
      );
      
      AppLogger.info('✅ OAuth2 session initiated');
      return true;
    } catch (e, stackTrace) {
      AppLogger.error('OAuth2 session creation failed', e, stackTrace);
      rethrow;
    }
  }


  /// Register Customer
  /// Create new customer account and user profile document
  Future<UserModel?> registerCustomer({
    required String name,
    required String email,
    required String password,
    required String phone,
  }) async {
    try {
      AppLogger.info('Registering customer: $email');

      // 1. Create Appwrite account
      final user = await account.create(
        userId: ID.unique(),
        email: email,
        password: password,
        name: name,
      );

      AppLogger.info('Appwrite account created: ${user.$id}');

      // 2. Login automatically
      await account.createEmailPasswordSession(
        email: email,
        password: password,
      );

      // 3. Create user profile document in database
      // CRITICAL: Use Auth User ID as Document ID to prevent mismatch
      final userDoc = await database.createDocument(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.usersCollectionId,
        documentId: user.$id, // ✅ Use Auth ID (was: ID.unique())
        data: {
          'user_id': user.$id,
          'username': name,
          'role': 'customer',
          'email': email,
          'phone': phone,
          'is_active': true,
        },
      );

      final userModel = UserModel.fromDocument(userDoc);
      AppLogger.info('Customer registered successfully');
      
      return userModel;
    } catch (e, stackTrace) {
      AppLogger.error('Customer registration failed', e, stackTrace);
      rethrow;
    }
  }

  /// Get user profile from database
  Future<UserModel?> getUserProfile(String userId) async {
    try {
      AppLogger.info('Fetching user profile for: $userId');
      
      final response = await database.listDocuments(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.usersCollectionId,
        queries: [
          Query.equal('user_id', userId),
          Query.limit(1),
        ],
      );

      if (response.documents.isEmpty) {
        AppLogger.warning('User profile not found');
        return null;
      }

      final userModel = UserModel.fromDocument(response.documents.first);
      AppLogger.info('User profile loaded: ${userModel.role}');
      
      return userModel;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get user profile', e, stackTrace);
      rethrow;
    }
  }

  /// Create User Profile for OAuth Users
  /// 
  /// Creates user document in database for Google OAuth users
  /// Uses OAuth userId as documentId to prevent duplicates
  Future<UserModel> createUserProfile({
    required String userId,
    required String email,
    required String role,
    String? name,
    String? phone,
    String? subRole,  // For Staff differentiation
    String? tenantId, // ← NEW: For direct tenant_id assignment
  }) async {
    try {
      AppLogger.info('📝 Creating user profile: $userId, role: $role, subRole: $subRole, tenantId: $tenantId');
      
      // Use email username as default name if not provided
      final displayName = name ?? email.split('@')[0];
      
      final userDoc = await database.createDocument(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.usersCollectionId,
        documentId: userId, // Use OAuth userId as document ID
        data: {
          'user_id': userId,
          'username': displayName,
          'role': role,
          'sub_role': subRole,
          'email': email,
          'phone': phone ?? '',
          'is_active': true,
          'tenant_id': tenantId, // ← NEW: Set tenant_id directly if provided
        },
      );

      final userModel = UserModel.fromDocument(userDoc);
      AppLogger.info('✅ User profile created successfully: ${userModel.role}, subRole: $subRole');
      
      return userModel;
    } on AppwriteException catch (e) {
      // Check if document already exists
      if (e.code == 409 || e.type == 'document_already_exists') {
        AppLogger.warning('⚠️ User document already exists, waiting for sync...');
        
        try {
          // Wait for Appwrite to sync (eventual consistency)
          await Future.delayed(const Duration(milliseconds: 500));
          
          // Get existing document
          final existing = await database.getDocument(
            databaseId: AppwriteConfig.databaseId,
            collectionId: AppwriteConfig.usersCollectionId,
            documentId: userId,
          );
          
          final userModel = UserModel.fromDocument(existing);
          AppLogger.info('✅ Retrieved existing user profile: ${userModel.role}');
          return userModel;
        } catch (getError) {
          // If still not found after delay, retry fetching one more time
          AppLogger.warning('⚠️ Retrying fetch after sync delay...');
          await Future.delayed(const Duration(milliseconds: 500));
          
          try {
            final existing = await database.getDocument(
              databaseId: AppwriteConfig.databaseId,
              collectionId: AppwriteConfig.usersCollectionId,
              documentId: userId,
            );
            
            final userModel = UserModel.fromDocument(existing);
            AppLogger.info('✅ Retrieved existing user profile on retry: ${userModel.role}');
            return userModel;
          } catch (retryError, stackTrace) {
            AppLogger.error('❌ Failed to get existing user profile after retries', retryError, stackTrace);
            rethrow;
          }
        }
      }
      
      // Other Appwrite errors
      AppLogger.error('❌ Failed to create user profile', e, StackTrace.current);
      rethrow;
    } catch (e, stackTrace) {
      AppLogger.error('❌ Failed to create user profile', e, stackTrace);
      rethrow;
    }
  }

  /// Request password reset
  Future<void> requestPasswordReset(String email) async {
    try {
      AppLogger.info('Requesting password reset for: $email');
      
      // TODO: Implement dengan URL yang sesuai untuk production
      await account.createRecovery(
        email: email,
        url: 'https://your-app.com/reset-password',
      );
      
      AppLogger.info('Password reset email sent');
    } catch (e, stackTrace) {
      AppLogger.error('Password reset request failed', e, stackTrace);
      rethrow;
    }
  }

  /// Update Session Info
  /// 
  /// Update user document dengan session tracking info untuk single device login
  Future<void> updateSessionInfo({
    required String documentId,
    required String sessionId,
    required String devicePlatform,
    String? deviceInfo,
  }) async {
    try {
      if (kDebugMode) {
        print('💾 [AUTH REPO] updateSessionInfo called');
        print('   ├─ Document ID: $documentId');
        print('   ├─ Session ID: $sessionId');
        print('   ├─ Device: $devicePlatform');
        print('   └─ Device Info: $deviceInfo');
      }
      
      AppLogger.info('Updating session info for user: $documentId');
      
      final updateData = {
        'last_session_id': sessionId,
        'last_login_at': DateTime.now().toIso8601String(),
        'last_login_device': devicePlatform,
        'last_login_device_info': deviceInfo,
      };
      
      if (kDebugMode) {
        print('📝 [DATA] Update payload:');
        updateData.forEach((key, value) {
          print('   ├─ $key: $value');
        });
      }
      
      await database.updateDocument(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.usersCollectionId,
        documentId: documentId,
        data: updateData,
      );
      
      if (kDebugMode) print('✅ [AUTH REPO] Database update successful');
      AppLogger.info('Session info updated successfully');
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('❌ [AUTH REPO] Update failed:');
        print('   ├─ Error: $e');
        print('   └─ Type: ${e.runtimeType}');
      }
      AppLogger.error('Failed to update session info', e, stackTrace);
      // Don't rethrow - session tracking is not critical for login success
    }
  }

  /// Delete Account (Permanent)
  /// 
  /// Deletes the user account and all related data via Appwrite Function
  Future<void> deleteAccount(String userId, {bool force = false}) async {
    try {
      AppLogger.info('Deleting account: $userId (force: $force)');
      
      final execution = await functions.createExecution(
        functionId: AppwriteConfig.deleteUserFunctionId,
        body: jsonEncode({
          'userId': userId,
          'force': force,
          'deletedBy': userId, // Self delete
        }),
      );

      AppLogger.info('Delete function executed: ${execution.$id}');

      final response = jsonDecode(execution.responseBody);
      
      if (response['success'] != true) {
        // Check for specific error code
        if (response['code'] == 'HAS_ACTIVE_TENANTS') {
          throw Exception('HAS_ACTIVE_TENANTS');
        }
        throw Exception(response['error'] ?? 'Failed to delete account');
      }
      
      AppLogger.info('Account deleted successfully');
    } catch (e, stackTrace) {
      AppLogger.error('Delete account failed', e, stackTrace);
      rethrow;
    }
  }

  /// Update user profile document
  /// 
  /// Updates specific fields in the user's profile document
  Future<void> updateUserProfile({
    required String userId,
    required Map<String, dynamic> updates,
  }) async {
    try {
      AppLogger.info('Updating user profile: $userId');
      
      await database.updateDocument(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.usersCollectionId,
        documentId: userId,
        data: updates,
      );
      
      AppLogger.info('User profile updated successfully');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to update user profile', e, stackTrace);
      rethrow;
    }
  }
}
