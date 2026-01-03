import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Registration Role Selection Page
/// User chooses: Owner, Tenant, or Staff
class RegistrationSelectionPage extends StatelessWidget {
  const RegistrationSelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pilih Jenis Akun'),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Header
                Icon(
                  Icons.person_add,
                  size: 80,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  'Registrasi Akun Baru',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Pilih jenis akun yang ingin Anda daftarkan',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),

                // Business Owner Card
                _buildRoleCard(
                  context: context,
                  icon: Icons.business,
                  title: 'Pemilik Usaha',
                  subtitle: 'Daftar sebagai pemilik warung/kantin',
                  color: Colors.blue,
                  onTap: () => context.push('/register-owner'),
                ),
                const SizedBox(height: 16),

                // Tenant Card
                _buildRoleCard(
                  context: context,
                  icon: Icons.store,
                  title: 'Tenant',
                  subtitle: 'Masukkan kode undangan dari owner',
                  color: Colors.green,
                  onTap: () => context.push('/enter-tenant-code'),
                ),
                const SizedBox(height: 16),

                // Staff Card
                _buildRoleCard(
                  context: context,
                  icon: Icons.badge,
                  title: 'Staff',
                  subtitle: 'Masukkan kode undangan dari tenant',
                  color: Colors.orange,
                  onTap: () => context.push('/enter-staff-code'),
                ),
                
                const SizedBox(height: 32),
                
                // Back to login
                TextButton(
                  onPressed: () => context.go('/login'),
                  child: const Text('Sudah punya akun? Login di sini'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: color,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey[400],
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
