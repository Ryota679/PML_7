import 'package:flutter/foundation.dart';
import 'package:appwrite/appwrite.dart';
import 'package:kantin_app/core/config/appwrite_config.dart';
import 'package:kantin_app/core/providers/appwrite_provider.dart';
import 'package:kantin_app/shared/models/tenant_model.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'tenant_swap_service.g.dart';

/// Handles tenant selection when user is downgraded from trial to free tier
/// 
/// Free tier Business Owners can only have 2 active tenants.
/// During D-7 selection window, they choose which 2 to keep active.
@riverpod
TenantSwapService tenantSwapService(TenantSwapServiceRef ref) {
  final databases = ref.read(appwriteDatabasesProvider);
  return TenantSwapService(databases: databases);
}

class TenantSwapService {
  final Databases _databases;

  TenantSwapService({required Databases databases}) : _databases = databases;

  /// Get all tenants owned by a Business Owner
  Future<List<TenantModel>> getUserTenants(String userId) async {
    final response = await _databases.listDocuments(
      databaseId: AppwriteConfig.databaseId,
      collectionId: AppwriteConfig.tenantsCollectionId,
      queries: [
        Query.equal('owner_id', userId),
        Query.limit(100),
      ],
    );

    return response.documents.map((doc) => TenantModel.fromDocument(doc)).toList();
  }

