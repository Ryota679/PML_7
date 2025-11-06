// lib/src/features/auth/presentation/screens/login_screen.dart

import 'package:appwrite/appwrite.dart'; // Pastikan import ini ada untuk AppwriteException & Account
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_app/src/core/api/appwrite_client.dart'; 
import 'package:kantin_app/src/features/tenant_management/presentation/screens/create_tenant_screen.dart';


class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email dan Password tidak boleh kosong')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // --- PERBAIKAN PENTING 3: BERIKAN TIPE EKSPLISIT ---
      // Memberikan tipe 'Account' secara eksplisit untuk membantu analyzer.
      final Account account = ref.read(appwriteAccountProvider);
      
      print('Mencoba login dengan email: ${_emailController.text.trim()}...');

      // Kode ini sekarang seharusnya tidak error lagi.
      await account.createEmailPasswordSession(
  email: _emailController.text.trim(),
  password: _passwordController.text,
    );

      print('✅ Login Berhasil!');

      if (mounted) {
        // Kode ini sekarang seharusnya tidak error lagi karena import sudah benar.
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const CreateTenantScreen()),
        );
      }
    } on AppwriteException catch (e) {
      print('❌ TERJADI ERROR APPWRITE:');
      print('Pesan Error: ${e.message}');
      print('Kode Error: ${e.code}');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login Gagal: ${e.message ?? 'Terjadi kesalahan'}')),
        );
      }
    } catch (e) {
      print('❌ TERJADI ERROR UMUM: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Terjadi kesalahan tak terduga: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login Business Owner')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : _login,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Login'),
            ),
          ],
        ),
      ),
    );
  }
}