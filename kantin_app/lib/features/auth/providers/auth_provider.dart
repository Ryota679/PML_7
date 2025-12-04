import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_app/core/utils/logger.dart';
import 'package:kantin_app/features/auth/data/auth_repository.dart';
import 'package:kantin_app/shared/models/user_model.dart';

/// Auth State
/// 
/// State untuk authentication
class AuthState {
  final bool isLoading;
  final bool isAuthenticated;
  final UserModel? user;
  final String? error;

  AuthState({
    this.isLoading = false,
    this.isAuthenticated = false,
    this.user,
    this.error,
  });

  AuthState copyWith({
    bool? isLoading,
    bool? isAuthenticated,
    UserModel? user,
    String? error,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      user: user ?? this.user,
      error: error ?? this.error,
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

    try {
      // Login ke Appwrite
      await authRepository.login(email: email, password: password);
      
      // Get user account
      final currentUser = await authRepository.getCurrentUser();
      
      if (currentUser == null) {
        throw Exception('Failed to get user data');
      }
      
      // Get user profile dari database
      final userProfile = await authRepository.getUserProfile(currentUser.$id);
      
      if (userProfile == null) {
        throw Exception('User profile not found');
      }
      
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: true,
        user: userProfile,
      );
      
      return true;
    } catch (e) {
      AppLogger.error('Login failed', e);
      
      String errorMessage = 'Login gagal';
      if (e.toString().contains('Invalid credentials')) {
        errorMessage = 'Email atau password salah';
      } else if (e.toString().contains('User not found')) {
        errorMessage = 'Akun tidak ditemukan';
      }
      
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
