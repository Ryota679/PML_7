import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_app/core/utils/logger.dart';
import 'package:kantin_app/features/auth/data/auth_repository.dart';
import 'package:kantin_app/shared/models/user_model.dart';

/// Contact Info for Deactivated Users
class DeactivatedUserInfo {
  final String ownerName;
  final String ownerEmail;
  final String ownerPhone;
  final String userRole; // 'staff' or 'tenant_user'

  DeactivatedUserInfo({
    required this.ownerName,
    required this.ownerEmail,
    required this.ownerPhone,
    required this.userRole,
  });
}

/// Auth State
/// 
/// State untuk authentication
class AuthState {
  final bool isLoading;
  final bool isAuthenticated;
  final UserModel? user;
  final String? error;
  final bool isDeactivatedUser; // Flag for deactivated users

  AuthState({
    this.isLoading = false,
    this.isAuthenticated = false,
    this.user,
    this.error,
    this.isDeactivatedUser = false,
  });

  AuthState copyWith({
    bool? isLoading,
    bool? isAuthenticated,
    UserModel? user,
    String? error,
    bool? isDeactivatedUser,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      user: user ?? this.user,
      error: error ?? this.error,
      isDeactivatedUser: isDeactivatedUser ?? this.isDeactivatedUser,
    );
  }

  // Helper getters
  bool get isCustomer => user?.role == 'customer';
  bool get isTenant => user?.role == 'tenant';
  bool get isBusinessOwner => user?.role == 'owner_bussines';
  bool get isAdmin => user?.role == 'adminsystem';
  bool get isGuest => !isAuthenticated;
}

