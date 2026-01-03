import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_app/features/admin/data/user_management_repository.dart';
import 'package:kantin_app/shared/models/user_model.dart';
import 'package:kantin_app/shared/providers/appwrite_provider.dart';
import 'package:kantin_app/features/auth/providers/auth_provider.dart';

/// User Management State
class UserManagementState {
  final List<UserModel> users;
  final bool isLoading;
  final String? error;

  UserManagementState({
    this.users = const [],
    this.isLoading = false,
    this.error,
  });

  UserManagementState copyWith({
    List<UserModel>? users,
    bool? isLoading,
    String? error,
  }) {
    return UserManagementState(
      users: users ?? this.users,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// User Management Repository Provider
final userManagementRepositoryProvider = Provider<UserManagementRepository>((ref) {
  final databases = ref.watch(appwriteDatabaseProvider);
  final functions = ref.watch(appwriteFunctionsProvider);
  return UserManagementRepository(
    databases: databases,
    functions: functions,
  );
});

/// User Management Provider
final userManagementProvider =
    StateNotifierProvider<UserManagementNotifier, UserManagementState>((ref) {
  final repository = ref.watch(userManagementRepositoryProvider);
  return UserManagementNotifier(repository, ref);
});

/// User Management Notifier
class UserManagementNotifier extends StateNotifier<UserManagementState> {
  final UserManagementRepository _repository;
  final Ref _ref;

  UserManagementNotifier(this._repository, this._ref) : super(UserManagementState());

  /// Load all business owners
  Future<void> loadBusinessOwners() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final users = await _repository.getAllBusinessOwners();
      
      // Sort by contract end date (ascending - soonest to expire first)
      users.sort((a, b) {
        final aDate = a.contractEndDate;
        final bDate = b.contractEndDate;
        
        // Null dates go to the end
        if (aDate == null && bDate == null) return 0;
        if (aDate == null) return 1;
        if (bDate == null) return -1;
        
        // Sort ascending (earliest date first)
        return aDate.compareTo(bDate);
      });
      
      state = state.copyWith(
        users: users,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Update user
  Future<bool> updateUser({
    required String documentId,
    required String fullName,
    String? phone,
  }) async {
    try {
      await _repository.updateUser(
        documentId: documentId,
        fullName: fullName,
        phone: phone,
      );
      
      // Reload users
      await loadBusinessOwners();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Delete user
  Future<bool> deleteUser({
    required String authUserId,
    required String documentId,
    bool force = false,
  }) async {
    try {
      // Get current admin ID
      final adminId = _ref.read(appwriteAccountProvider).get();
      // Note: We can't await here easily without making method async and getting user model
      // For now, let's assume the current user is the admin.
      // Better approach: Pass adminId from UI or get it from AuthState
      
      // Workaround: Get current user ID from AuthProvider
      final currentUser = _ref.read(authProvider).user;
      if (currentUser == null) throw Exception('Admin not logged in');

      await _repository.deleteUser(
        authUserId: authUserId,
        documentId: documentId,
        force: force,
        adminId: currentUser.id!,
      );
      
      // Reload users
      await loadBusinessOwners();
      return true;
    } catch (e) {
      // Don't swallow HAS_ACTIVE_TENANTS exception, rethrow it for UI handling
      if (e.toString().contains('HAS_ACTIVE_TENANTS')) {
        rethrow;
      }
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Reset user password
  Future<bool> resetPassword({
    required String authUserId,
    required String newPassword,
  }) async {
    try {
      await _repository.resetUserPassword(
        authUserId: authUserId,
        newPassword: newPassword,
      );
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Toggle user status
  Future<bool> toggleUserStatus({
    required String authUserId,
    required bool enable,
  }) async {
    try {
      await _repository.toggleUserStatus(
        authUserId: authUserId,
        enable: enable,
      );
      
      // Reload users
      await loadBusinessOwners();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Update contract end date (Token system)
  Future<bool> updateContractEndDate({
    required String documentId,
    required DateTime contractEndDate,
  }) async {
    try {
      await _repository.updateContractEndDate(
        documentId: documentId,
        contractEndDate: contractEndDate,
      );
      
      // Reload users
      await loadBusinessOwners();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }
}
