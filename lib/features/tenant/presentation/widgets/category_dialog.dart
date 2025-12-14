import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/models/category_model.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../providers/category_provider.dart';

/// Dialog for creating or editing a category
class CategoryDialog extends ConsumerStatefulWidget {
  final CategoryModel? category;

  const CategoryDialog({super.key, this.category});

  @override
  ConsumerState<CategoryDialog> createState() => _CategoryDialogState();
}

class _CategoryDialogState extends ConsumerState<CategoryDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _iconController = TextEditingController();
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    
    if (widget.category != null) {
      // Edit mode - populate fields
      _nameController.text = widget.category!.name;
      _descriptionController.text = widget.category!.description ?? '';
      _iconController.text = widget.category!.icon ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _iconController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.category == null ? 'Tambah Kategori' : 'Edit Kategori'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Name
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nama Kategori *',
                hintText: 'Contoh: Makanan Berat',
                prefixIcon: Icon(Icons.category),
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Nama kategori harus diisi';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            // Icon (emoji)
            TextFormField(
              controller: _iconController,
              decoration: const InputDecoration(
                labelText: 'Icon/Emoji (Opsional)',
                hintText: '🍜 🍔 🍕 ☕',
                prefixIcon: Icon(Icons.emoji_emotions),
                border: OutlineInputBorder(),
                helperText: 'Gunakan emoji untuk icon kategori',
              ),
              maxLength: 2,
            ),
            const SizedBox(height: 16),
            
            // Description
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Deskripsi (Opsional)',
                hintText: 'Deskripsi kategori',
                prefixIcon: Icon(Icons.description),
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: _isLoading ? null : _saveCategory,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(widget.category == null ? 'Tambah' : 'Simpan'),
        ),
      ],
    );
  }

  Future<void> _saveCategory() async {
    if (!_formKey.currentState!.validate()) return;

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

    final notifier = ref.read(tenantCategoriesProvider(user!.tenantId!).notifier);
    
    final name = _nameController.text.trim();
    final description = _descriptionController.text.trim();
    final icon = _iconController.text.trim();

    bool success;
    if (widget.category == null) {
      // Create new category
      success = await notifier.createCategory(
        name: name,
        description: description.isEmpty ? null : description,
        icon: icon.isEmpty ? null : icon,
      );
    } else {
      // Update existing category
      success = await notifier.updateCategory(
        categoryId: widget.category!.id,
        name: name,
        description: description.isEmpty ? null : description,
        icon: icon.isEmpty ? null : icon,
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
              widget.category == null
                  ? 'Kategori berhasil ditambahkan'
                  : 'Kategori berhasil diupdate',
            ),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal menyimpan kategori'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
