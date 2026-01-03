import 'package:flutter/material.dart';
import '../../../../shared/models/tenant_model.dart';
import '../../../../shared/models/user_model.dart';

/// Card widget to display tenant user information
class TenantUserCard extends StatelessWidget {
  final UserModel user;
  final TenantModel? tenant;
  final VoidCallback onRemove;
  final VoidCallback onDelete; // NEW: permanent delete
  final Function(bool) onToggleStatus;

  const TenantUserCard({
    super.key,
    required this.user,
    this.tenant,
    required this.onRemove,
    required this.onDelete, // NEW
    required this.onToggleStatus,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                // Avatar
                CircleAvatar(
                  backgroundColor: user.isActive
                      ? Colors.blue.shade100
                      : Colors.grey.shade300,
                  child: Icon(
                    Icons.person,
                    color: user.isActive
                        ? Colors.blue.shade700
                        : Colors.grey.shade600,
                  ),
                ),
                const SizedBox(width: 12),
                // Name and email
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.fullName,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.email,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey.shade600,
                            ),
                      ),
                    ],
                  ),
                ),
                // Menu button
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'toggle':
                        // Always use toggle status - validation happens in _toggleUserStatus
                        onToggleStatus(!user.isActive);
                        break;
                      case 'remove':
                        onRemove();
                        break;
                      case 'delete': // NEW: permanent delete
                        onDelete();
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'toggle',
                      child: Row(
                        children: [
                          Icon(
                            user.isActive
                                ? Icons.visibility_off
                                : Icons.check_circle,
                            size: 20,
                            color: user.isActive ? null : Colors.green,
                          ),
                          const SizedBox(width: 12),
                          Text(user.isActive ? 'Nonaktifkan' : 'Aktifkan'),
                        ],
                      ),
                    ),
                    const PopupMenuDivider(),
                    const PopupMenuItem(
                      value: 'remove',
                      child: Row(
                        children: [
                          Icon(Icons.person_remove, size: 20, color: Colors.orange),
                          SizedBox(width: 12),
                          Text('Unassign', style: TextStyle(color: Colors.orange)),
                        ],
                      ),
                    ),
                    const PopupMenuDivider(),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_forever, size: 20, color: Colors.red),
                          SizedBox(width: 12),
                          Text('Delete Permanent', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Status and tenant info
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                // Role badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.badge,
                        size: 14,
                        color: Colors.purple.shade900,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Admin Tenant',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.purple.shade900,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: user.isActive
                        ? Colors.green.shade100
                        : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        user.isActive ? Icons.check_circle : Icons.cancel,
                        size: 14,
                        color: user.isActive
                            ? Colors.green.shade900
                            : Colors.grey.shade700,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        user.isActive ? 'Aktif' : 'Nonaktif',
                        style: TextStyle(
                          fontSize: 12,
                          color: user.isActive
                              ? Colors.green.shade900
                              : Colors.grey.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                // Tenant badge
                if (tenant != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          tenant!.type.icon,
                          style: const TextStyle(fontSize: 12),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          tenant!.name,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue.shade900,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            // Phone
            if (user.phone != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.phone, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 6),
                  Text(
                    user.phone!,
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
    );
  }
}
