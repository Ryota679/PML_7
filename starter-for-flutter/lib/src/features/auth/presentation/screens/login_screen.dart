// lib/src/features/auth/presentation/screens/login_screen.dart

import 'package:appwrite/appwrite.dart'; // Pastikan import ini ada untuk AppwriteException & Account
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_app/src/core/api/appwrite_client.dart';
import 'package:kantin_app/ui/business_owner_dashboard.dart';
import 'package:kantin_app/ui/tenant_dashboard.dart';


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
      
      debugPrint('Mencoba login dengan email: ${_emailController.text.trim()}...');

      // Kode ini sekarang seharusnya tidak error lagi.
      await account.createEmailPasswordSession(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      debugPrint('✅ Login Berhasil!');

      final user = await account.get();
      final labels = user.labels;

      if (!mounted) return;

      if (labels.contains('business_owner')) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const BusinessOwnerDashboard()),
        );
      } else if (labels.contains('tenant')) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const TenantDashboard()),
        );
      } else {
        _showError('Akun Anda belum memiliki role yang valid.');
        await account.deleteSession(sessionId: 'current');
      }
    } on AppwriteException catch (e) {
      debugPrint('❌ TERJADI ERROR APPWRITE:');
      debugPrint('Pesan Error: ${e.message}');
      debugPrint('Kode Error: ${e.code}');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login Gagal: ${e.message ?? 'Terjadi kesalahan'}')),
        );
      }
    } catch (e) {
      debugPrint('❌ TERJADI ERROR UMUM: $e');
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

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login Biasa')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Masuk ke Dashboard',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Gunakan email & password Business Owner atau Tenant. '
              'Aplikasi akan otomatis mengarahkan sesuai label akun.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'Password',
                prefixIcon: Icon(Icons.lock),
                border: OutlineInputBorder(),
              ),
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