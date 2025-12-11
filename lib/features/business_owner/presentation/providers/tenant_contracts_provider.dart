import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_app/core/providers/appwrite_provider.dart';
import 'package:kantin_app/core/utils/logger.dart';
import 'package:kantin_app/features/auth/providers/auth_provider.dart';
import 'package:kantin_app/shared/models/user_model.dart';
import '../../data/tenant_contracts_repository.dart';
import '../../data/tenant_user_with_info.dart';

/// Provider for tenant contracts repository
final tenantContractsRepositoryProvider = Provider<TenantContractsRepository>((ref) {
  final databases = ref.watch(appwriteDatabasesProvider);
  return TenantContractsRepository(databases: databases);
});

/// Provider for managing tenant contracts
final tenantContractsProvider = StateNotifierProvider<TenantContractsNotifier, AsyncValue<List<TenantUserWithInfo>>>((ref) {
  final repository = ref.watch(tenantContractsRepositoryProvider);
  final currentUser = ref.watch(authProvider).user;
  
  return TenantContractsNotifier(
    repository: repository,
    currentUser: currentUser,
  );
});

class TenantContractsNotifier extends StateNotifier<AsyncValue<List<TenantUserWithInfo>>> {
  final TenantContractsRepository repository;
  final UserModel? currentUser;

  TenantContractsNotifier({
    required this.repository,
    required this.currentUser,
  }) : super(const AsyncValue.loading()) {
    loadTenantUsers();
  }

  /// Load all tenant users for current business owner
  Future<void> loadTenantUsers() async {
    if (currentUser == null || currentUser?.userId == null) {
      state = const AsyncValue.data([]);
      return;
    }

    state = const AsyncValue.loading();

    try {
      final tenantUsers = await repository.getTenantUsersWithInfo(currentUser!.userId);
      
      // Sort by contract end date (ascending - soonest to expire first)
      tenantUsers.sort((a, b) {
        final aDate = a.user.contractEndDate;
        final bDate = b.user.contractEndDate;
        
        // Null dates go to the end
        if (aDate == null && bDate == null) return 0;
        if (aDate == null) return 1;
        if (bDate == null) return -1;
        
        // Sort ascending (earliest date first)
        return aDate.compareTo(bDate);
      });
      
      state = AsyncValue.data(tenantUsers);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Add contract token (months) to a tenant user
  Future<bool> addContractToken(String userDocId, int months) async {
    try {
      AppLogger.info('🔵 TenantContractsNotifier.addContractToken - userDocId: $userDocId, months: $months');
      await repository.addContractToken(userDocId, months);
      
      // Refresh list
      await loadTenantUsers();
      
      AppLogger.info('✅ Contract token added successfully in notifier');
      return true;
    } catch (e, stackTrace) {
      AppLogger.error('❌ Error in TenantContractsNotifier.addContractToken', e, stackTrace);
      // Keep error in state but don't override
      return false;
    }
  }

  /// Refresh tenant users list
  Future<void> refresh() => loadTenantUsers();
}
