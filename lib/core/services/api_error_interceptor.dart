import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:appwrite/appwrite.dart';
import 'package:kantin_app/core/utils/logger.dart';

/// API Error Interceptor
/// 
/// Global error handler untuk detect session expiry (401/403)
/// dan trigger auto-logout untuk single device login
class ApiErrorInterceptor {
  /// Callback untuk handle session expired
  static Function()? _onSessionExpired;
  
  /// Register callback untuk session expired
  static void registerSessionExpiredCallback(Function() callback) {
    _onSessionExpired = callback;
    if (kDebugMode) {
      print('🔒 [API INTERCEPTOR] Session expired callback registered');
    }
  }
  
  /// Check if error is session expired (401/403)
  static bool isSessionExpiredError(dynamic error) {
    if (error is AppwriteException) {
      // Check for 401 Unauthorized or 403 Forbidden
      final isUnauthorized = error.code == 401 || error.code == 403;
      
      // Check for specific error types
      final isSessionError = error.type?.contains('unauthorized') ?? false;
      final isUserUnauthorized = error.type == 'user_unauthorized';
      final isGeneralUnauthorized = error.type == 'general_unauthorized_scope';
      
      final isExpired = isUnauthorized || isSessionError || isUserUnauthorized || isGeneralUnauthorized;
      
      if (kDebugMode && isExpired) {
        print('🚨 [API INTERCEPTOR] Session expired error detected!');
        print('   ├─ Code: ${error.code}');
        print('   ├─ Type: ${error.type}');
        print('   ├─ Message: ${error.message}');
        print('   └─ Is Session Expired: $isExpired');
      }
      
      return isExpired;
    }
    
    return false;
  }
  
  /// Handle API error - automatically detect and handle session expiry
  static Future<void> handleError(dynamic error, {String? context}) async {
    if (kDebugMode) {
      print('🔍 [API INTERCEPTOR] Checking error...');
      if (context != null) {
        print('   └─ Context: $context');
      }
    }
    
    if (isSessionExpiredError(error)) {
      AppLogger.error('Session expired detected - triggering auto-logout', error);
      
      if (kDebugMode) {
        print('⚠️  [API INTERCEPTOR] SESSION EXPIRED!');
        print('   └─ Triggering auto-logout callback...');
      }
      
      // Trigger callback to logout user
      if (_onSessionExpired != null) {
        _onSessionExpired!();
        
        if (kDebugMode) {
          print('✅ [API INTERCEPTOR] Auto-logout callback executed');
        }
      } else {
        if (kDebugMode) {
          print('❌ [API INTERCEPTOR] No callback registered!');
        }
        AppLogger.error('Session expired but no callback registered');
      }
    }
  }
  
  /// Wrap async function with error interceptor
  /// 
  /// Usage:
  /// ```dart
  /// final result = await ApiErrorInterceptor.wrapApiCall(
  ///   apiCall: () => database.createDocument(...),
  ///   context: 'Create Category',
  /// );
  /// ```
  static Future<T> wrapApiCall<T>({
    required Future<T> Function() apiCall,
    String? context,
  }) async {
    try {
      if (kDebugMode && context != null) {
        print('📡 [API CALL] $context');
      }
      
      final result = await apiCall();
      
      if (kDebugMode && context != null) {
        print('✅ [API CALL] $context - Success');
      }
      
      return result;
    } catch (e) {
      if (kDebugMode && context != null) {
        print('❌ [API CALL] $context - Failed');
      }
      
      // Check if this is a session expired error
      await handleError(e, context: context);
      
      // Rethrow untuk handling di caller
      rethrow;
    }
  }
}

