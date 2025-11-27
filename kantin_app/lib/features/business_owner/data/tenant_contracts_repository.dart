import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import 'package:kantin_app/core/config/appwrite_config.dart';
import 'package:kantin_app/shared/models/user_model.dart';
import 'package:kantin_app/shared/models/tenant_model.dart';
import 'tenant_user_with_info.dart';

/// Repository for managing tenant contracts
class TenantContractsRepository {
  final Databases databases;

  TenantContractsRepository({required this.databases});

  /// Get all tenant users for a business owner with tenant info
  Future<List<TenantUserWithInfo>> getTenantUsersWithInfo(String businessOwnerId) async {
    // Step 1: Get all tenants owned by this business owner
    final tenantsResponse = await databases.listDocuments(
      databaseId: AppwriteConfig.databaseId,
      collectionId: AppwriteConfig.tenantsCollectionId,
      queries: [
        Query.equal('owner_id', businessOwnerId),
      ],
    );

    if (tenantsResponse.documents.isEmpty) {
      return []; // No tenants, no tenant users
    }

    // Create map of tenant ID -> tenant info
    final tenantMap = <String, models.Document>{};
    for (var doc in tenantsResponse.documents) {
      tenantMap[doc.$id] = doc;
    }

    final tenantIds = tenantMap.keys.toList();

    // Step 2: Get all users with role='tenant' and sub_role IS NULL (only owners, not staff)
    final usersResponse = await databases.listDocuments(
      databaseId: AppwriteConfig.databaseId,
      collectionId: AppwriteConfig.usersCollectionId,
      queries: [
        Query.equal('role', 'tenant'),
        Query.isNull('sub_role'), // Only tenant owners
      ],
    );

    // Step 3: Filter by tenant_id and combine with tenant info
    final tenantUsersWithInfo = <TenantUserWithInfo>[];
    for (var doc in usersResponse.documents) {
      final user = UserModel.fromDocument(doc);
      
      if (user.tenantId != null && tenantIds.contains(user.tenantId)) {
        final tenantDoc = tenantMap[user.tenantId];
        if (tenantDoc != null) {
          tenantUsersWithInfo.add(TenantUserWithInfo(
            user: user,
            tenantName: tenantDoc.data['name'] as String,
            tenantType: tenantDoc.data['type'] as String?,
          ));
        }
      }
    }

    return tenantUsersWithInfo;
  }

  /// Add contract token (months) to a tenant user
  Future<void> addContractToken(String userDocId, int months) async {
    // Get current user document
    final userDoc = await databases.getDocument(
      databaseId: AppwriteConfig.databaseId,
      collectionId: AppwriteConfig.usersCollectionId,
      documentId: userDocId,
    );

    // Get current contract end date or use now if null
    DateTime baseDate;
    final contractEndDateStr = userDoc.data['contract_end_date'] as String?;
    
    if (contractEndDateStr != null) {
      final currentEndDate = DateTime.parse(contractEndDateStr);
      // If expired, extend from now. Otherwise extend from current end date
      final now = DateTime.now();
      baseDate = currentEndDate.isAfter(now) ? currentEndDate : now;
    } else {
      baseDate = DateTime.now();
    }

    // Calculate new end date
    final newEndDate = DateTime(
      baseDate.year,
      baseDate.month + months,
      baseDate.day,
      baseDate.hour,
      baseDate.minute,
      baseDate.second,
    );

    // Update user document
    await databases.updateDocument(
      databaseId: AppwriteConfig.databaseId,
      collectionId: AppwriteConfig.usersCollectionId,
      documentId: userDocId,
      data: {
        'contract_end_date': newEndDate.toIso8601String(),
      },
    );
  }
}
