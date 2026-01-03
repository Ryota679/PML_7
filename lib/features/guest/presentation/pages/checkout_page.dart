import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kantin_app/features/guest/providers/cart_provider.dart';
import 'package:kantin_app/features/guest/providers/order_provider.dart';

/// Checkout Page
/// Customer information form and order confirmation
class CheckoutPage extends ConsumerStatefulWidget {
  final String tenantId;

  const CheckoutPage({
    super.key,
    required this.tenantId,
  });

  @override
  ConsumerState<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends ConsumerState<CheckoutPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _tableNumberController = TextEditingController();
  final _notesController = TextEditingController();
  
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _tableNumberController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cartItems = ref.watch(cartItemsListProvider);
    final totalAmount = ref.watch(cartFormattedTotalProvider);
    final itemCount = ref.watch(cartTotalItemsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Customer Information Section
                  _buildSectionHeader('Informasi Pelanggan', Icons.person_outline),
                  const SizedBox(height: 12),
                  _buildCustomerForm(),
                  
                  const SizedBox(height: 24),
                  
                  // Order Summary Section
                  _buildSectionHeader('Ringkasan Pesanan', Icons.receipt_long_outlined),
                  const SizedBox(height: 12),
                  _buildOrderSummary(cartItems, itemCount),
                  
                  const SizedBox(height: 16),
                ],
              ),
            ),
            
            // Bottom Total & Submit
            _buildBottomBar(totalAmount),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildCustomerForm() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Name Field
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nama *',
                hintText: 'Masukkan nama Anda',
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Nama wajib diisi';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            // Phone Field
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'No. Telepon *',
                hintText: '08xxxxxxxxxx',
                prefixIcon: Icon(Icons.phone),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(13),
              ],
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'No. telepon wajib diisi';
                }
                if (value.length < 10) {
                  return 'No. telepon minimal 10 digit';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            // Table Number Field (Optional)
            TextFormField(
              controller: _tableNumberController,
              decoration: const InputDecoration(
                labelText: 'No. Meja / Lokasi (Opsional)',
                hintText: 'Contoh: Meja 5',
                prefixIcon: Icon(Icons.table_restaurant),
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
            ),
            
            const SizedBox(height: 16),
            
            // Notes Field (Optional)
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Catatan (Opsional)',
                hintText: 'Catatan khusus untuk pesanan',
                prefixIcon: Icon(Icons.note),
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              maxLength: 200,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderSummary(List cartItems, int itemCount) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Item',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                Text(
                  '$itemCount item',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
            const Divider(height: 24),
            
            // Cart Items List
            ...cartItems.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${item.quantity}x',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.product.name),
                        if (item.notes != null && item.notes!.isNotEmpty)
                          Text(
                            item.notes!,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Text(
                    item.formattedSubtotal,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar(String totalAmount) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Total
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total Pembayaran',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  totalAmount,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton.icon(
                onPressed: _isSubmitting ? null : _handleSubmitOrder,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.check_circle),
                label: Text(_isSubmitting ? 'Memproses...' : 'Pesan Sekarang'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSubmitOrder() async {
    // Validate form
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Get cart items
    final cartItems = ref.read(cartItemsListProvider);
    if (cartItems.isEmpty) {
      _showErrorSnackBar('Keranjang kosong');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Create order via repository
      final repository = ref.read(orderRepositoryProvider);
      final order = await repository.createOrder(
        tenantId: widget.tenantId,
        customerName: _nameController.text.trim(),
        customerPhone: _phoneController.text.trim(),
        cartItems: cartItems,
        tableNumber: _tableNumberController.text.trim().isEmpty
            ? null
            : _tableNumberController.text.trim(),
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );

      // Save order to state
      ref.read(currentOrderProvider.notifier).state = order;

      // Clear cart
      ref.read(cartProvider.notifier).clearCart();

      // Navigate to order tracking page
      if (mounted) {
        context.go('/order/${order.orderNumber}');
        
        _showSuccessSnackBar('Pesanan berhasil dibuat!');
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Gagal membuat pesanan: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