/// Auth Provider
/// 
/// Provider untuk mengelola authentication state
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository authRepository;

  AuthNotifier(this.authRepository) : super(AuthState()) {
    // Check session saat inisialisasi
    _checkSession();
  }

  /// Check session saat app start
  Future<void> _checkSession() async {
    state = state.copyWith(isLoading: true);
    
    try {
      final session = await authRepository.getCurrentSession();
      
      if (session != null) {
        final currentUser = await authRepository.getCurrentUser();
        
        if (currentUser != null) {
          final userProfile = await authRepository.getUserProfile(currentUser.$id);
          
          if (userProfile != null) {
            state = state.copyWith(
              isLoading: false,
              isAuthenticated: true,
              user: userProfile,
            );
            return;
          }
        }
      }
      
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: false,
      );
    } catch (e) {
      AppLogger.error('Session check failed', e);
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: false,
      );
    }
  }

  /// Login
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    AppLogger.info('🚀 === AUTH PROVIDER LOGIN FLOW START ===');

    try {
      // Step 1: Login ke Appwrite
      AppLogger.info('📍 STEP 1: Calling authRepository.login()...');
      await authRepository.login(email: email, password: password);
      AppLogger.info('✅ STEP 1: Repository login successful');
      
      // Step 2: Get user account
      AppLogger.info('📍 STEP 2: Getting current user account...');
      final currentUser = await authRepository.getCurrentUser();
      
      if (currentUser == null) {
        AppLogger.error('❌ STEP 2 FAILED: getCurrentUser returned null');
        throw Exception('Failed to get user data');
      }
      AppLogger.info('✅ STEP 2: Retrieved user account');
      AppLogger.info('   └─ Auth User ID: ${currentUser.$id}');
      AppLogger.info('   └─ Email: ${currentUser.email}');
      AppLogger.info('   └─ Name: ${currentUser.name}');
      
      // Step 3: Get user profile dari database
      AppLogger.info('📍 STEP 3: Fetching user profile from database...');
      AppLogger.info('   └─ Querying users collection with: user_id = ${currentUser.$id}');
      final userProfile = await authRepository.getUserProfile(currentUser.$id);
      
      if (userProfile == null) {
        AppLogger.error('❌ STEP 3 FAILED: User profile not found in database');
        AppLogger.error('   └─ Auth User ID exists but no matching document in users collection');
        AppLogger.error('   └─ Expected document with user_id = ${currentUser.$id}');
        throw Exception('User profile not found');
      }
      AppLogger.info('✅ STEP 3: User profile retrieved');
      AppLogger.info('   └─ Document ID: ${userProfile.id}');
      AppLogger.info('   └─ Role: ${userProfile.role}');
      AppLogger.info('   └─ Username: ${userProfile.username}');
      
      // Step 3.5: Check if user is deactivated BEFORE setting isAuthenticated
      // This prevents router from auto-navigating
      AppLogger.info('📍 STEP 3.5: Checking user active status...');
      
      // SKIP check for Business Owners and Customers
      if (userProfile.role != 'owner_business' && 
          userProfile.role != 'owner_bussines' && 
          userProfile.role != 'customer') {
        
        // Only check tenant users and staff
        if (userProfile.role == 'tenant' && !userProfile.isActive) {
          AppLogger.warning('⚠️ User is deactivated: ${userProfile.username}');
          
          // CRITICAL: Logout to destroy Appwrite session
          // Session was created before this check, so we must delete it
          AppLogger.info('🔒 Destroying Appwrite session for deactivated user...');
          try {
            await authRepository.logout();
            AppLogger.info('✅ Session destroyed successfully');
          } catch (e) {
            AppLogger.error('Failed to destroy session', e);
          }
          
          // Set deactivated flag WITHOUT setting isAuthenticated
          state = state.copyWith(
            isLoading: false,
            isAuthenticated: false, // Keep false!
            user: userProfile,
            isDeactivatedUser: true, // Flag for UI to show dialog
          );
          
          AppLogger.info('🚫 Login blocked - user is deactivated');
          return false; // Login fails for deactivated users
        }
      }
      
      AppLogger.info('✅ STEP 3.5: User is active, proceeding with login');
      
      // Step 4: Update state
      AppLogger.info('📍 STEP 4: Updating auth state...');
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: true,
        user: userProfile,
      );
      AppLogger.info('✅ STEP 4: State updated successfully');
      AppLogger.info('🎉 === AUTH PROVIDER LOGIN FLOW COMPLETE ===');
      
      return true;
    } catch (e) {
      AppLogger.error('💥 === AUTH PROVIDER LOGIN FLOW FAILED ===', e);
      
      String errorMessage = 'Login gagal';
      if (e.toString().contains('Invalid credentials')) {
        errorMessage = 'Email atau password salah';
        AppLogger.error('🔒 Error Type: Invalid Credentials');
      } else if (e.toString().contains('User not found')) {
        errorMessage = 'Akun tidak ditemukan';
        AppLogger.error('🔍 Error Type: User Not Found');
      } else if (e.toString().contains('User profile not found')) {
        errorMessage = 'Profil pengguna tidak ditemukan';
        AppLogger.error('📋 Error Type: User Profile Missing');
      }
      
      AppLogger.error('📱 User Message: $errorMessage');
      
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: false,
        error: errorMessage,
      );
      
      return false;
    }
  }

  /// Register Customer
  /// Register new customer account
  Future<bool> registerCustomer({
    required String name,
    required String email,
    required String password,
    required String phone,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Register customer via repository
      final user = await authRepository.registerCustomer(
        name: name,
        email: email,
        password: password,
        phone: phone,
      );

      if (user == null) {
        throw Exception('Registration failed');
      }

      // Auto-login after registration
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: true,
        user: user,
      );

      return true;
    } catch (e) {
      AppLogger.error('Customer registration failed', e);
      
      String errorMessage = 'Registrasi gagal';
      if (e.toString().contains('email already exists')) {
        errorMessage = 'Email sudah terdaftar';
      }

      state = state.copyWith(
        isLoading: false,
        isAuthenticated: false,
        error: errorMessage,
      );

      throw Exception(errorMessage);
    }
  }

  /// Logout
  Future<void> logout() async {
    try {
      await authRepository.logout();
      state = AuthState(); // Reset to initial state
    } catch (e) {
      AppLogger.error('Logout failed', e);
    }
  }

  /// Clear Deactivated User Flag
  /// 
  /// Resets the isDeactivatedUser flag after dialog is dismissed
  /// Allows normal navigation flow to resume
  void clearDeactivatedFlag() {
    if (state.isDeactivatedUser) {
      state = state.copyWith(
        isDeactivatedUser: false,
        user: null, // Clear user data
      );
      AppLogger.info('Cleared deactivated user flag');
    }
  }

  /// Request password reset
  Future<bool> requestPasswordReset(String email) async {
    try {
      await authRepository.requestPasswordReset(email);
      return true;
    } catch (e) {
      AppLogger.error('Password reset request failed', e);
      return false;
    }
  }

  /// Refresh User Profile
  /// 
  /// Reload user data from database without re-authentication
  /// Useful after updating user fields (e.g., tenant selection, subscription)
  Future<void> refreshUserProfile() async {
    try {
      final currentUser = await authRepository.getCurrentUser();
      
      if (currentUser != null) {
        final userProfile = await authRepository.getUserProfile(currentUser.$id);
        
        if (userProfile != null) {
          state = state.copyWith(user: userProfile);
          AppLogger.info('User profile refreshed');
        }
      }
    } catch (e) {
      AppLogger.error('Failed to refresh user profile', e);
    }
  }

  /// Check User Active Status
  /// 
  /// Returns DeactivatedUserInfo if user is inactive, null otherwise
  /// **IMPORTANT**: Queries database for REAL-TIME status
  Future<DeactivatedUserInfo?> checkUserActiveStatus() async {
    final user = state.user;
    if (user == null) {
      AppLogger.info('   ❌ No user in state');
      return null;
    }

    AppLogger.info('   🔍 Checking user: ${user.email} (${user.userId})');

    // SKIP Business Owners
    if (user.role == 'owner_bussines' || user.role == 'owner_business') {
      AppLogger.info('   ⏭️  Skipping - Business Owner');
      return null;
    }

    // SKIP Customers
    if (user.role == 'customer') {
      AppLogger.info('   ⏭️  Skipping - Customer');
      return null;
    }

    // Only check tenant users and staff
    if (user.role != 'tenant') {
      AppLogger.info('   ⏭️  Skipping - Role: ${user.role}');
      return null;
    }

    try {
      // REAL-TIME CHECK: Query database
      AppLogger.info('   📡 Fetching from database...');
      final freshUser = await authRepository.getUserProfile(user.userId);
      
      // Handle null (user not found)
      if (freshUser == null) {
        AppLogger.warning('   ⚠️  User not found in database');
        return null;
      }
      
      AppLogger.info('   📊 Database result:');
      AppLogger.info('      - is_active: ${freshUser.isActive}');

      // Check using FRESH data
      if (!freshUser.isActive) {
        AppLogger.warning('⚠️ [DB] User DEACTIVATED: ${freshUser.username}');
        
        // Set flag
        state = state.copyWith(isDeactivatedUser: true);
        AppLogger.warning('   🚩 Set deactivated flag');
        
        final userRole = (freshUser.subRole == 'staff') ? 'staff' : 'tenant_user';
        
        // Simplified: Return without fetching BO (can be enhanced later)
        return DeactivatedUserInfo(
          ownerName: 'Business Owner',
          ownerEmail: 'owner@example.com',
          ownerPhone: '628123456789',
          userRole: userRole,
        );
      }

      AppLogger.info('   ✅ [DB] User ACTIVE');
      return null;
    } catch (e) {
      AppLogger.error('❌ Error checking status: $e');
      return null;
    }
  }

  /// Delete Account
  Future<void> deleteAccount({bool force = false}) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final userId = state.user?.id;
      if (userId == null) {
        throw Exception('User not found');
      }

      await authRepository.deleteAccount(userId, force: force);
      
      // Logout after successful deletion
      await logout();
      
    } catch (e) {
      AppLogger.error('Delete account failed', e);
      
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
      
      rethrow; // Rethrow to handle specific errors in UI
    }
  }
}

/// Auth State Provider
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return AuthNotifier(authRepository);
});
