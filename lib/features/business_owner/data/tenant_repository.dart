import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import '../../../core/config/appwrite_config.dart';
import '../../../core/utils/app_logger.dart';
import '../../../core/utils/tenant_code_generator.dart';
import '../../../shared/models/tenant_model.dart';

/// Repository for tenant CRUD operations
class TenantRepository {
  final Databases _databases;

  TenantRepository(this._databases);

  /// Get all tenants for a specific owner
  Future<List<TenantModel>> getTenantsByOwnerId(String ownerId) async {
    try {
      AppLogger.info('Fetching tenants for owner: $ownerId');

      final response = await _databases.listDocuments(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.tenantsCollectionId,
        queries: [
          Query.equal('owner_id', ownerId),
          Query.orderDesc('\$createdAt'),
          Query.limit(100),
        ],
      );

      final tenants = response.documents
          .map((doc) => TenantModel.fromDocument(doc))
          .toList();

      AppLogger.info('Found ${tenants.length} tenants');
      return tenants;
    } catch (e, stackTrace) {
      AppLogger.error('Error fetching tenants', e, stackTrace);
      rethrow;
    }
  }

  /// Get a single tenant by ID
  Future<TenantModel?> getTenantById(String tenantId) async {
    try {
      AppLogger.info('Fetching tenant: $tenantId');

      final doc = await _databases.getDocument(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.tenantsCollectionId,
        documentId: tenantId,
      );

      return TenantModel.fromDocument(doc);
    } catch (e, stackTrace) {
      AppLogger.error('Error fetching tenant', e, stackTrace);
      return null;
    }
  }

  /// Create a new tenant
  Future<TenantModel> createTenant({
    required String ownerId,
    required String name,
    required TenantType type,
    String? description,
    String? logoUrl,
    String? phone,
    int displayOrder = 0,
  }) async {
    try {
      AppLogger.info('Creating tenant: $name');

      final data = {
        'owner_id': ownerId,
        'name': name,
        'type': type.value,
        'description': description,
        'is_active': true,
        'logo_url': logoUrl,
        'phone': phone,
        'display_order': displayOrder,
      };

      final doc = await _databases.createDocument(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.tenantsCollectionId,
        documentId: ID.unique(),
        data: data,
        permissions: [
          Permission.read(Role.any()),
          Permission.update(Role.user(ownerId)),
          Permission.delete(Role.user(ownerId)),
        ],
      );

      AppLogger.info('Tenant created: ${doc.$id}');
      
      // Auto-generate and save tenant code
      try {
        final tenantCode = TenantCodeGenerator.generateCode(doc.$id);
        AppLogger.info('Generated tenant code: $tenantCode for ${doc.$id}');
        
        final updatedDoc = await _databases.updateDocument(
          databaseId: AppwriteConfig.databaseId,
          collectionId: AppwriteConfig.tenantsCollectionId,
          documentId: doc.$id,
          data: {'tenant_code': tenantCode},
        );
        
        AppLogger.info('Tenant code saved successfully');
        return TenantModel.fromDocument(updatedDoc);
      } catch (codeError) {
        AppLogger.warning('Failed to save tenant code, but tenant created: $codeError');
        // Return tenant without code (will be generated on-the-fly)
        return TenantModel.fromDocument(doc);
      }
    } catch (e, stackTrace) {
      AppLogger.error('Error creating tenant', e, stackTrace);
      rethrow;
    }
  }

  /// Update an existing tenant
  Future<TenantModel> updateTenant(
    String tenantId,
    Map<String, dynamic> updates,
  ) async {
    try {
      AppLogger.info('Updating tenant: $tenantId');

      final doc = await _databases.updateDocument(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.tenantsCollectionId,
        documentId: tenantId,
        data: updates,
      );

      AppLogger.info('Tenant updated: $tenantId');
      return TenantModel.fromDocument(doc);
    } catch (e, stackTrace) {
      AppLogger.error('Error updating tenant', e, stackTrace);
      rethrow;
    }
  }

  /// Delete a tenant
  Future<void> deleteTenant(String tenantId) async {
    try {
      AppLogger.info('Deleting tenant: $tenantId');

      await _databases.deleteDocument(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.tenantsCollectionId,
        documentId: tenantId,
      );

      AppLogger.info('Tenant deleted: $tenantId');
    } catch (e, stackTrace) {
      AppLogger.error('Error deleting tenant', e, stackTrace);
      rethrow;
    }
  }

  /// Toggle tenant active status
  Future<TenantModel> toggleTenantStatus(
    String tenantId,
    bool isActive,
  ) async {
    try {
      AppLogger.info('Toggling tenant status: $tenantId to $isActive');

      return await updateTenant(tenantId, {'is_active': isActive});
    } catch (e, stackTrace) {
      AppLogger.error('Error toggling tenant status', e, stackTrace);
      rethrow;
    }
  }

  /// Get active tenants for an owner
  Future<List<TenantModel>> getActiveTenants(String ownerId) async {
    try {
      AppLogger.info('Fetching active tenants for owner: $ownerId');

      final response = await _databases.listDocuments(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.tenantsCollectionId,
        queries: [
          Query.equal('owner_id', ownerId),
          Query.equal('is_active', true),
          Query.orderAsc('display_order'),
          Query.limit(100),
        ],
      );

      final tenants = response.documents
          .map((doc) => TenantModel.fromDocument(doc))
          .toList();

      AppLogger.info('Found ${tenants.length} active tenants');
      return tenants;
    } catch (e, stackTrace) {
      AppLogger.error('Error fetching active tenants', e, stackTrace);
      rethrow;
    }
  }

  /// Update tenant display order
  Future<void> updateDisplayOrder(
    String tenantId,
    int newOrder,
  ) async {
    try {
      AppLogger.info('Updating display order for tenant: $tenantId to $newOrder');

      await updateTenant(tenantId, {'display_order': newOrder});
    } catch (e, stackTrace) {
      AppLogger.error('Error updating display order', e, stackTrace);
      rethrow;
    }
  }
}