  /// Save tenant selection for free tier with 1x swap limit
  /// 
  /// Returns:
  /// - success: true/false
  /// - error: error code if failed ('swap_limit_exceeded')
  /// - message: user-facing message
  /// - swapUsed: true if this selection used the 1x swap
  ///  - needsWarning: true if this is first swap (show warning dialog)
  Future<Map<String, dynamic>> saveSelection({
    required String userId,
    required List<String> selectedTenantIds,
  }) async {
    try {
      if (kDebugMode) {
if (kDebugMode) print('🔄 [SWAP DEBUG] Starting saveSelection...');
if (kDebugMode) print('📋 [SWAP DEBUG] userId (from Auth): $userId');
if (kDebugMode) print('📋 [SWAP DEBUG] selectedTenantIds: $selectedTenantIds');
      }
      
      // Fetch user document first to check swap status
      if (kDebugMode) print('🔍 [SWAP DEBUG] Fetching user document...');
      final userDocs = await _databases.listDocuments(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.usersCollectionId,
        queries: [
          Query.equal('user_id', userId),
          Query.limit(1),
        ],
      );

      if (userDocs.documents.isEmpty) {
        if (kDebugMode) print('❌ [SWAP DEBUG] User document not found for user_id: $userId');
        throw Exception('User document not found');
      }

      final userDoc = userDocs.documents.first;
      if (kDebugMode) {
if (kDebugMode) print('✅ [SWAP DEBUG] User document found!');
if (kDebugMode) print('📄 [SWAP DEBUG] Document ID (from DB): ${userDoc.$id}');
if (kDebugMode) print('📄 [SWAP DEBUG] user_id field value: ${userDoc.data['user_id']}');
if (kDebugMode) print('📄 [SWAP DEBUG] Match status: ${userDoc.$id == userId ? "✅ MATCH" : "❌ MISMATCH"}');
      }
      
      final userData = userDoc.data;
      
      // Check if this is a selection CHANGE (not first-time selection)
      final previouslySelected = userData['selected_tenant_ids'] as List?;
      final isChangingSelection = previouslySelected != null && previouslySelected.isNotEmpty;
      final swapUsed = userData['swap_used'] as bool? ?? false;
      
      if (kDebugMode) {
if (kDebugMode) print('🔄 [SWAP DEBUG] Previous selection: $previouslySelected');
if (kDebugMode) print('🔄 [SWAP DEBUG] Is changing selection: $isChangingSelection');
if (kDebugMode) print('🔄 [SWAP DEBUG] Swap already used: $swapUsed');
      }
      
      // VALIDATION: Block 2nd+ swap (only 1x swap allowed during trial)
      if (isChangingSelection && swapUsed) {
        if (kDebugMode) print('⛔ [SWAP DEBUG] Swap limit exceeded!');
        return {
          'success': false,
          'error': 'swap_limit_exceeded',
          'message': 'Anda sudah menggunakan kesempatan swap Anda. Upgrade ke premium untuk mengubah pilihan lagi.',
        };
      }
      
      // Get all tenants
      if (kDebugMode) print('🏪 [SWAP DEBUG] Fetching user tenants...');
      final allTenants = await getUserTenants(userId);
      if (kDebugMode) print('🏪 [SWAP DEBUG] Found ${allTenants.length} tenants');
      final tenantCount = allTenants.length;
      final validTenantIds = allTenants.map((t) => t.id).toSet();
      
      // VALIDATION: Filter out invalid tenant IDs
      final validSelectedIds = selectedTenantIds.where((id) => validTenantIds.contains(id)).toList();
      
      if (validSelectedIds.length != selectedTenantIds.length) {
        if (kDebugMode) print('⚠️ [SWAP DEBUG] Some selected tenant IDs are invalid. Filtered ${selectedTenantIds.length - validSelectedIds.length} invalid IDs');
      }

      // Validation: Either select all when ≤2, or select exactly 2 when >2
      if (tenantCount <= 2) {
        // Auto-select scenario: Must select all
        if (validSelectedIds.length != tenantCount) {
          throw Exception(
              'Untuk ≤2 tenant, harus pilih semua tenant ($tenantCount tenant)');
        }
      } else {
        // Manual select scenario: Must select exactly 2
        if (validSelectedIds.length != 2) {
          throw Exception('Harus memilih tepat 2 tenant');
        }
      }

      // Update each tenant's selection status
      if (kDebugMode) print('📝 [SWAP DEBUG] Updating ${allTenants.length} tenant selection statuses...');
      for (final tenant in allTenants) {
        final isSelected = validSelectedIds.contains(tenant.id);

        await _databases.updateDocument(
          databaseId: AppwriteConfig.databaseId,
          collectionId: AppwriteConfig.tenantsCollectionId,
          documentId: tenant.id,
          data: {
            'selected_for_free_tier': isSelected,
          },
        );
        if (kDebugMode) print('  ✓ Updated tenant: ${tenant.name} (selected: $isSelected)');
      }

      // Update user document with selection + swap tracking
      final updateData = {
        'selected_tenant_ids': validSelectedIds,
        'selection_submitted_at': DateTime.now().toIso8601String(),
      };
      
      // Mark swap as used if this is a change (not first selection)
      if (isChangingSelection && !swapUsed) {
        updateData['swap_used'] = true;
        if (kDebugMode) print('🔄 [SWAP DEBUG] Marking swap as USED');
      }

      if (kDebugMode) {
if (kDebugMode) print('💾 [SWAP DEBUG] Attempting to update user document...');
if (kDebugMode) print('💾 [SWAP DEBUG] Target Document ID: ${userDoc.$id}');
if (kDebugMode) print('💾 [SWAP DEBUG] Update data: $updateData');
      }
      
      try {
        await _databases.updateDocument(
          databaseId: AppwriteConfig.databaseId,
          collectionId: AppwriteConfig.usersCollectionId,
          documentId: userDoc.$id,
          data: updateData,
        );
        if (kDebugMode) print('✅ [SWAP DEBUG] User document updated successfully!');
      } catch (updateError) {
        if (kDebugMode) {
  if (kDebugMode) print('❌ [SWAP DEBUG] Update failed!');
  if (kDebugMode) print('❌ [SWAP DEBUG] Error type: ${updateError.runtimeType}');
  if (kDebugMode) print('❌ [SWAP DEBUG] Error message: $updateError');
          if (updateError.toString().contains('401')) {
    if (kDebugMode) print('🔒 [SWAP DEBUG] 401 UNAUTHORIZED ERROR DETECTED!');
    if (kDebugMode) print('🔒 [SWAP DEBUG] This means permission issue.');
    if (kDebugMode) print('🔒 [SWAP DEBUG] Check:');
    if (kDebugMode) print('   1. Collection "users" permissions (should have Users: Update)');
    if (kDebugMode) print('   2. Document-level permissions for ID: ${userDoc.$id}');
    if (kDebugMode) print('   3. Current user session token (try logout/login)');
          }
        }
        rethrow;
      }

      if (kDebugMode) print('🎉 [SWAP DEBUG] Save selection completed successfully!');
      return {
        'success': true,
        'swapUsed': isChangingSelection, // Indicate if this action used the swap
        'needsWarning': isChangingSelection && !swapUsed, // Show warning for first swap
      };
    } catch (e) {
      if (kDebugMode) {
if (kDebugMode) print('❌ [SWAP DEBUG] Fatal error in saveSelection:');
if (kDebugMode) print('❌ [SWAP DEBUG] Error: $e');
      }
      return {
        'success': false,
        'error': 'save_failed',
        'message': e.toString(),
      };
    }
  }

  /// Use swap opportunity (deprecated - merged into saveSelection)
  @Deprecated('Use saveSelection instead')
  Future<void> useSwapOpportunity(
      String userId, List<String> newTenantIds) async {
    final result = await saveSelection(
      userId: userId,
      selectedTenantIds: newTenantIds,
    );
    
    if (!result['success']) {
      throw Exception(result['message']);
    }
  }
}
