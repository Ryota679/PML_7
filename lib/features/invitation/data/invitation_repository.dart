import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import 'package:kantin_app/core/config/appwrite_config.dart';
import 'package:kantin_app/core/utils/logger.dart';
import 'package:kantin_app/core/utils/invitation_code_generator.dart';

/// Repository for managing invitation codes
class InvitationRepository {
  final Databases _database;
  
  InvitationRepository(this._database);
  
  /// Generate and save invitation code
  /// 
  /// Creates a new invitation code in the database
  /// Code expires after 5 hours
  Future<Document> generateInvitation({
    required String type,
    required String createdBy,
    required String tenantId,
  }) async {
    try {
      AppLogger.info('🎫 Generating invitation code: type=$type, tenantId=$tenantId');
      
      // Generate code based on type
      final invitationType = type == 'tenant' 
          ? InvitationType.tenant 
          : InvitationType.staff;
      final code = InvitationCodeGenerator.generate(invitationType);
      
      // Set expiration (5 hours from now)
      final expiresAt = DateTime.now().add(Duration(hours: 5));
      
      // Create document
      final invitation = await _database.createDocument(
        databaseId: AppwriteConfig.databaseId,
        collectionId: 'invitation_codes',
        documentId: ID.unique(),
        data: {
          'code': code,
          'type': type,
          'created_by': createdBy,
          'tenant_id': tenantId,
          'status': 'active',
          'expires_at': expiresAt.toIso8601String(),
        },
      );
      
      AppLogger.info('✅ Invitation code generated: $code');
      return invitation;
      
    } catch (e, stackTrace) {
      AppLogger.error('❌ Failed to generate invitation', e, stackTrace);
      rethrow;
    }
  }
  
  /// Validate invitation code
  /// 
  /// Checks:
  /// 1. Format is valid (XX-XXXXXX)
  /// 2. Code exists in database
  /// 3. Status is 'active'
  /// 4. Not expired
  Future<ValidationResult> validateCode(String code) async {
    try {
      AppLogger.info('🔍 Validating code: $code');
      
      // 1. Check format
      if (!InvitationCodeGenerator.isValidFormat(code)) {
        AppLogger.warning('Invalid code format: $code');
        return ValidationResult(
          isValid: false,
          error: 'Format kode tidak valid. Gunakan format TN-123456 atau ST-123456',
        );
      }
      
      final upperCode = code.toUpperCase();
      
      // 2. Query database
      final result = await _database.listDocuments(
        databaseId: AppwriteConfig.databaseId,
        collectionId: 'invitation_codes',
        queries: [
          Query.equal('code', upperCode),
          Query.limit(1),
        ],
      );
      
      if (result.documents.isEmpty) {
        AppLogger.warning('Code not found: $upperCode');
        return ValidationResult(
          isValid: false,
          error: 'Kode undangan tidak ditemukan',
        );
      }
      
      final doc = result.documents.first;
      
      // 3. Check status
      if (doc.data['status'] != 'active') {
        AppLogger.warning('Code not active: ${doc.data['status']}');
        return ValidationResult(
          isValid: false,
          error: 'Kode sudah digunakan atau tidak aktif',
        );
      }
      
      // 4. Check expiration
      final expiresAt = DateTime.parse(doc.data['expires_at']);
      if (expiresAt.isBefore(DateTime.now())) {
        AppLogger.warning('Code expired: $expiresAt');
        
        // Mark as expired
        try {
          await _database.updateDocument(
            databaseId: AppwriteConfig.databaseId,
            collectionId: 'invitation_codes',
            documentId: doc.$id,
            data: {'status': 'expired'},
          );
        } catch (e) {
          AppLogger.error('Failed to mark code as expired', e);
        }
        
        return ValidationResult(
          isValid: false,
          error: 'Kode sudah expired (maksimal 5 jam)',
        );
      }
      
      // 5. Valid!
      AppLogger.info('✅ Code validated successfully');
      return ValidationResult(
        isValid: true,
        tenantId: doc.data['tenant_id'],
        type: doc.data['type'],
        documentId: doc.$id,
      );
      
    } catch (e, stackTrace) {
      AppLogger.error('❌ Failed to validate code', e, stackTrace);
      return ValidationResult(
        isValid: false,
        error: 'Terjadi kesalahan saat validasi kode',
      );
    }
  }
  
  /// Mark code as used
  /// 
  /// Updates code status to 'used' and records who used it
  Future<void> markAsUsed(String documentId, String userId) async {
    try {
      AppLogger.info('📝 Marking code as used: $documentId by $userId');
      
      await _database.updateDocument(
        databaseId: AppwriteConfig.databaseId,
        collectionId: 'invitation_codes',
        documentId: documentId,
        data: {
          'status': 'used',
          'used_by': userId,
          'used_at': DateTime.now().toIso8601String(),
        },
      );
      
      AppLogger.info('✅ Code marked as used');
      
    } catch (e, stackTrace) {
      AppLogger.error('❌ Failed to mark code as used', e, stackTrace);
      rethrow;
    }
  }
  
  /// Get all invitations created by owner
  /// 
  /// Returns list of invitations with optional status filter
  Future<List<Document>> getInvitationsByOwner(
    String ownerId, {
    String? status,
  }) async {
    try {
      final queries = [
        Query.equal('created_by', ownerId),
        Query.orderDesc('\$createdAt'),
      ];
      
      if (status != null) {
        queries.add(Query.equal('status', status));
      }
      
      final result = await _database.listDocuments(
        databaseId: AppwriteConfig.databaseId,
        collectionId: 'invitation_codes',
        queries: queries,
      );
      
      return result.documents;
      
    } catch (e, stackTrace) {
      AppLogger.error('❌ Failed to get invitations', e, stackTrace);
      rethrow;
    }
  }
}

/// Validation result model
class ValidationResult {
  final bool isValid;
  final String? error;
  final String? tenantId;
  final String? type;
  final String? documentId;
  
  ValidationResult({
    required this.isValid,
    this.error,
    this.tenantId,
    this.type,
    this.documentId,
  });
}
