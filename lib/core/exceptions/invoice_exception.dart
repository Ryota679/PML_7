/// Exception thrown when invoice generation fails
/// 
/// This occurs when:
/// 1. All retry attempts exhausted (extremely rare)
/// 2. Database connection error
/// 3. Permission error
class InvoiceGenerationException implements Exception {
  final String message;
  final Object? originalException;
  
  InvoiceGenerationException(
    this.message, {
    this.originalException,
  });
  
  @override
  String toString() {
    if (originalException != null) {
      return 'InvoiceGenerationException: $message\nCaused by: $originalException';
    }
    return 'InvoiceGenerationException: $message';
  }
  
  /// User-friendly error message (Indonesian)
  String get userMessage {
    if (message.contains('Database error')) {
      return 'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.';
    } else if (message.contains('Permission')) {
      return 'Terjadi kesalahan sistem. Silakan hubungi admin.';
    } else {
      return 'Gagal membuat nomor invoice. Silakan coba lagi.';
    }
  }
}
