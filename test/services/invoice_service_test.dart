import 'package:flutter_test/flutter_test.dart';
import 'package:kantin_app/core/services/invoice_service.dart';

void main() {
  group('InvoiceService', () {
    test('generates valid invoice number', () {
      final invoice = InvoiceService.generateInvoiceNumber();
      
      // Should start with INV-
      expect(invoice, startsWith('INV-'));
      
      // Should be valid format
      expect(InvoiceService.isValidInvoice(invoice), true);
      
      // Should have correct length (INV-YYYYMMDD-XXXXXXX = 20 chars)
      expect(invoice.length, 20);
    });
    
    test('generates unique invoice numbers', () {
      final invoice1 = InvoiceService.generateInvoiceNumber();
      final invoice2 = InvoiceService.generateInvoiceNumber();
      
      // Should be different (random codes)
      expect(invoice1, isNot(equals(invoice2)));
    });
    
    test('validates invoice format correctly', () {
      // Valid invoices
      expect(InvoiceService.isValidInvoice('INV-20251221-ABCD123'), true);
      expect(InvoiceService.isValidInvoice('INV-20250101-XYZ9999'), true);
      expect(InvoiceService.isValidInvoice('INV-19991231-A1B2C3D'), true);
      
      // Invalid invoices
      expect(InvoiceService.isValidInvoice('INVALID'), false);
      expect(InvoiceService.isValidInvoice('INV-123'), false);
      expect(InvoiceService.isValidInvoice('ORD-20251221-ABC'), false);
      expect(InvoiceService.isValidInvoice('INV-20251221-ABC'), false); // too short
      expect(InvoiceService.isValidInvoice('INV-20251221-ABC12345'), false); // too long
      expect(InvoiceService.isValidInvoice('inv-20251221-ABCD123'), false); // lowercase prefix
    });
    
    test('distinguishes our invoice from other references', () {
      // Our invoices
      expect(InvoiceService.isOurInvoice('INV-20251221-ABC123'), true);
      expect(InvoiceService.isOurInvoice('inv-123'), true); // case insensitive
      
      // Not our invoices
      expect(InvoiceService.isOurInvoice('MT-987654321'), false);
      expect(InvoiceService.isOurInvoice('ORD-123'), false);
      expect(InvoiceService.isOurInvoice('RANDOM'), false);
    });
    
    test('extracts date from invoice number', () {
      final invoice = 'INV-20251221-ABCD123';
      final date = InvoiceService.extractDate(invoice);
      
      expect(date, isNotNull);
      expect(date!.year, 2025);
      expect(date.month, 12);
      expect(date.day, 21);
    });
    
    test('returns null for invalid invoice date extraction', () {
      expect(InvoiceService.extractDate('INVALID'), null);
      expect(InvoiceService.extractDate('INV-123'), null);
      expect(InvoiceService.extractDate('ORD-20251221-ABC'), null);
    });
    
    test('generated invoice contains current date', () {
      final invoice = InvoiceService.generateInvoiceNumber();
      final extractedDate = InvoiceService.extractDate(invoice);
      final now = DateTime.now();
      
      expect(extractedDate, isNotNull);
      expect(extractedDate!.year, now.year);
      expect(extractedDate.month, now.month);
      expect(extractedDate.day, now.day);
    });
  });
}
