import 'package:appwrite/appwrite.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_app/core/config/appwrite_config.dart';
import 'package:kantin_app/core/providers/appwrite_provider.dart';
import 'package:kantin_app/features/auth/providers/auth_provider.dart';
import 'package:kantin_app/shared/models/user_model.dart';

/// Provider untuk manage staff members
final staffProvider = StateNotifierProvider<StaffNotifier, AsyncValue<List<UserModel>>>((ref) {
  final authNotifier = ref.watch(authProvider.notifier);
  final databases = ref.watch(appwriteDatabasesProvider);
  final functions = ref.watch(appwriteFunctionsProvider);
  final currentUser = ref.watch(authProvider).user;
  
  return StaffNotifier(
    databases: databases,
    functions: functions,
    currentUser: currentUser,
    authNotifier: authNotifier,
  );
});

class StaffNotifier extends StateNotifier<AsyncValue<List<UserModel>>> {
  final Databases databases;
  final Functions functions;
  final UserModel? currentUser;
  final AuthNotifier authNotifier;

  StaffNotifier({
    required this.databases,
    required this.functions,
    required this.currentUser,
    required this.authNotifier,
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
    // 🔒 FORCE CHECK: Verify user still active before critical operation
if (kDebugMode) print('🔒 [FORCE CHECK] Verifying active status before DELETE staff...');
    final deactivatedInfo = await authNotifier.checkUserActiveStatus();
    if (deactivatedInfo != null) {
  if (kDebugMode) print('⚠️ [FORCE CHECK] User deactivated! Blocking delete operation.');
  if (kDebugMode) print('🚪 [FORCE CHECK] Auto-logout triggered...');
      await authNotifier.logout();
      return false;
    }
if (kDebugMode) print('✅ [FORCE CHECK] User active, proceeding with delete...');
    
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

  /// Toggle staff active status
  Future<bool> toggleStaffStatus(String staffId, bool isActive) async {
    // 🔒 FORCE CHECK: Verify user still active before critical operation
if (kDebugMode) print('🔒 [FORCE CHECK] Verifying active status before TOGGLE staff...');
    final deactivatedInfo = await authNotifier.checkUserActiveStatus();
    if (deactivatedInfo != null) {
  if (kDebugMode) print('⚠️ [FORCE CHECK] User deactivated! Blocking toggle operation.');
  if (kDebugMode) print('🚪 [FORCE CHECK] Auto-logout triggered...');
      await authNotifier.logout();
      return false;
    }
if (kDebugMode) print('✅ [FORCE CHECK] User active, proceeding with toggle...');
    
if (kDebugMode) print('🔄 [STAFF TOGGLE] Starting...');
if (kDebugMode) print('📋 Staff ID: $staffId');
if (kDebugMode) print('🎯 Target Status: ${isActive ? "AKTIF" : "NONAKTIF"}');
if (kDebugMode) print('🗄️ Database: ${AppwriteConfig.databaseId}');
if (kDebugMode) print('📚 Collection: ${AppwriteConfig.usersCollectionId}');
    
    try {
  if (kDebugMode) print('⏳ [STAFF TOGGLE] Calling Appwrite updateDocument...');
      
      await databases.updateDocument(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.usersCollectionId,
        documentId: staffId,
        data: {'is_active': isActive},
      );

  if (kDebugMode) print('✅ [STAFF TOGGLE] Appwrite update SUCCESS!');

      // Update local state optimistically
      state.whenData((staffList) {
        final updatedList = staffList.map((s) {
          if (s.id == staffId) {
            return s.copyWith(isActive: isActive);
          }
          return s;
        }).toList();
        state = AsyncValue.data(updatedList);
      });

  if (kDebugMode) print('✅ [STAFF TOGGLE] Local state updated!');
      return true;
    } catch (e) {
  if (kDebugMode) print('❌ [STAFF TOGGLE] ERROR: $e');
  if (kDebugMode) print('📝 Error Type: ${e.runtimeType}');
      if (e.toString().contains('unauthorized')) {
    if (kDebugMode) print('🚫 Permission denied! Check Appwrite permissions for label:tenant');
      } else if (e.toString().contains('not_found')) {
    if (kDebugMode) print('🔍 Staff ID not found in database!');
      }
      return false;
    }
  }
}
