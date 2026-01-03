import 'dart:math';

/// Utility for generating and validating invitation codes
/// 
/// Invitation codes format:
/// - Tenant: TN-123456
/// - Staff:  ST-789012
class InvitationCodeGenerator {
  /// Generate invitation code based on type
  /// 
  /// Returns a code in format: XX-XXXXXX (e.g., TN-123456)
  static String generate(InvitationType type) {
    final prefix = type == InvitationType.tenant ? 'TN' : 'ST';
    final random = Random().nextInt(900000) + 100000; // 6 digits (100000-999999)
    return '$prefix-$random';
  }
  
  /// Validate code format
  /// 
  /// Returns true if code matches pattern: (TN|ST)-XXXXXX
  static bool isValidFormat(String code) {
    final regex = RegExp(r'^(TN|ST)-\d{6}$');
    return regex.hasMatch(code.toUpperCase());
  }
  
  /// Get invitation type from code prefix
  /// 
  /// Returns:
  /// - InvitationType.tenant if code starts with TN-
  /// - InvitationType.staff if code starts with ST-
  /// - null if invalid prefix
  static InvitationType? getType(String code) {
    final upperCode = code.toUpperCase();
    if (upperCode.startsWith('TN-')) return InvitationType.tenant;
    if (upperCode.startsWith('ST-')) return InvitationType.staff;
    return null;
  }
}

/// Invitation type enum
enum InvitationType {
  tenant,
  staff,
}
