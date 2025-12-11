import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Inactive Tenant Page
/// 
/// Shown when free tier user tries to access non-selected tenant
/// Offers upgrade or swap options
class InactiveTenantPage extends StatelessWidget {
  const InactiveTenantPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tenant Tidak Aktif'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Lock Icon
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.lock_outline,
                  size: 80,
                  color: Colors.grey.shade400,
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Title
              Text(
                'Tenant Tidak Aktif',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 16),
              
              // Description
              Text(
                'Tenant ini tidak termasuk dalam 2 tenant aktif Anda pada paket gratis.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 12),
              
              Text(
                'Untuk mengakses tenant ini, Anda dapat:',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 32),
              
              // Options Cards
              _buildOptionCard(
                context,
                icon: Icons.swap_horiz,
                title: 'Tukar Tenant Aktif',
                description: 'Ganti salah satu tenant aktif Anda dengan tenant ini',
                color: Colors.blue,
                onTap: () {
                  // Navigate back to business owner dashboard
                  // User can use swap banner to change selection
                  context.go('/business-owner');
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Gunakan banner "Tukar Tenant" untuk mengganti pilihan'),
                      duration: Duration(seconds: 4),
                    ),
                  );
                },
              ),
              
              const SizedBox(height: 16),
              
              _buildOptionCard(
                context,
                icon: Icons.workspace_premium,
                title: 'Upgrade ke Premium',
                description: 'Akses unlimited tenant tanpa batas',
                color: Colors.amber.shade700,
                onTap: () {
                  // TODO: Navigate to upgrade page
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Fitur upgrade akan tersedia segera'),
                      duration: Duration(seconds: 3),
                    ),
                  );
                },
              ),
              
              const SizedBox(height: 32),
              
              // Back Button
              TextButton.icon(
                onPressed: () {
                  context.go('/business-owner');
                },
                icon: const Icon(Icons.arrow_back),
                label: const Text('Kembali ke Dashboard'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
