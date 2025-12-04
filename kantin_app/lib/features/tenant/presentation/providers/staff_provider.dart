import 'package:appwrite/appwrite.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_app/core/config/appwrite_config.dart';
import 'package:kantin_app/core/providers/appwrite_provider.dart';
import 'package:kantin_app/features/auth/providers/auth_provider.dart';
import 'package:kantin_app/shared/models/user_model.dart';

/// Provider untuk manage staff members
final staffProvider = StateNotifierProvider<StaffNotifier, AsyncValue<List<UserModel>>>((ref) {
  final databases = ref.watch(appwriteDatabasesProvider);
  final functions = ref.watch(appwriteFunctionsProvider);
  final currentUser = ref.watch(authProvider).user;
  
  return StaffNotifier(
    databases: databases,
    functions: functions,
    currentUser: currentUser,
  );
});

class StaffNotifier extends StateNotifier<AsyncValue<List<UserModel>>> {
  final Databases databases;
  final Functions functions;
  final UserModel? currentUser;

  StaffNotifier({
    required this.databases,
    required this.functions,
    required this.currentUser,
  }) : super(const AsyncValue.loading()) {
    loadStaff();
  }

  /// Load staff members for current tenant
  Future<void> loadStaff() async {
    if (currentUser == null || currentUser?.tenantId == null) {
      state = const AsyncValue.data([]);
      return;
    }

    state = const AsyncValue.loading();

    try {
      final response = await databases.listDocuments(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.usersCollectionId,
        queries: [
          Query.equal('tenant_id', currentUser!.tenantId!),
          Query.equal('sub_role', 'staff'),
        ],
      );

      final staffList = response.documents.map((doc) {
        return UserModel.fromJson(doc.data);
      }).toList();

      state = AsyncValue.data(staffList);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Refresh staff list (call after adding new staff)
  Future<void> refresh() => loadStaff();

  /// Delete staff permanently via Appwrite function
  Future<bool> deleteStaffPermanent(String userDocId, String deletedBy) async {
    try {
      // Call delete-user function
      final execution = await functions.createExecution(
        functionId: AppwriteConfig.deleteUserFunctionId,
        body: '{"userId": "$userDocId", "deletedBy": "$deletedBy", "force": false}',
      );

      // Parse response
      final responseBody = execution.responseBody;
      if (responseBody.contains('"success":true')) {
        // Remove from local state
        state.whenData((staffList) {
          final updatedList = staffList.where((s) => s.id != userDocId).toList();
          state = AsyncValue.data(updatedList);
        });
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}
