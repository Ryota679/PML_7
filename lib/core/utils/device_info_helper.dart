import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

/// Device Info Helper
/// 
/// Utility untuk detect platform dan get device information
class DeviceInfoHelper {
  /// Get platform string: "web", "android", "ios"
  static String getPlatform() {
    if (kIsWeb) return 'web';
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    return 'unknown';
  }
  
  /// Get friendly device name for display
  /// Future implementation: integrate device_info_plus package
  static Future<String> getDeviceInfo() async {
    final platform = getPlatform();
    
    switch (platform) {
      case 'web':
        // TODO: Get browser info (Chrome, Firefox, Safari, Edge)
        return 'Web Browser';
      case 'android':
        // TODO: Get Android version & device model
        return 'Android Device';
      case 'ios':
        // TODO: Get iOS version & device model  
        return 'iOS Device';
      default:
        return 'Unknown Device';
    }
  }
  
  /// Get icon for platform
  static IconData getPlatformIcon(String platform) {
    switch (platform) {
      case 'web':
        return Icons.language;
      case 'android':
        return Icons.android;
      case 'ios':
        return Icons.phone_iphone;
      default:
        return Icons.devices;
    }
  }
  
  /// Get friendly platform name for display
  static String getPlatformDisplayName(String platform) {
    switch (platform) {
      case 'web':
        return 'Web';
      case 'android':
        return 'Android';
      case 'ios':
        return 'iOS';
      default:
        return 'Unknown';
    }
  }
  
  /// Format timestamp untuk display (relative time)
  static String formatLoginTime(DateTime? loginTime) {
    if (loginTime == null) return 'Unknown';
    
    final now = DateTime.now();
    final difference = now.difference(loginTime);
    
    if (difference.inSeconds < 60) {
      return 'Baru saja';
    } else if (difference.inMinutes < 60) {
      final minutes = difference.inMinutes;
      return '$minutes menit yang lalu';
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      return '$hours jam yang lalu';
    } else {
      final days = difference.inDays;
      return '$days hari yang lalu';
    }
  }
}
