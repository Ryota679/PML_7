import 'package:flutter/foundation.dart';

/// Simple logging utility for the app
class AppLogger {
  /// Log info message
  static void info(String message, [dynamic data]) {
    if (kDebugMode) {
      print('ℹ️ INFO: $message${data != null ? '\nData: $data' : ''}');
    }
  }

  /// Log error message
  static void error(String message, [dynamic error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      print('❌ ERROR: $message');
      if (error != null) {
        print('Error: $error');
      }
      if (stackTrace != null) {
        print('StackTrace: $stackTrace');
      }
    }
  }

  /// Log warning message
  static void warning(String message, [dynamic data]) {
    if (kDebugMode) {
      print('⚠️ WARNING: $message${data != null ? '\nData: $data' : ''}');
    }
  }

  /// Log debug message
  static void debug(String message, [dynamic data]) {
    if (kDebugMode) {
      print('🐛 DEBUG: $message${data != null ? '\nData: $data' : ''}');
    }
  }

  /// Log success message
  static void success(String message, [dynamic data]) {
    if (kDebugMode) {
      print('✅ SUCCESS: $message${data != null ? '\nData: $data' : ''}');
    }
  }
}
