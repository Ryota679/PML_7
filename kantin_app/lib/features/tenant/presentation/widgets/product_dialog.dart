import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/config/appwrite_config.dart';
import '../../../../core/services/image_upload_service.dart';
import '../../../../core/utils/logger.dart';
import '../../../../shared/models/category_model.dart';
import '../../../../shared/models/product_model.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../providers/product_provider.dart';

/// Dialog for creating or editing a product
class ProductDialog extends ConsumerStatefulWidget {
  final ProductModel? product;
  final List<CategoryModel> categories;

  const ProductDialog({
    super.key,
    this.product,
    required this.categories,
  });

  @override
  ConsumerState<ProductDialog> createState() => _ProductDialogState();
}

class _ProductDialogState extends ConsumerState<ProductDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _stockController = TextEditingController();
  
  CategoryModel? _selectedCategory;
  bool _isAvailable = true;
  bool _hasStockTracking = false;
  bool _isLoading = false;
  bool _isUploadingImage = false;
  String? _uploadedImageUrl;

  @override
  void initState() {
    super.initState();
    
    if (widget.product != null) {
      // Edit mode - populate fields
      _nameController.text = widget.product!.name;
      _descriptionController.text = widget.product!.description ?? '';
      _priceController.text = widget.product!.price.toString();
      _imageUrlController.text = widget.product!.imageUrl ?? '';
      _isAvailable = widget.product!.isAvailable;
      _hasStockTracking = widget.product!.hasStockTracking;
      if (widget.product!.stock != null) {
        _stockController.text = widget.product!.stock.toString();
      }
      
      // Find and set selected category
      _selectedCategory = widget.categories.firstWhere(
        (cat) => cat.id == widget.product!.categoryId,
        orElse: () => widget.categories.first,
      );
    } else {
      // Create mode - set default category
      _selectedCategory = widget.categories.isNotEmpty ? widget.categories.first : null;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _imageUrlController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.product == null ? 'Tambah Produk' : 'Edit Produk'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500, minWidth: 300),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Category dropdown
                DropdownButtonFormField<CategoryModel>(
                  value: _selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Kategori *',
                    prefixIcon: Icon(Icons.category),
                    border: OutlineInputBorder(),
                  ),
                  isExpanded: true,
                  items: widget.categories.map((category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Row(
                        children: [
                          if (category.icon != null) ...[
                            Text(category.icon!),
                            const SizedBox(width: 8),
                          ],
                          Expanded(
                            child: Text(
                              category.name,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCategory = value;
                    });
                  },
                  validator: (value) {
                    if (value == null) return 'Pilih kategori';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Name
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nama Produk *',
                    hintText: 'Contoh: Nasi Goreng Special',
                    prefixIcon: Icon(Icons.restaurant),
                    border: OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.words,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Nama produk harus diisi';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Description
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Deskripsi (Opsional)',
                    hintText: 'Deskripsi produk',
                    prefixIcon: Icon(Icons.description),
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 16),
                
                // Price
                TextFormField(
                  controller: _priceController,
                  decoration: const InputDecoration(
                    labelText: 'Harga (Rp) *',
                    hintText: '15000',
                    prefixIcon: Icon(Icons.attach_money),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Harga harus diisi';
                    }
                    final price = int.tryParse(value);
                    if (price == null || price <= 0) {
                      return 'Harga harus lebih dari 0';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Image Upload Section
                const Text(
                  'Gambar Produk',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                
                // Upload Image Button
                OutlinedButton.icon(
                  onPressed: _isUploadingImage ? null : _handleImageUpload,
                  icon: _isUploadingImage
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.upload_file),
                  label: Text(
                    _uploadedImageUrl != null || _imageUrlController.text.isNotEmpty
                        ? 'Ganti Gambar'
                        : 'Pilih Gambar dari Device',
                  ),
                ),
                
                // Show uploaded image preview
                if (_uploadedImageUrl != null || _imageUrlController.text.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    height: 120,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        _uploadedImageUrl ?? _imageUrlController.text,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.broken_image, color: Colors.grey),
                                SizedBox(height: 4),
                                Text(
                                  'Gagal memuat gambar',
                                  style: TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _uploadedImageUrl ?? _imageUrlController.text,
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),
                
                // Manual URL input (fallback)
                TextFormField(
                  controller: _imageUrlController,
                  decoration: const InputDecoration(
                    labelText: 'Atau Paste URL Gambar',
                    hintText: 'https://example.com/image.jpg',
                    prefixIcon: Icon(Icons.link),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.url,
                  onChanged: (value) {
                    setState(() {
                      if (value.isNotEmpty) {
                        _uploadedImageUrl = null; // Clear uploaded image if manual URL entered
                      }
                    });
                  },
                ),
                const SizedBox(height: 16),
                
                // Stock tracking toggle
                CheckboxListTile(
                  title: const Text('Lacak Stok'),
                  subtitle: const Text('Aktifkan untuk tracking jumlah stok'),
                  value: _hasStockTracking,
                  onChanged: (value) {
                    setState(() {
                      _hasStockTracking = value ?? false;
                      if (!_hasStockTracking) {
                        _stockController.clear();
                      }
                    });
                  },
                ),
                
                // Stock quantity (if tracking enabled)
                if (_hasStockTracking) ...[
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _stockController,
                    decoration: const InputDecoration(
                      labelText: 'Jumlah Stok',
                      hintText: '100',
                      prefixIcon: Icon(Icons.inventory_2),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (value) {
                      if (_hasStockTracking) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Jumlah stok harus diisi';
                        }
                        final stock = int.tryParse(value);
                        if (stock == null || stock < 0) {
                          return 'Stok tidak valid';
                        }
                      }
                      return null;
                    },
                  ),
                ],
                const SizedBox(height: 16),
                
                // Availability toggle
                SwitchListTile(
                  title: const Text('Status Ketersediaan'),
                  subtitle: Text(_isAvailable ? 'Tersedia' : 'Tidak Tersedia'),
                  value: _isAvailable,
                  onChanged: (value) {
                    setState(() {
                      _isAvailable = value;
                    });
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: _isLoading ? null : _saveProduct,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(widget.product == null ? 'Tambah' : 'Simpan'),
        ),
      ],
    );
  }

  Future<void> _handleImageUpload() async {
    setState(() {
      _isUploadingImage = true;
    });

    try {
      final imageUploadService = ref.read(imageUploadServiceProvider);
      
      final imageUrl = await imageUploadService.pickAndUploadImage(
        bucketId: AppwriteConfig.productImagesBucketId,
        maxSizeKB: 500, // Max 500KB after compression
      );

      if (imageUrl != null) {
        setState(() {
          _uploadedImageUrl = imageUrl;
          _imageUrlController.clear(); // Clear manual URL input
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Gambar berhasil diupload!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e, stackTrace) {
      AppLogger.error('Error uploading image', e, stackTrace);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Gagal upload gambar: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingImage = false;
        });
      }
    }
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) return;

    setState(() {
      _isLoading = true;
    });

    final user = ref.read(authProvider).user;
    if (user?.tenantId == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    final notifier = ref.read(tenantProductsProvider(user!.tenantId!).notifier);
    
    final name = _nameController.text.trim();
    final description = _descriptionController.text.trim();
    final price = int.parse(_priceController.text.trim());
    // Use uploaded image URL if available, otherwise use manual URL
    final imageUrl = _uploadedImageUrl ?? _imageUrlController.text.trim();
    final stock = _hasStockTracking && _stockController.text.trim().isNotEmpty
        ? int.parse(_stockController.text.trim())
        : null;

    bool success;
    if (widget.product == null) {
      // Create new product
      success = await notifier.createProduct(
        categoryId: _selectedCategory!.id,
        name: name,
        description: description.isEmpty ? null : description,
        price: price,
        imageUrl: imageUrl.isEmpty ? null : imageUrl,
        isAvailable: _isAvailable,
        stock: stock,
      );
    } else {
      // Update existing product
      success = await notifier.updateProduct(
        productId: widget.product!.id,
        categoryId: _selectedCategory!.id,
        name: name,
        description: description.isEmpty ? null : description,
        price: price,
        imageUrl: imageUrl.isEmpty ? null : imageUrl,
        isAvailable: _isAvailable,
        stock: stock,
      );
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });

      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.product == null
                  ? 'Produk berhasil ditambahkan'
                  : 'Produk berhasil diupdate',
            ),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal menyimpan produk'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
