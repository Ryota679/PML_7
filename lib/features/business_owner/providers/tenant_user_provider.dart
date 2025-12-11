import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/appwrite_provider.dart';
import '../../../core/utils/app_logger.dart';
import '../../../shared/models/user_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/tenant_user_repository.dart';

/// Provider for TenantUserRepository
final tenantUserRepositoryProvider = Provider<TenantUserRepository>((ref) {
  final databases = ref.watch(appwriteDatabasesProvider);
  final functions = ref.watch(appwriteFunctionsProvider);
  return TenantUserRepository(databases, functions);
});

/// State for tenant user management
class TenantUserState {
  final List<UserModel> users;
  final bool isLoading;
  final String? error;

  const TenantUserState({
    this.users = const [],
    this.isLoading = false,
    this.error,
  });

  TenantUserState copyWith({
    List<UserModel>? users,
    bool? isLoading,
    String? error,
  }) {
    return TenantUserState(
      users: users ?? this.users,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Notifier for managing tenant user state
class TenantUserNotifier extends StateNotifier<TenantUserState> {
  final TenantUserRepository _repository;
  final String _ownerId;

  TenantUserNotifier(this._repository, this._ownerId)
      : super(const TenantUserState());

  /// Load all tenant users for the owner
  Future<void> loadTenantUsers() async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final users = await _repository.getTenantUsersByOwner(_ownerId);

      state = state.copyWith(
        users: users,
        isLoading: false,
      );
    } catch (e, stackTrace) {
      AppLogger.error('Error loading tenant users', e, stackTrace);
      state = state.copyWith(
        isLoading: false,
        error: 'Gagal memuat data user: $e',
      );
    }
  }

  /// Assign user to tenant
  Future<bool> assignUserToTenant(String userDocId, String tenantId) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final updatedUser = await _repository.assignUserToTenant(
        userDocId,
        tenantId,
      );

      // Add or update in list
      final userExists = state.users.any((u) => u.id == updatedUser.id);
      final updatedList = userExists
          ? state.users.map((u) => u.id == updatedUser.id ? updatedUser : u).toList()
          : [updatedUser, ...state.users];

      state = state.copyWith(
        users: updatedList,
        isLoading: false,
      );

      AppLogger.info('User assigned to tenant successfully');
      return true;
    } catch (e, stackTrace) {
      AppLogger.error('Error assigning user to tenant', e, stackTrace);
      state = state.copyWith(
        isLoading: false,
        error: 'Gagal assign user ke tenant: $e',
      );
      return false;
    }
  }

  /// Remove user from tenant
  Future<bool> removeUserFromTenant(String userDocId) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      await _repository.removeUserFromTenant(userDocId);

      // Remove from list
      final updatedList = state.users.where((u) => u.id != userDocId).toList();

      state = state.copyWith(
        users: updatedList,
        isLoading: false,
      );

      AppLogger.info('User removed from tenant successfully');
      return true;
    } catch (e, stackTrace) {
      AppLogger.error('Error removing user from tenant', e, stackTrace);
      state = state.copyWith(
        isLoading: false,
        error: 'Gagal remove user dari tenant: $e',
      );
      return false;
    }
  }

  /// Toggle user active status
  Future<bool> toggleUserStatus(String userDocId, bool isActive) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final updatedUser = await _repository.toggleUserStatus(userDocId, isActive);

      // Update in list
      final updatedList = state.users.map((u) {
        return u.id == userDocId ? updatedUser : u;
      }).toList();

      state = state.copyWith(
        users: updatedList,
        isLoading: false,
      );

      AppLogger.info('User status toggled successfully');
      return true;
    } catch (e, stackTrace) {
      AppLogger.error('Error toggling user status', e, stackTrace);
      state = state.copyWith(
        isLoading: false,
        error: 'Gagal mengubah status user: $e',
      );
      return false;
    }
  }

  /// Delete user permanently with cascading delete
  Future<bool> deleteUserPermanent(String userDocId, String deletedBy) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      await _repository.deleteUserPermanent(userDocId, deletedBy);

      // Remove from list
      final updatedList = state.users.where((u) => u.id != userDocId).toList();

      state = state.copyWith(
        users: updatedList,
        isLoading: false,
      );

      AppLogger.info('User deleted permanently');
      return true;
    } catch (e, stackTrace) {
      AppLogger.error('Error deleting user permanently', e, stackTrace);
      state = state.copyWith(
        isLoading: false,
        error: 'Gagal delete user: $e',
      );
      return false;
    }
  }
}

/// Provider for tenant user management
final tenantUserProvider =
    StateNotifierProvider.family<TenantUserNotifier, TenantUserState, String>(
  (ref, ownerId) {
    final repository = ref.watch(tenantUserRepositoryProvider);
    return TenantUserNotifier(repository, ownerId);
  },
);

/// Convenience provider that auto-fetches ownerId from auth
final myTenantUsersProvider =
    StateNotifierProvider<TenantUserNotifier, TenantUserState>(
  (ref) {
    final auth = ref.watch(authProvider);
    final ownerId = auth.user?.userId ?? '';
    final repository = ref.watch(tenantUserRepositoryProvider);
    final notifier = TenantUserNotifier(repository, ownerId);

    // Auto-load on initialization
    if (ownerId.isNotEmpty) {
      Future.microtask(() => notifier.loadTenantUsers());
    }

    return notifier;
  },
);

/// Provider for available users (no tenant assigned)
final availableUsersProvider = FutureProvider<List<UserModel>>((ref) async {
  final repository = ref.watch(tenantUserRepositoryProvider);
  return repository.getAvailableUsers();
});
