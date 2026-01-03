import 'package:flutter/material.dart';
import '../../../../shared/models/tenant_model.dart';

/// Card widget to display tenant information
class TenantCard extends StatelessWidget {
  final TenantModel tenant;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final Function(bool) onToggleStatus;
  final VoidCallback? onShowUpgradeInfo; // Optional callback for upgrade info
  final VoidCallback? onGenerateCode; // NEW: Generate invitation code
  final bool isPremiumUser; // NEW: Check if user is premium to hide upgrade info

  const TenantCard({
    super.key,
    required this.tenant,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleStatus,
    this.onShowUpgradeInfo, // Optional
    this.onGenerateCode, // Optional
    this.isPremiumUser = false, // Default to false
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  // Type icon
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: tenant.isActive
                          ? Colors.blue.shade50
                          : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      tenant.type.icon,
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Name and type
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tenant.name,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 4),
                          Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade100,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                tenant.type.label,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.blue.shade900,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Status badge (isActive)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: tenant.isActive
                                    ? Colors.green.shade100
                                    : Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                tenant.isActive ? 'Aktif' : 'Nonaktif',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: tenant.isActive
                                      ? Colors.green.shade900
                                      : Colors.grey.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            // Selection status badge (selectedForFreeTier)
                            if (tenant.selectedForFreeTier != null) ...{
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: tenant.selectedForFreeTier == true
                                      ? Colors.purple.shade100
                                      : Colors.orange.shade100,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  tenant.selectedForFreeTier == true
                                      ? '✓ Dipilih'
                                      : '🔒 Tidak Dipilih - Upgrade',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: tenant.selectedForFreeTier == true
                                        ? Colors.purple.shade900
                                        : Colors.orange.shade900,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            },
                            // Premium badge (if tenant has individual premium)
                            if (tenant.hasPremiumSubscription) ...{
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.amber.shade100,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.star,
                                      size: 14,
                                      color: Colors.amber.shade900,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Premium',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.amber.shade900,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            },
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Menu button
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      switch (value) {
                        case 'generate_code':
                          onGenerateCode?.call();
                          break;
                        case 'edit':
                          onEdit();
                          break;
                        case 'toggle':
                          onToggleStatus(!tenant.isActive);
                          break;
                        case 'delete':
                          onDelete();
                          break;
                        case 'upgrade_info':
                          // Use dedicated callback if provided, otherwise fallback to onEdit
                          if (onShowUpgradeInfo != null) {
                            onShowUpgradeInfo!();
                          } else {
                            onEdit();
                          }
                          break;
                      }
                    },
                    itemBuilder: (context) {
                      // Check if tenant is not selected (show different menu)
                      final isNotSelected = tenant.selectedForFreeTier == false;
                      
                      return [
                        // NEW: Generate invitation code (always show)
                        const PopupMenuItem(
                          value: 'generate_code',
                          child: Row(
                            children: [
                              Icon(Icons.card_giftcard, size: 20, color: Colors.green),
                              SizedBox(width: 12),
                              Flexible(child: Text('Generate Kode', overflow: TextOverflow.ellipsis)),
                            ],
                          ),
                        ),
                        const PopupMenuDivider(),
                        // Show upgrade info only for non-premium users with unselected tenants
                        if (isNotSelected && !isPremiumUser)
                          const PopupMenuItem(
                            value: 'upgrade_info',
                            child: Row(
                              children: [
                                Icon(Icons.info_outline, size: 20, color: Colors.orange),
                                SizedBox(width: 12),
                                Text('Info Upgrade', style: TextStyle(color: Colors.orange)),
                              ],
                            ),
                          )
                        else
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit, size: 20),
                                SizedBox(width: 12),
                                Text('Edit'),
                              ],
                            ),
                          ),
                        PopupMenuItem(
                          value: 'toggle',
                          child: Row(
                            children: [
                              Icon(
                                tenant.isActive
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Text(tenant.isActive ? 'Nonaktifkan' : 'Aktifkan'),
                            ],
                          ),
                        ),
                        const PopupMenuDivider(),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, size: 20, color: Colors.red),
                              SizedBox(width: 12),
                              Text('Hapus', style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      ];
                    },
                  ),
                ],
              ),
              // Description
              if (tenant.description != null) ...[
                const SizedBox(height: 12),
                Text(
                  tenant.description!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              // Phone
              if (tenant.phone != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.phone, size: 16, color: Colors.grey.shade600),
                    const SizedBox(width: 6),
                    Text(
                      tenant.phone!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
