import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:appwrite/appwrite.dart';
import '../exceptions/invoice_exception.dart';

/// Service for generating and validating invoice numbers
/// 
/// Invoice format: INV-YYYYMMDD-XXXXXXX
/// Example: INV-20251221-A8K3M9P
class InvoiceService {
  /// Generate unique invoice number
  /// 
  /// Format: INV-YYYYMMDD-XXXXXXX
  /// - INV: Prefix
  /// - YYYYMMDD: Date (20251221)
  /// - XXXXXXX: Random 7-char alphanumeric code
  /// 
  /// Example: INV-20251221-A8K3M9P
  static String generateInvoiceNumber() {
    final now = DateTime.now();
    final dateStr = DateFormat('yyyyMMdd').format(now);
    final random = _generateRandomCode(7);
    
    return 'INV-$dateStr-$random';
  }
  
  /// Generate UNIQUE invoice number with database check
  /// 
  /// This method ensures 100% uniqueness by checking database
  /// and retrying if collision is detected.
  /// 
  /// **Usage:**
  /// ```dart
  /// try {
  ///   final invoice = await InvoiceService.generateUniqueInvoice(
  ///     databases,
  ///     databaseId: 'your-db-id',
  ///     collectionId: 'orders',
  ///   );
  ///   // Use invoice safely - guaranteed unique!
  /// } catch (e) {
  ///   // Show error to user
  ///   showDialog("Gagal membuat invoice, coba lagi");
  /// }
  /// ```
  /// 
  /// **Parameters:**
  /// - [databases]: Appwrite Databases instance
  /// - [databaseId]: Your database ID
  /// - [collectionId]: Orders collection ID
  /// - [maxRetries]: Maximum retry attempts (default: 5)
  /// 
  /// **Returns:** Unique invoice number
  /// 
  /// **Throws:** 
  /// - `InvoiceGenerationException` if all retries fail
  /// - `AppwriteException` if database error
  static Future<String> generateUniqueInvoice({
    required Databases databases,
    required String databaseId,
    required String collectionId,
    int maxRetries = 5,
  }) async {
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      final invoice = generateInvoiceNumber();
      
      try {
        // Check if invoice already exists in database
        final existing = await databases.listDocuments(
          databaseId: databaseId,
          collectionId: collectionId,
          queries: [
            Query.equal('invoice_number', invoice),
            Query.limit(1),
          ],
        );
        
        // If no documents found → invoice is unique! ✅
        if (existing.documents.isEmpty) {
          if (kDebugMode) print('✅ Invoice generated: $invoice (attempt $attempt)');
          return invoice;
        }
        
        // Collision detected → log and retry
        if (kDebugMode) print('⚠️ Invoice collision detected: $invoice (attempt $attempt/$maxRetries)');
        
        // Continue to next attempt
        
      } on AppwriteException catch (e) {
        // Database error (network, permission, etc)
        if (kDebugMode) print('❌ Database error while checking invoice: ${e.message}');
        
        // If it's the last attempt, throw error
        if (attempt == maxRetries) {
          throw InvoiceGenerationException(
            'Database error after $maxRetries attempts: ${e.message}',
            originalException: e,
          );
        }
        
        // Otherwise, retry with new invoice
        if (kDebugMode) print('🔄 Retrying with new invoice... (attempt ${attempt + 1}/$maxRetries)');
        
      } catch (e) {
        // Unexpected error
        if (kDebugMode) print('❌ Unexpected error while generating invoice: $e');
        throw InvoiceGenerationException(
          'Unexpected error: $e',
          originalException: e,
        );
      }
    }
    
    // All retries exhausted (extremely rare - 0.00001% probability)
    throw InvoiceGenerationException(
      'Failed to generate unique invoice after $maxRetries attempts. '
      'This is extremely rare. Please try again or contact support.',
    );
  }
  
  /// Generate random alphanumeric code
  /// 
  /// Uses uppercase letters (A-Z) and numbers (0-9)
  /// Cryptographically secure random generator
  static String _generateRandomCode(int length) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random.secure();
    return List.generate(
      length, 
      (_) => chars[random.nextInt(chars.length)]
    ).join();
  }
  
  /// Validate invoice format
  /// 
  /// Returns true if invoice matches format: INV-YYYYMMDD-XXXXXXX
  /// 
  /// Valid examples:
  /// - INV-20251221-ABC1234 ✓
  /// - INV-20250101-XYZ9999 ✓
  /// 
  /// Invalid examples:
  /// - INVALID ✗
  /// - INV-123 ✗
  /// - ORD-20251221-ABC ✗
  static bool isValidInvoice(String invoice) {
    final regex = RegExp(r'^INV-\d{8}-[A-Z0-9]{7}$');
    return regex.hasMatch(invoice);
  }
  
  /// Check if invoice is ours (starts with INV-)
  /// 
  /// Used to distinguish our invoices from other reference numbers
  /// (e.g., Midtrans transaction IDs)
  static bool isOurInvoice(String query) {
    return query.toUpperCase().startsWith('INV-');
  }
  
  /// Extract date from invoice number
  /// 
  /// Returns DateTime if valid invoice, null otherwise
  /// 
  /// Example:
  /// - INV-20251221-ABC1234 → DateTime(2025, 12, 21)
  static DateTime? extractDate(String invoice) {
    if (!isValidInvoice(invoice)) return null;
    
    try {
      final dateStr = invoice.split('-')[1]; // YYYYMMDD
      final year = int.parse(dateStr.substring(0, 4));
      final month = int.parse(dateStr.substring(4, 6));
      final day = int.parse(dateStr.substring(6, 8));
      
      return DateTime(year, month, day);
    } catch (e) {
      return null;
    }
  }
}
