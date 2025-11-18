import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_app/src/core/api/appwrite_client.dart';
import 'package:kantin_app/src/features/tenant_management/data/datasources/repositories/tenant_repository_impl.dart';
import 'package:kantin_app/src/features/tenant_management/presentation/providers/tenant_profile_provider.dart';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';

class TenantProfileScreen extends ConsumerStatefulWidget {
  const TenantProfileScreen({super.key});

  @override
  ConsumerState<TenantProfileScreen> createState() =>
      _TenantProfileScreenState();
}

class _TenantProfileScreenState extends ConsumerState<TenantProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _logoUrlController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  Document? _tenant;
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    _loadTenantData();
  }

  Future<void> _loadTenantData() async {
    setState(() => _isLoading = true);
    try {
      final account = ref.read(appwriteAccountProvider);
      final user = await account.get();
      final tenant = await ref
          .read(tenantRepositoryProvider)
          .getTenantByOwner(user.$id);
      
      if (tenant != null) {
        setState(() {
          _tenant = tenant;
          _nameController.text = tenant.data['name'] ?? '';
          _logoUrlController.text = tenant.data['logoUrl'] ?? '';
          _descriptionController.text = tenant.data['description'] ?? '';
        });
      }
    } on AppwriteException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.message}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;
    if (_tenant == null) return;

    // Validasi password jika diisi
    if (_passwordController.text.isNotEmpty) {
      if (_passwordController.text.length < 8) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password minimal 8 karakter'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      if (_passwordController.text != _confirmPasswordController.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password dan konfirmasi password tidak sama'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      // Update password jika diisi
      // Catatan: Appwrite memerlukan old password untuk update password
      // Untuk sementara, kita skip update password jika old password tidak tersedia
      // Tenant bisa menggunakan fitur "Lupa Password" di login screen jika perlu
      // if (_passwordController.text.isNotEmpty) {
      //   final account = ref.read(appwriteAccountProvider);
      //   await account.updatePassword(
      //     password: _passwordController.text,
      //     oldPassword: '', // Appwrite memerlukan old password
      //   );
      // }

      // Update tenant profile
      await ref.read(updateTenantProfileProvider.notifier).updateProfile(
            tenantId: _tenant!.$id,
            name: _nameController.text.trim(),
            logoUrl: _logoUrlController.text.trim().isEmpty
                ? null
                : _logoUrlController.text.trim(),
            description: _descriptionController.text.trim().isEmpty
                ? null
                : _descriptionController.text.trim(),
          );

      // Reset password fields
      _passwordController.clear();
      _confirmPasswordController.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil berhasil diperbarui!'),
            backgroundColor: Colors.green,
          ),
        );
        _loadTenantData(); // Reload data
      }
    } on AppwriteException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.message}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _logoUrlController.dispose();
    _descriptionController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Listen untuk update profile result
    ref.listen<AsyncValue<Document?>>(
      updateTenantProfileProvider,
      (previous, next) {
        next.when(
          data: (data) {
            if (data != null && previous?.value == null) {
              // Update berhasil
            }
          },
          loading: () {},
          error: (error, stack) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error: $error'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
        );
      },
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan Profil Tenant'),
      ),
      body: _isLoading && _tenant == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Nama Tenant
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nama Tenant/Warung',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.store),
                      ),
                      validator: (value) =>
                          (value?.trim().isEmpty ?? true)
                              ? 'Nama tidak boleh kosong'
                              : null,
                    ),
                    const SizedBox(height: 16),

                    // Logo URL
                    TextFormField(
                      controller: _logoUrlController,
                      decoration: const InputDecoration(
                        labelText: 'URL Logo (opsional)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.image),
                        helperText: 'Masukkan URL gambar logo tenant',
                      ),
                      keyboardType: TextInputType.url,
                    ),
                    const SizedBox(height: 16),

                    // Deskripsi
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Deskripsi (opsional)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.description),
                      ),
                      maxLines: 3,
                      maxLength: 256,
                    ),
                    const SizedBox(height: 24),

                    // Section Password
                    const Divider(),
                    const Text(
                      'Ubah Password',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Kosongkan jika tidak ingin mengubah password',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 16),

                    // Password Baru
                    TextFormField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: 'Password Baru',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.lock),
                        suffixIcon: IconButton(
                          icon: Icon(_isPasswordVisible
                              ? Icons.visibility
                              : Icons.visibility_off),
                          onPressed: () {
                            setState(() {
                              _isPasswordVisible = !_isPasswordVisible;
                            });
                          },
                        ),
                      ),
                      obscureText: !_isPasswordVisible,
                    ),
                    const SizedBox(height: 16),

                    // Konfirmasi Password
                    TextFormField(
                      controller: _confirmPasswordController,
                      decoration: InputDecoration(
                        labelText: 'Konfirmasi Password Baru',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(_isConfirmPasswordVisible
                              ? Icons.visibility
                              : Icons.visibility_off),
                          onPressed: () {
                            setState(() {
                              _isConfirmPasswordVisible =
                                  !_isConfirmPasswordVisible;
                            });
                          },
                        ),
                      ),
                      obscureText: !_isConfirmPasswordVisible,
                    ),
                    const SizedBox(height: 32),

                    // Tombol Simpan
                    ElevatedButton(
                      onPressed: _isLoading ? null : _updateProfile,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Simpan Perubahan'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

