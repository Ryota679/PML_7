import 'package:flutter/material.dart';
import 'package:kantin_app/core/utils/device_info_helper.dart';

/// Device Switch Dialog
/// 
/// Dialog informatif untuk device BARU saat user login,
/// menjelaskan bahwa device lama sudah logout.
class DeviceSwitchDialog extends StatelessWidget {
  final String currentDevice;
  final String? previousDevice;
  final DateTime? previousLoginAt;
  
  const DeviceSwitchDialog({
    super.key,
    required this.currentDevice,
    this.previousDevice,
    this.previousLoginAt,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final previousDeviceName = previousDevice != null
        ? DeviceInfoHelper.getPlatformDisplayName(previousDevice!)
        : 'Unknown';
    final previousDeviceIcon = previousDevice != null
        ? DeviceInfoHelper.getPlatformIcon(previousDevice!)
        : Icons.devices;
    final currentDeviceName = DeviceInfoHelper.getPlatformDisplayName(currentDevice);
    final currentDeviceIcon = DeviceInfoHelper.getPlatformIcon(currentDevice);
    final loginTimeText = DeviceInfoHelper.formatLoginTime(previousLoginAt);

    return AlertDialog(
      icon: Icon(
        Icons.info_outline,
        size: 48,
        color: theme.colorScheme.primary,
      ),
      title: const Text('Login dari Device Baru'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Current device info
          Row(
            children: [
              Icon(
                currentDeviceIcon,
                size: 24,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Anda baru saja login dari:',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      currentDeviceName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),
          
          // Previous device info
          Row(
            children: [
              Icon(
                previousDeviceIcon,
                size: 24,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sesi sebelumnya di:',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      '$previousDeviceName ($loginTimeText)',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'telah dilogout otomatis',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontStyle: FontStyle.italic,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Info message
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Hanya 1 device bisa aktif pada satu waktu',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Mengerti'),
        ),
      ],
    );
  }
}
