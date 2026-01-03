import 'dart:convert';
import 'package:appwrite/appwrite.dart';
import 'package:kantin_app/core/config/appwrite_config.dart';
import 'package:kantin_app/core/utils/logger.dart';
import 'package:kantin_app/shared/models/registration_request_model.dart';

/// Registration Repository
/// 
/// Repository untuk mengelola pendaftaran Business Owner
class RegistrationRepository {
  final Databases _databases;
  final Account _account;
  final Functions _functions;

  RegistrationRepository({
    required Databases databases,
    required Account account,
    required Functions functions,
  })  : _databases = databases,
        _account = account,
        _functions = functions;

  /// Get semua pending registration requests
  Future<List<RegistrationRequestModel>> getPendingRequests() async {
    try {
      AppLogger.info('Fetching pending registration requests');
      
      final response = await _databases.listDocuments(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.registrationRequestsCollectionId,
        queries: [
          Query.equal('status', 'pending'),
          Query.orderDesc('\$createdAt'),
          Query.limit(50),
        ],
      );

      final requests = response.documents
          .map((doc) => RegistrationRequestModel.fromJson(doc.data))
          .toList();

      AppLogger.info('Found ${requests.length} pending requests');
      return requests;
    } catch (e, stackTrace) {
      AppLogger.error('Error fetching pending requests', e, stackTrace);
      rethrow;
    }
  }

  /// Get all registration requests (with filter)
  Future<List<RegistrationRequestModel>> getAllRequests({
    String? status,
    int limit = 100,
  }) async {
    try {
      AppLogger.info('Fetching all registration requests');
      
      List<String> queries = [
        Query.orderDesc('\$createdAt'),
        Query.limit(limit),
      ];

      if (status != null) {
        queries.add(Query.equal('status', status));
      }

      final response = await _databases.listDocuments(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.registrationRequestsCollectionId,
        queries: queries,
      );

      final requests = response.documents
          .map((doc) => RegistrationRequestModel.fromJson(doc.data))
          .toList();

      AppLogger.info('Found ${requests.length} requests');
      return requests;
    } catch (e, stackTrace) {
      AppLogger.error('Error fetching requests', e, stackTrace);
      rethrow;
    }
  }

  /// Approve registration request
  /// 
  /// Calls Appwrite Function to automatically create user and update status
  /// User will login using password they provided during registration
  /// Returns response data including user details
  Future<Map<String, dynamic>?> approveRequest({
    required String requestId,
    required String adminUserId,
    String? notes,
  }) async {
    try {
      AppLogger.info('Approving registration request via Function: $requestId');

      // Check if Function ID is configured
      if (AppwriteConfig.approveRegistrationFunctionId == 'YOUR_FUNCTION_ID_HERE') {
        throw Exception(
          'Appwrite Function not configured!\n\n'
          'Please deploy the function and update Function ID in:\n'
          'lib/core/config/appwrite_config.dart\n\n'
          'See: appwrite-functions/approve-registration/README.md'
        );
      }

      // Call Appwrite Function to create user (password auto-generated)
      final payload = jsonEncode({
        'requestId': requestId,
        'adminUserId': adminUserId,
        'notes': notes,
      });

      AppLogger.info('Calling Function with payload...');
      final execution = await _functions.createExecution(
        functionId: AppwriteConfig.approveRegistrationFunctionId,
        body: payload,
        xasync: false, // Wait for completion
      );

      // Check execution status
      if (execution.status == 'completed') {
        // Parse response
        final response = jsonDecode(execution.responseBody);
        
        if (response['success'] == true) {
          final userData = response['data'] as Map<String, dynamic>;
          AppLogger.info('✅ User created successfully: ${userData['email']}');
          AppLogger.info('Registration request approved: $requestId');
          
          // Return user data
          return userData;
        } else {
          final error = response['error'] ?? 'Unknown error';
          AppLogger.error('Function returned error: $error', null, null);
          throw Exception('Failed to approve: $error');
        }
      } else if (execution.status == 'failed') {
        AppLogger.error('Function execution failed', execution.responseBody, null);
        throw Exception('Function execution failed: ${execution.responseBody}');
      } else {
        AppLogger.warning('Function execution status: ${execution.status}');
        throw Exception('Unexpected execution status: ${execution.status}');
      }

    } catch (e, stackTrace) {
      AppLogger.error('Error approving request', e, stackTrace);
      rethrow;
    }
  }

  /// Reject registration request
  Future<void> rejectRequest({
    required String requestId,
    required String adminUserId,
    required String reason,
  }) async {
    try {
      AppLogger.info('Rejecting registration request: $requestId');

      await _databases.updateDocument(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.registrationRequestsCollectionId,
        documentId: requestId,
        data: {
          'status': 'rejected',
          'reviewed_by': adminUserId,
          'reviewed_at': DateTime.now().toIso8601String(),
          'admin_notes': reason,
        },
      );

      AppLogger.info('Registration request rejected: $requestId');
    } catch (e, stackTrace) {
      AppLogger.error('Error rejecting request', e, stackTrace);
      rethrow;
    }
  }

  /// Create new registration request (for public registration form)
  Future<RegistrationRequestModel> createRequest({
    required String fullName,
    required String email,
    required String password,
    required String businessName,
    required String businessType,
    String? phone,
  }) async {
    try {
      AppLogger.info('Creating registration request for: $email');

      // Hash password (simple base64 for now, in production use proper hashing)
      final passwordHash = password; // TODO: Implement proper password hashing

      final doc = await _databases.createDocument(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.registrationRequestsCollectionId,
        documentId: ID.unique(),
        data: {
          'full_name': fullName,
          'email': email,
          'password_hash': passwordHash,
          'business_name': businessName,
          'business_type': businessType,
          'phone': phone,
          'status': 'pending',
        },
      );

      final request = RegistrationRequestModel.fromJson(doc.data);
      AppLogger.info('Registration request created: ${request.id}');
      
      return request;
    } catch (e, stackTrace) {
      AppLogger.error('Error creating registration request', e, stackTrace);
      rethrow;
    }
  }
}
