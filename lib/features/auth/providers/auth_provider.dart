import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:go_router/go_router.dart';
import 'package:kantin_app/core/utils/logger.dart';
import 'package:kantin_app/features/auth/data/auth_repository.dart';
import 'package:kantin_app/shared/models/user_model.dart';
import 'package:kantin_app/core/utils/device_info_helper.dart';
import 'package:kantin_app/core/services/api_error_interceptor.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

/// OAuth Registration Data
class PendingOAuthRegistration {
  final String email;
  final String userId;
  final String? intendedRole; // Pre-selected role (owner/tenant/staff)

  PendingOAuthRegistration({
    required this.email,
    required this.userId,
    this.intendedRole,
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
  final PendingOAuthRegistration? pendingOAuthRegistration; // OAuth user needs to choose role
  final bool showDeviceSwitchDialog; // Flag for device switch notification
  final String? previousLoginDevice; // Previous device platform
  final DateTime? previousLoginAt; // Previous login timestamp
  final bool sessionExpired; // Flag for session expired

  AuthState({
    this.isLoading = false,
    this.isAuthenticated = false,
    this.user,
    this.error,
    this.isDeactivatedUser = false,
    this.pendingOAuthRegistration,
    this.showDeviceSwitchDialog = false,
    this.previousLoginDevice,
    this.previousLoginAt,
    this.sessionExpired = false,
  });

  AuthState copyWith({
    bool? isLoading,
    bool? isAuthenticated,
    UserModel? user,
    String? error,
    bool? isDeactivatedUser,
    PendingOAuthRegistration? pendingOAuthRegistration,
    bool clearUser = false, // Flag to explicitly clear user
    bool clearPendingOAuth = false, // Flag to explicitly clear pendingOAuth
    bool? showDeviceSwitchDialog,
    String? previousLoginDevice,
    DateTime? previousLoginAt,
    bool? sessionExpired,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      user: clearUser ? null : (user ?? this.user),
      error: error ?? this.error,
      isDeactivatedUser: isDeactivatedUser ?? this.isDeactivatedUser,
      pendingOAuthRegistration: clearPendingOAuth ? null : (pendingOAuthRegistration ?? this.pendingOAuthRegistration),
      showDeviceSwitchDialog: showDeviceSwitchDialog ?? this.showDeviceSwitchDialog,
      previousLoginDevice: previousLoginDevice ?? this.previousLoginDevice,
      previousLoginAt: previousLoginAt ?? this.previousLoginAt,
      sessionExpired: sessionExpired ?? this.sessionExpired,
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
    
    // Register session expired callback for API error interceptor
    _registerSessionExpiredHandler();
  }
  
  /// Register handler untuk session expired dari API errors
  void _registerSessionExpiredHandler() {
    ApiErrorInterceptor.registerSessionExpiredCallback(() {
      if (kDebugMode) {
        print('🚨 [AUTH] Session expired callback triggered!');
        print('   └─ Force logging out user...');
      }
      
      // Force logout without calling API (session already expired)
      _forceLogoutLocal();
    });
  }
  
  /// Force logout (local only - no API call)
  /// Used when session already expired on server
  void _forceLogoutLocal() {
    if (kDebugMode) {
      print('🔒 [AUTH] Force logout (local)');
      print('   └─ Setting session expired flag...');
    }
    
    // Set session expired flag first (before clearing state)
    state = state.copyWith(
      sessionExpired: true,
      isAuthenticated: false,
      user: null,
    );
    
    AppLogger.info('User force logged out (session expired)');
    
    if (kDebugMode) {
      print('✅ [AUTH] Session expired flag set');
      print('✅ [AUTH] Local state cleared');
    }
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
      
      // Step 3.7: Session Tracking for Single Device Login
      if (kDebugMode) {
        print('═══════════════════════════════════════════════════════');
        print('🔐 [SINGLE DEVICE LOGIN] Step 3.7: Session Tracking');
        print('═══════════════════════════════════════════════════════');
      }
      
      try {
        // Get current session info
        final session = await authRepository.getCurrentSession();
        
        if (session == null) {
          if (kDebugMode) print('❌ [SESSION] No active session found!');
          throw Exception('No session found after login');
        }
        
        if (kDebugMode) {
          print('✅ [SESSION] Session retrieved successfully');
          print('   ├─ Session ID: ${session.$id}');
          print('   ├─ User ID: ${session.userId}');
          print('   ├─ Provider: ${session.provider}');
          print('   └─ Expires: ${session.expire}');
        }
        
        // Detect device platform
        final devicePlatform = _getDevicePlatform();
        final deviceInfo = await _getDeviceInfo();
        
        if (kDebugMode) {
          print('📱 [DEVICE] Device detection:');
          print('   ├─ Platform: $devicePlatform');
          print('   └─ Info: $deviceInfo');
        }
        
        // Get previous session for comparison
        final previousSessionId = userProfile.lastSessionId;
        final previousDevice = userProfile.lastLoginDevice;
        final previousLoginAt = userProfile.lastLoginAt;
        
        if (kDebugMode) {
          print('📊 [PREVIOUS] Previous session data:');
          print('   ├─ Previous Session ID: ${previousSessionId ?? "null (first login)"}');
          print('   ├─ Previous Device: ${previousDevice ?? "null"}');
          print('   └─ Previous Login: ${previousLoginAt ?? "null"}');
        }
        
        // Update session tracking in database
        if (userProfile.id != null) {
          if (kDebugMode) {
            print('💾 [DATABASE] Updating session tracking...');
            print('   ├─ Document ID: ${userProfile.id}');
            print('   ├─ New Session ID: ${session.$id}');
            print('   ├─ New Device: $devicePlatform');
            print('   └─ Timestamp: ${DateTime.now()}');
          }
          
          await authRepository.updateSessionInfo(
            documentId: userProfile.id!,
            sessionId: session.$id,
            devicePlatform: devicePlatform,
            deviceInfo: deviceInfo,
          );
          
          if (kDebugMode) print('✅ [DATABASE] Session tracking updated successfully');
          
          // Check if device switched
          if (previousDevice != null && previousDevice != devicePlatform) {
            if (kDebugMode) {
              print('🔄 [DEVICE SWITCH] Device change detected!');
              print('   ├─ From: $previousDevice');
              print('   ├─ To: $devicePlatform');
              print('   └─ Action: Setting dialog flag');
            }
            
            // Set flag and store previous device info for dialog
            state = state.copyWith(
              showDeviceSwitchDialog: true,
              previousLoginDevice: previousDevice,
              previousLoginAt: previousLoginAt,
            );
            
            if (kDebugMode) print('✅ [DIALOG] Device switch dialog flag set');
          } else if (previousDevice == null) {
            if (kDebugMode) print('ℹ️  [FIRST LOGIN] This is the first login for this user');
          } else {
            if (kDebugMode) print('ℹ️  [SAME DEVICE] User logged in from same device: $devicePlatform');
          }
          
          // CRITICAL: Check Appwrite session limit
          if (kDebugMode) {
            print('⚠️  [SESSION LIMIT] IMPORTANT CHECK:');
            print('   └─ Appwrite should have AUTOMATICALLY deleted old session');
            print('   └─ If both devices still active, session limit NOT working!');
            print('   └─ Verify: Appwrite Console → Settings → Auth → Sessions limit = 1');
          }
        } else {
          if (kDebugMode) print('❌ [ERROR] User profile has no document ID!');
        }
      } catch (e, stackTrace) {
        // Session tracking error should not block login
        if (kDebugMode) {
          print('❌ [ERROR] Session tracking failed (non-critical):');
          print('   ├─ Error: $e');
          print('   └─ Stack: ${stackTrace.toString().split('\n').take(3).join('\n')}');
        }
        AppLogger.error('Session tracking failed (non-critical)', e);
      }
      
      if (kDebugMode) {
        print('═══════════════════════════════════════════════════════');
        print('🔐 [SINGLE DEVICE LOGIN] Step 3.7: Complete');
        print('═══════════════════════════════════════════════════════');
      }
      
      // Step 4: Update state
      AppLogger.info('📍 STEP 4: Updating auth state...');
      
      // Preserve showDeviceSwitchDialog flag if set
      final finalState = state.showDeviceSwitchDialog
          ? state.copyWith(
              isLoading: false,
              isAuthenticated: true,
              user: userProfile,
            )
          : state.copyWith(
              isLoading: false,
              isAuthenticated: true,
              user: userProfile,
            );
      
      state = finalState;
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

  /// Handle Google Sign-In (OAuth)
  /// 
  /// Orchestrates Google OAuth flow with state detection
  /// Optional intendedRole parameter for pre-selected role (e.g., from registration)
  Future<void> handleGoogleSignIn(BuildContext context, {String? intendedRole}) async {
    state = state.copyWith(isLoading: true, error: null);
    AppLogger.info('🔐 === GOOGLE OAUTH FLOW START ===');

    // Store intended role before OAuth redirect (will be retrieved after)
    if (intendedRole != null) {
      AppLogger.info('💾 Storing intended role: $intendedRole');
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('oauth_intended_role', intendedRole);
    }

    try {
      // Step 1: Create OAuth2 session
      AppLogger.info('📍 STEP 1: Creating OAuth2 session...');
      await authRepository.createOAuth2Session(provider: 'google');
      AppLogger.info('✅ STEP 1: OAuth2 session created');

      // CRITICAL: Wait for Appwrite to sync account
      // Without this delay, getCurrentUser returns null
      AppLogger.info('⏳ Waiting for Appwrite to sync account...');
      await Future.delayed(const Duration(milliseconds: 300));

      // Step 2: Get authenticated user
      AppLogger.info('📍 STEP 2: Getting current user...');
      final googleUser = await authRepository.getCurrentUser();
      
      if (googleUser == null) {
        AppLogger.error('❌ STEP 2 FAILED: getCurrentUser returned null');
        throw Exception('Failed to get user data');

      }
      AppLogger.info('✅ STEP 2: Retrieved user account');
      AppLogger.info('   └─ Auth User ID: ${googleUser.$id}');
      AppLogger.info('   └─ Email: ${googleUser.email}');

      // Step 3: Check if user exists in database
      AppLogger.info('📍 STEP 3: Checking if user exists in database...');
      try {
        final userDoc = await authRepository.getUserProfile(googleUser.$id);
        
        if (userDoc != null) {
          AppLogger.info('✅ STEP 3: User document found');
          // User exists - handle based on state
          await _handleExistingUser(userDoc, context);
        } else {
          // Should not reach here (getUserProfile returns null)
          AppLogger.warning('⚠️ STEP 3: User profile is null');
          await _showRegistrationRequiredDialog(googleUser, context);
        }
      } catch (e) {
        // Document not found (404)
        AppLogger.info('⚠️ STEP 3: User NOT found in database (404)');
        AppLogger.info('   └─ New Google OAuth user, needs registration');
        
        // Show registration dialog
        await _showRegistrationRequiredDialog(googleUser, context);
      }
      
    } catch (e) {
      AppLogger.error('💥 === GOOGLE OAUTH FLOW FAILED ===', e);
      
      String errorMessage = 'Google login gagal';
      if (e.toString().contains('cancelled') || e.toString().contains('canceled')) {
        errorMessage = 'Login dibatalkan';
        AppLogger.info('🔙 User cancelled OAuth');
      }
      
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: false,
        error: errorMessage,
      );
    }
  }

  /// Handle Existing User (OAuth)
  /// 
  /// Detect user state and navigate accordingly
  Future<void> _handleExistingUser(UserModel userDoc, BuildContext context) async {
    AppLogger.info('🔍 Detecting user state...');
    AppLogger.info('   └─ Role: ${userDoc.role}');
    AppLogger.info('   └─ Tenant ID: ${userDoc.tenantId ?? "NULL"}');
    AppLogger.info('   └─ Active: ${userDoc.isActive}');

    // Owner - always complete
    if (userDoc.role == 'owner_business' || userDoc.role == 'owner_bussines') {
      AppLogger.info('✅ Owner user - Complete registration');
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: true,
        user: userDoc,
      );
      // Navigate to owner dashboard
      if (context.mounted) {
        context.go('/owner-dashboard');
      }
      return;
    }

    // Tenant/Staff - check tenant_id
    if (userDoc.role == 'tenant') {
      if (userDoc.tenantId == null || userDoc.tenantId!.isEmpty) {
        // Incomplete registration - need code entry
        AppLogger.warning('⚠️ Tenant/Staff user - Incomplete registration (tenant_id NULL)');
        AppLogger.info('   └─ Navigating to code entry page');
        
        // Set partial state (authenticated but not fully setup)
        state = state.copyWith(
          isLoading: false,
          isAuthenticated: true,
          user: userDoc,
        );
        
        // Navigate to code entry
        if (context.mounted) {
          if (userDoc.subRole == 'staff') {
            context.go('/enter-staff-code');
          } else {
            context.go('/enter-tenant-code');
          }
        }
      } else {
        // Complete registration
        AppLogger.info('✅ Tenant/Staff user - Complete registration');
        state = state.copyWith(
          isLoading: false,
          isAuthenticated: true,
          user: userDoc,
        );
        
        // Navigate to dashboard
        if (context.mounted) {
          if (userDoc.subRole == 'staff') {
            context.go('/tenant'); // Staff also go to tenant dashboard
          } else {
            context.go('/tenant'); // Tenant dashboard
          }
        }
      }
    }
  }

  /// Show Registration Required Dialog
  /// 
  /// For new Google OAuth users who need to choose role
  /// 
  /// Instead of manual navigation, set state flag
  /// Router will automatically redirect based on pendingOAuthRegistration state
  Future<void> _showRegistrationRequiredDialog(
    dynamic googleUser,
    BuildContext context,
  ) async {
    AppLogger.info('📢 OAuth user needs registration: ${googleUser.email}');
    
    // Retrieve intended role from storage (if set before OAuth)
    final prefs = await SharedPreferences.getInstance();
    final intendedRole = prefs.getString('oauth_intended_role');
    
    if (intendedRole != null) {
      AppLogger.info('📝 Retrieved intended role from storage: $intendedRole');
      // Clear the stored value
      await prefs.remove('oauth_intended_role');
    }
    
    // Set pending registration state
    // Router redirect logic will handle navigation automatically
    state = state.copyWith(
      isLoading: false,
      pendingOAuthRegistration: PendingOAuthRegistration(
        email: googleUser.email,
        userId: googleUser.$id,
        intendedRole: intendedRole, // Pass the intended role
      ),
    );
    
    AppLogger.info('✅ Pending OAuth registration state set - router will redirect');
  }

  /// Clear Pending OAuth Registration
  /// 
  /// Called after user selects role or cancels
  void clearPendingOAuthRegistration() {
    state = state.copyWith(clearPendingOAuth: true);
    AppLogger.info('🧹 Pending OAuth registration cleared');
  }

  /// Register as Business Owner
  /// 
  /// Creates user profile with 'owner' role
  Future<void> registerAsOwner(String email, String userId) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      AppLogger.info('📝 Registering as Business Owner: $email');
      
      // Create user profile in database
      final userProfile = await authRepository.createUserProfile(
        userId: userId,
        email: email,
        role: 'owner_bussines', // Fixed: use correct enum value
        subRole: null, // Owner has no sub_role
      );
      
      // Update Auth labels for easier categorization
      await authRepository.updateAccountLabels(
        userId: userId,
        role: 'owner_bussines',  // Match database value
      );
      
      AppLogger.info('✅ Owner registration successful');
      
      // Update auth state
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: true,
        user: userProfile,
        pendingOAuthRegistration: null, // Clear pending
      );
      
    } catch (e, stackTrace) {
      AppLogger.error('❌ Owner registration failed', e, stackTrace);
      state = state.copyWith(
        isLoading: false,
        error: 'Registration failed: ${e.toString()}',
      );
      rethrow;
    }
  }

  /// Register as Tenant
  /// 
  /// Creates user profile with 'tenant' role
  Future<void> registerAsTenant(String email, String userId) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      AppLogger.info('📝 Registering as Tenant: $email');
      
      // Create user profile in database
      final userProfile = await authRepository.createUserProfile(
        userId: userId,
        email: email,
        role: 'tenant',
        subRole: 'owner', // Tenant owner (not staff)
      );
      
      // Update Auth labels for easier categorization
      await authRepository.updateAccountLabels(
        userId: userId,
        role: 'tenant',
      );
      
      AppLogger.info('✅ Tenant registration successful');
      
      // Update auth state
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: true,
        user: userProfile,
        pendingOAuthRegistration: null, // Clear pending
      );
      
    } catch (e, stackTrace) {
      AppLogger.error('❌ Tenant registration failed', e, stackTrace);
      state = state.copyWith(
        isLoading: false,
        error: 'Registration failed: ${e.toString()}',
      );
      rethrow;
    }
  }

  /// Register as Staff
  /// 
  /// Creates user profile with 'staff' role
  Future<void> registerAsStaff(String email, String userId) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      AppLogger.info('📝 Registering as Staff: $email');
      
      // Create user profile in database
      // Note: Staff uses 'tenant' role with sub_role='staff'
      final userProfile = await authRepository.createUserProfile(
        userId: userId,
        email: email,
        role: 'tenant', // Staff uses tenant role
        subRole: 'staff', // Differentiate from tenant owner
      );
      
      // Update Auth labels for easier categorization
      await authRepository.updateAccountLabels(
        userId: userId,
        role: 'staff',
      );
      
      AppLogger.info('✅ Staff registration successful');
      
      // Update auth state
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: true,
        user: userProfile,
        pendingOAuthRegistration: null, // Clear pending
      );
      
    } catch (e, stackTrace) {
      AppLogger.error('❌ Staff registration failed', e, stackTrace);
      state = state.copyWith(
        isLoading: false,
        error: 'Registration failed: ${e.toString()}',
      );
      rethrow;
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
  
  /// Clear Device Switch Dialog Flag
  /// 
  /// Resets the showDeviceSwitchDialog flag after dialog is dismissed
  void clearDeviceSwitchFlag() {
    if (state.showDeviceSwitchDialog) {
      state = state.copyWith(
        showDeviceSwitchDialog: false,
        previousLoginDevice: null,
        previousLoginAt: null,
      );
      AppLogger.info('Cleared device switch dialog flag');
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
          state = state.copyWith(
            user: userProfile,
            clearPendingOAuth: true, // Clear OAuth pending state using flag
          );
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
  
  /// Get Device Platform
  /// Helper method to detect current device platform
  String _getDevicePlatform() {
    return DeviceInfoHelper.getPlatform();
  }
  
  /// Get Device Info
  /// Helper method to get detailed device information
  Future<String?> _getDeviceInfo() async {
    try {
      return await DeviceInfoHelper.getDeviceInfo();
    } catch (e) {
      AppLogger.error('Failed to get device info', e);
      return null;
    }
  }
}

/// Auth State Provider
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return AuthNotifier(authRepository);
});
