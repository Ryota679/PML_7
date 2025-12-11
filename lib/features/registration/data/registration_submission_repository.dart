import 'package:appwrite/appwrite.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_app/core/config/appwrite_config.dart';
import 'package:kantin_app/core/utils/logger.dart';
import 'package:kantin_app/shared/providers/appwrite_provider.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

/// Registration Submission Repository Provider
final registrationSubmissionRepositoryProvider =
    Provider<RegistrationSubmissionRepository>((ref) {
  final databases = ref.watch(appwriteDatabaseProvider);
  return RegistrationSubmissionRepository(databases: databases);
});

/// Registration Submission Repository
/// 
/// Repository untuk handle submission registrasi Business Owner
class RegistrationSubmissionRepository {
  final Databases databases;

  RegistrationSubmissionRepository({required this.databases});

  /// Submit registration ke Appwrite
  Future<void> submitRegistration({
    required String fullName,
    required String email,
    required String password,
    required String businessName,
    required String businessType,
    String? phone,
  }) async {
    try {
      AppLogger.info('Submitting registration to Appwrite');

      // Hash password menggunakan SHA-256
      final passwordHash = _hashPassword(password);

      // Create document di collection registration_requests
      await databases.createDocument(
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
          'admin_notes': null,
          'reviewed_by': null,
          'reviewed_at': null,
        },
      );

      AppLogger.info('Registration submitted successfully');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to submit registration', e, stackTrace);
      rethrow;
    }
  }

  /// Hash password menggunakan SHA-256
  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}
