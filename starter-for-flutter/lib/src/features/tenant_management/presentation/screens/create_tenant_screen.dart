

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_app/src/features/tenant_management/presentation/providers/create_tenant_provider.dart';

class CreateTenantScreen extends ConsumerStatefulWidget {
  const CreateTenantScreen({super.key});

  @override
  ConsumerState<CreateTenantScreen> createState() => _CreateTenantScreenState();
}

class _CreateTenantScreenState extends ConsumerState<CreateTenantScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      ref.read(createTenantProvider.notifier).createTenant(
            name: _nameController.text.trim(),
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. Ubah `ref.listen` agar menggunakan tipe data yang baru dan `.when()`
    ref.listen<AsyncValue<Map<String, dynamic>?>>(createTenantProvider,
        (previous, next) {
      next.when(
        data: (result) {
          // Hanya tampilkan SnackBar jika ada hasil (bukan saat inisialisasi)
          if (result != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                // 2. Tampilkan pesan dinamis dari server!
                content: Text(result['message'] as String? ?? 'Tenant berhasil dibuat!'),
                backgroundColor: Colors.green,
              ),
            );
            // Kosongkan form setelah berhasil
            _formKey.currentState?.reset();
            _nameController.clear();
            _emailController.clear();
            _passwordController.clear();
          }
        },
        error: (error, stackTrace) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal membuat tenant: $error'),
              backgroundColor: Colors.red,
            ),
          );
        },
        loading: () {
          // Tidak perlu melakukan apa-apa saat loading di sini
        },
      );
    });

    final state = ref.watch(createTenantProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Tambah Tenant Baru')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ... TextFormField Anda (tidak ada perubahan di sini) ...
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Nama Tenant/Warung', border: OutlineInputBorder()),
                  validator: (value) => (value?.trim().isEmpty ?? true) ? 'Nama tidak boleh kosong' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email Login Tenant', border: OutlineInputBorder()),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) => (value?.contains('@') != true) ? 'Masukkan email yang valid' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(labelText: 'Password Awal Tenant', border: OutlineInputBorder()),
                  obscureText: true,
                  validator: (value) => (value?.length ?? 0) < 8 ? 'Password minimal 8 karakter' : null,
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                  onPressed: state.isLoading ? null : _submit,
                  child: state.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Simpan Tenant'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}