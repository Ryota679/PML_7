/// Tenant Code Generator
/// Generate short, unique codes dari tenant ID
class TenantCodeGenerator {
  /// Characters untuk code (exclude confusing ones: 0, O, 1, I, L)
  static const String _chars = '23456789ABCDEFGHJKLMNPQRSTUVWXYZ';
  
  /// Generate 6-character code dari tenant ID
  /// 
  /// Example: "69268d4c6be9048dc121" → "K7N2M8"
  static String generateCode(String tenantId) {
    if (tenantId.isEmpty || tenantId.length < 12) {
      throw ArgumentError('Tenant ID must be at least 12 characters');
    }
    
    // Ambil 12 karakter pertama untuk consistency
    final substring = tenantId.substring(0, 12);
    
    try {
      // Convert hex string to integer
      final number = int.parse(substring, radix: 16);
      
      // Convert to base-32 representation (6 chars)
      String code = '';
      int remaining = number;
      
      for (int i = 0; i < 6; i++) {
        code = _chars[remaining % _chars.length] + code;
        remaining ~/= _chars.length;
      }
      
      return code;
    } catch (e) {
      // Fallback jika parsing gagal
      return _generateFallbackCode(tenantId);
    }
  }
  
  /// Fallback method jika main method gagal
  static String _generateFallbackCode(String tenantId) {
    // Use hashCode as fallback
    final hash = tenantId.hashCode.abs();
    String code = '';
    int remaining = hash;
    
    for (int i = 0; i < 6; i++) {
      code = _chars[remaining % _chars.length] + code;
      remaining ~/= _chars.length;
    }
    
    return code;
  }
  
  /// Format code dengan separator untuk display yang lebih readable
  /// Example: "K7N2M8" → "K7N-2M8"
  static String formatCode(String code, {bool useSeparator = false}) {
    if (!useSeparator || code.length != 6) {
      return code;
    }
    return '${code.substring(0, 3)}-${code.substring(3)}';
  }
  
  /// Validate code format
  static bool isValidCode(String code) {
    // Remove separator if present
    final cleanCode = code.replaceAll('-', '').toUpperCase();
    
    // Must be 6 characters
    if (cleanCode.length != 6) return false;
    
    // Must only contain valid characters
    return cleanCode.split('').every((char) => _chars.contains(char));
  }
}
