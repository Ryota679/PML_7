import 'package:appwrite/appwrite.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_app/core/config/appwrite_config.dart';
import 'package:kantin_app/core/utils/logger.dart';
import 'package:kantin_app/shared/models/tenant_model.dart';
import 'package:kantin_app/shared/providers/appwrite_provider.dart';

/// Tenant Repository Provider
final tenantRepositoryProvider = Provider<TenantRepository>((ref) {
  final database = ref.watch(appwriteDatabaseProvider);
  return TenantRepository(database: database);
});

/// Repository untuk tenant data operations
class TenantRepository {
  final Databases database;

  TenantRepository({required this.database});

  /// Get tenant by ID
  Future<TenantModel?> getTenantById(String tenantId) async {
    try {
      AppLogger.info('Fetching tenant: $tenantId');

      final doc = await database.getDocument(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.tenantsCollectionId,
        documentId: tenantId,
      );

      final tenant = TenantModel.fromDocument(doc);
      AppLogger.info('Tenant loaded: ${tenant.name}');
      return tenant;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get tenant', e, stackTrace);
      return null;
    }
  }

  /// Get tenant by code (6-character code)
  Future<TenantModel?> getTenantByCode(String code) async {
    try {
      AppLogger.info('Looking up tenant by code: $code');

      final response = await database.listDocuments(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.tenantsCollectionId,
        queries: [
          Query.equal('tenant_code', code.toUpperCase()),
          Query.limit(1),
        ],
      );

      if (response.documents.isEmpty) {
        AppLogger.warning('No tenant found with code: $code');
        return null;
      }

      final tenant = TenantModel.fromDocument(response.documents.first);
      AppLogger.info('Tenant found: ${tenant.name} (${tenant.id})');
      return tenant;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to lookup tenant by code', e, stackTrace);
      return null;
    }
  }

  /// Get all tenants for an owner
  Future<List<TenantModel>> getTenantsByOwnerId(String ownerId) async {
    try {
      AppLogger.info('Fetching tenants for owner: $ownerId');

      final response = await database.listDocuments(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.tenantsCollectionId,
        queries: [
          Query.equal('owner_id', ownerId),
          Query.orderAsc('display_order'),
        ],
      );

      final tenants = response.documents
          .map((doc) => TenantModel.fromDocument(doc))
          .toList();

      AppLogger.info('Found ${tenants.length} tenants');
      return tenants;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get tenants for owner', e, stackTrace);
      rethrow;
    }
  }

  /// Get all active tenants
  Future<List<TenantModel>> getAllActiveTenants() async {
    try {
      AppLogger.info('Fetching all active tenants');

      final response = await database.listDocuments(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.tenantsCollectionId,
        queries: [
          Query.equal('is_active', true),
          Query.orderAsc('display_order'),
        ],
      );

      final tenants = response.documents
          .map((doc) => TenantModel.fromDocument(doc))
          .toList();

      AppLogger.info('Found ${tenants.length} active tenants');
      return tenants;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get active tenants', e, stackTrace);
      rethrow;
    }
  }

  /// Update tenant code (after migration or manual update)
  Future<bool> updateTenantCode(String tenantId, String code) async {
    try {
      AppLogger.info('Updating tenant code: $tenantId -> $code');

      await database.updateDocument(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.tenantsCollectionId,
        documentId: tenantId,
        data: {
          'tenant_code': code.toUpperCase(),
        },
      );

      AppLogger.info('Tenant code updated successfully');
      return true;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to update tenant code', e, stackTrace);
      return false;
    }
  }
}
