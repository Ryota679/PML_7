import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Guest Landing Page
/// First page yang customer lihat (yang tidak login)
class GuestLandingPage extends StatelessWidget {
  const GuestLandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.primaryContainer,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Logo/Icon
                Icon(
                  Icons.restaurant_menu,
                  size: 100,
                  color: Colors.white,
                ),
                const SizedBox(height: 24),
                
                // Title
                Text(
                  'Kantin App',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Order makanan & minuman dengan mudah',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.white.withOpacity(0.9),
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 64),

                // Main CTA - Masukkan Kode
                Card(
                  elevation: 8,
                  child: InkWell(
                    onTap: () => context.push('/enter-code'),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Icon(
                            Icons.pin,
                            size: 48,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Masukkan Kode Tenant',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Punya kode dari warung/kantin?',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.grey[600],
                                ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          FilledButton.icon(
                            onPressed: () => context.push('/enter-code'),
                            icon: const Icon(Icons.arrow_forward),
                            label: const Text('Mulai Order'),
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Divider
                Row(
                  children: [
                    Expanded(child: Divider(color: Colors.white.withOpacity(0.5))),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'atau',
                        style: TextStyle(color: Colors.white.withOpacity(0.8)),
                      ),
                    ),
                    Expanded(child: Divider(color: Colors.white.withOpacity(0.5))),
                  ],
                ),
                const SizedBox(height: 24),

                // Login untuk Tenant/Owner
                OutlinedButton.icon(
                  onPressed: () => context.push('/login'),
                  icon: const Icon(Icons.business),
                  label: const Text('Login untuk Pemilik Usaha'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white, width: 2),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
                
                const SizedBox(height: 48),
                
                // Help Text
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.help_outline,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Tanyakan kode 6 karakter ke pemilik warung/kantin',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
