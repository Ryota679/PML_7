import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:appwrite/appwrite.dart';
import '../exceptions/invoice_exception.dart';
import 'invoice_service.dart';

/// EXAMPLE: How to use InvoiceService.generateUniqueInvoice()
/// 
/// This shows proper error handling for invoice generation
class OrderCheckoutExample extends ConsumerWidget {
  const OrderCheckoutExample({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ElevatedButton(
      onPressed: () => _handleCheckout(context, ref),
      child: const Text('Checkout'),
    );
  }

  Future<void> _handleCheckout(BuildContext context, WidgetRef ref) async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // Get Appwrite databases instance
      final databases = ref.read(appwriteDatabasesProvider);
      
      // Generate unique invoice with retry mechanism
      final invoice = await InvoiceService.generateUniqueInvoice(
        databases: databases,
        databaseId: 'your-database-id',
        collectionId: 'orders',
        maxRetries: 5, // Try up to 5 times
      );
      
      // Invoice generated successfully! ✅
      if (kDebugMode) print('Invoice: $invoice');
      
      // Create order with this invoice
      await _createOrder(databases, invoice);
      
      // Close loading
      Navigator.pop(context);
      
      // Show success
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Order berhasil! Invoice: $invoice'),
          backgroundColor: Colors.green,
        ),
      );
      
    } on InvoiceGenerationException catch (e) {
      // Invoice generation failed (extremely rare)
      if (kDebugMode) print('Invoice generation failed: ${e.message}');
      
      // Close loading
      Navigator.pop(context);
      
      // Show user-friendly error
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Gagal Membuat Pesanan'),
          content: Text(e.userMessage), // User-friendly message
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _handleCheckout(context, ref); // Retry
              },
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      );
      
    } on AppwriteException catch (e) {
      // Appwrite error (network, permission, etc)
      if (kDebugMode) print('Appwrite error: ${e.message}');
      
      // Close loading
      Navigator.pop(context);
      
      // Show error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.message}'),
          backgroundColor: Colors.red,
        ),
      );
      
    } catch (e) {
      // Unexpected error
      if (kDebugMode) print('Unexpected error: $e');
      
      // Close loading
      Navigator.pop(context);
      
      // Show generic error
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Terjadi kesalahan. Silakan coba lagi.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  Future<void> _createOrder(Databases databases, String invoice) async {
    // Create order in database
    await databases.createDocument(
      databaseId: 'your-database-id',
      collectionId: 'orders',
      documentId: ID.unique(),
      data: {
        'invoice_number': invoice,
        'order_status': 'pending',
        // ... other order data
      },
    );
  }
}

// Mock provider for example
final appwriteDatabasesProvider = Provider<Databases>((ref) {
  throw UnimplementedError('Replace with actual provider');
});
