import 'package:appwrite/appwrite.dart';
import 'package:kantin_app/core/config/appwrite_config.dart';
import 'package:kantin_app/shared/models/tenant_model.dart';

/// Tenant Swap Service
/// 
/// Handles tenant selection when user is downgraded from trial to free tier
/// - User can select 2 tenants to keep active
/// - Other tenants become inactive
/// - User has 7-day grace period to swap selection (1x only)
class TenantSwapService {
  final Databases _databases;
  
  TenantSwapService() : _databases = Databases(Client()
    ..setEndpoint(AppwriteConfig.endpoint)
    ..setProject(AppwriteConfig.projectId));

  /// Get all tenants for a user, ordered by creation date (newest first)
  Future<List<TenantModel>> getUserTenants(String userId) async {
    try {
      final response = await _databases.listDocuments(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.tenantsCollectionId,
        queries: [
          Query.equal('owner_id', userId),
          Query.orderDesc('\$createdAt'),
          Query.limit(100),
        ],
      );

      return response.documents
          .map((doc) => TenantModel.fromDocument(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch tenants: $e');
    }
  }

  /// Save user's manual tenant selection
  /// 
  /// Updates:
  /// - Selected tenants: selected_for_free_tier = true
  /// - Other tenants: selected_for_free_tier = false
  /// - User: manual_tenant_selection = true
  Future<void> saveSelection({
    required String userId,
    required List<String> selectedTenantIds,
  }) async {
    if (selectedTenantIds.length != 2) {
      throw Exception('Must select exactly 2 tenants');
    }

    try {
      // Get all user's tenants
      final allTenants = await getUserTenants(userId);

      // Update each tenant's selection status
      for (final tenant in allTenants) {
        final isSelected = selectedTenantIds.contains(tenant.id);
        
        await _databases.updateDocument(
          databaseId: AppwriteConfig.databaseId,
          collectionId: AppwriteConfig.tenantsCollectionId,
          documentId: tenant.id,
          data: {
            'selected_for_free_tier': isSelected,
          },
        );
      }

      // Update user to mark manual selection
      await _databases.updateDocument(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.usersCollectionId,
        documentId: userId,
        data: {
          'manual_tenant_selection': true,
        },
      );
    } catch (e) {
      throw Exception('Failed to save selection: $e');
    }
  }

  /// Use swap opportunity (change selection within grace period)
  /// 
  /// Updates:
  /// - Selected tenants: selected_for_free_tier = true
  /// - Other tenants: selected_for_free_tier = false  
  /// - User: swap_used = true
  Future<void> useSwapOpportunity({
    required String userId,
    required List<String> newSelectedTenantIds,
  }) async {
    if (newSelectedTenantIds.length != 2) {
      throw Exception('Must select exactly 2 tenants');
    }

    try {
      // Get all user's tenants
      final allTenants = await getUserTenants(userId);

      // Update each tenant's selection status
      for (final tenant in allTenants) {
        final isSelected = newSelectedTenantIds.contains(tenant.id);
        
        await _databases.updateDocument(
          databaseId: AppwriteConfig.databaseId,
          collectionId: AppwriteConfig.tenantsCollectionId,
          documentId: tenant.id,
          data: {
            'selected_for_free_tier': isSelected,
          },
        );
      }

      // Mark swap as used
      await _databases.updateDocument(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.usersCollectionId,
        documentId: userId,
        data: {
          'swap_used': true,
        },
      );
    } catch (e) {
      throw Exception('Failed to use swap: $e');
    }
  }

  /// Check if user can still swap selection
  /// 
  /// Returns true if:
  /// - User has swap_available_until in the future
  /// - User has not used swap (swap_used = false)
  Future<bool> canSwap({
    required DateTime? swapAvailableUntil,
    required bool swapUsed,
  }) async {
    if (swapUsed) return false;
    if (swapAvailableUntil == null) return false;
    
    final now = DateTime.now();
    return swapAvailableUntil.isAfter(now);
  }

  /// Get days remaining for swap opportunity
  int getSwapDaysRemaining(DateTime? swapAvailableUntil) {
    if (swapAvailableUntil == null) return 0;
    
    final now = DateTime.now();
    if (swapAvailableUntil.isBefore(now)) return 0;
    
    return swapAvailableUntil.difference(now).inDays;
  }
}
