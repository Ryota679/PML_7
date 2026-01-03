import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_app/features/admin/data/registration_repository.dart';
import 'package:kantin_app/features/auth/providers/auth_provider.dart';
import 'package:kantin_app/shared/models/registration_request_model.dart';
import 'package:kantin_app/shared/providers/appwrite_provider.dart';

/// Registration Repository Provider
final registrationRepositoryProvider = Provider<RegistrationRepository>((ref) {
  final databases = ref.watch(appwriteDatabaseProvider);
  final account = ref.watch(appwriteAccountProvider);
  final functions = ref.watch(appwriteFunctionsProvider);
  
  return RegistrationRepository(
    databases: databases,
    account: account,
    functions: functions,
  );
});

/// Registration Requests State
class RegistrationRequestsState {
  final List<RegistrationRequestModel> requests;
  final bool isLoading;
  final String? error;

  RegistrationRequestsState({
    this.requests = const [],
    this.isLoading = false,
    this.error,
  });

  RegistrationRequestsState copyWith({
    List<RegistrationRequestModel>? requests,
    bool? isLoading,
    String? error,
  }) {
    return RegistrationRequestsState(
      requests: requests ?? this.requests,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Registration Requests Provider
class RegistrationRequestsNotifier extends StateNotifier<RegistrationRequestsState> {
  final RegistrationRepository _repository;
  final String? _currentUserId;

  RegistrationRequestsNotifier(this._repository, this._currentUserId)
      : super(RegistrationRequestsState());

  /// Load pending requests
  Future<void> loadPendingRequests() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final requests = await _repository.getPendingRequests();
      state = state.copyWith(
        requests: requests,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Load all requests
  Future<void> loadAllRequests({String? status}) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final requests = await _repository.getAllRequests(status: status);
      state = state.copyWith(
        requests: requests,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Approve request
  /// User will use password they provided during registration
  /// Returns response data including user details
  Future<Map<String, dynamic>?> approveRequest(
    String requestId, {
    String? notes,
  }) async {
    if (_currentUserId == null) return null;

    try {
      final responseData = await _repository.approveRequest(
        requestId: requestId,
        adminUserId: _currentUserId,
        notes: notes,
      );
      
      // Reload requests
      await loadPendingRequests();
      return responseData;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  /// Reject request
  Future<bool> rejectRequest(String requestId, String reason) async {
    if (_currentUserId == null) return false;

    try {
      await _repository.rejectRequest(
        requestId: requestId,
        adminUserId: _currentUserId,
        reason: reason,
      );
      
      // Reload requests
      await loadPendingRequests();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Create new registration request (public)
  Future<bool> createRequest({
    required String fullName,
    required String email,
    required String password,
    required String businessName,
    required String businessType,
    String? phone,
  }) async {
    try {
      await _repository.createRequest(
        fullName: fullName,
        email: email,
        password: password,
        businessName: businessName,
        businessType: businessType,
        phone: phone,
      );
      
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }
}

/// Provider for registration requests with current user context
final registrationRequestsProvider = StateNotifierProvider<RegistrationRequestsNotifier, RegistrationRequestsState>((ref) {
  final repository = ref.watch(registrationRepositoryProvider);
  
  // Get current user ID from auth state
  final authState = ref.watch(authProvider);
  final currentUserId = authState.isAuthenticated 
      ? authState.user?.userId 
      : null;
  
  return RegistrationRequestsNotifier(repository, currentUserId);
});

/// Provider for pending requests count
final pendingRequestsCountProvider = Provider<int>((ref) {
  final state = ref.watch(registrationRequestsProvider);
  return state.requests.where((r) => r.isPending).length;
});
