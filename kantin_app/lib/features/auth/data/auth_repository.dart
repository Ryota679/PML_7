import 'package:appwrite/appwrite.dart';
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
  return AuthRepository(account: account, database: database);
});

/// Auth Repository
/// 
/// Repository untuk menangani authentication logic
class AuthRepository {
  final Account account;
  final Databases database;

  AuthRepository({
    required this.account,
    required this.database,
  });

  /// Login dengan email dan password
  Future<models.Session> login({
    required String email,
    required String password,
  }) async {
    try {
      AppLogger.info('Attempting login for: $email');
      
      final session = await account.createEmailPasswordSession(
        email: email,
        password: password,
      );
      
      AppLogger.info('Login successful');
      return session;
    } catch (e, stackTrace) {
      AppLogger.error('Login failed', e, stackTrace);
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
      final userDoc = await database.createDocument(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.usersCollectionId,
        documentId: ID.unique(),
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
}
