import 'package:flutter/material.dart';
import 'package:kantin_app/shared/models/user_model.dart';
import 'package:kantin_app/shared/models/tenant_model.dart';
import '../../utils/tenant_selection_helper.dart';

/// Tenant Upgrade Dialog
/// 
/// Shows upgrade options when user tries to access limited tenant
class TenantUpgradeDialog extends StatelessWidget {
  final UserModel user;
  final TenantModel tenant;
  
  const TenantUpgradeDialog({
    super.key,
    required this.user,
    required this.tenant,
  });

  @override
  Widget build(BuildContext context) {
    // Grace period swap removed - always false
    final hasSwapAvailable = false;
    
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.lock_outline,
                    color: Colors.orange.shade700,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tenant Tidak Dipilih',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text(
                        tenant.name,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey.shade600,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Message
            Text(
              'Anda tidak bisa mengelola tenant ini karena tidak termasuk 2 tenant aktif (free tier).',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            
            const SizedBox(height: 24),
            
            // Upgrade Options
            Text(
              'Pilihan Upgrade:',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            
            const SizedBox(height: 16),
            
            // Option 1: Use Swap Opportunity
            if (hasSwapAvailable)
              _UpgradeOption(
                icon: Icons.swap_horiz,
                iconColor: Colors.blue,
                title: 'Gunakan Swap Opportunity',
                subtitle: 'Tukar dengan tenant yang sudah dipilih',
                onTap: () async {
                  Navigator.pop(context);
                  // Note: This would need BuildContext to be wrapped in Consumer to access ref
                  // Since hasSwapAvailable is always false, this code is unreachable
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Swap feature temporarily disabled'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                },
              ),
            
            // Option 2: Upgrade Business Owner to Premium
            _UpgradeOption(
              icon: Icons.workspace_premium,
              iconColor: Colors.purple,
              title: 'Upgrade Business Owner ke Premium',
              subtitle: 'Rp 149.000/bulan - Unlimited tenants',
              onTap: () {
                Navigator.pop(context);
                // TODO: Navigate to BO premium upgrade page
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('🚧 Payment integration coming soon'),
                    backgroundColor: Colors.orange,
                  ),
                );
              },
            ),
            
            const SizedBox(height: 24),
            
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Batal'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      // TODO: Show read-only view
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Mode read-only belum tersedia'),
                          backgroundColor: Colors.blue,
                        ),
                      );
                    },
                    icon: const Icon(Icons.visibility),
                    label: const Text('View Only'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Upgrade Option Card
class _UpgradeOption extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  
  const _UpgradeOption({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
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
