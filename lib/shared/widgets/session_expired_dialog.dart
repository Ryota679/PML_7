import 'package:flutter/material.dart';
import 'package:kantin_app/core/utils/device_info_helper.dart';

/// Session Expired Dialog
/// 
/// Dialog security alert untuk device LAMA yang sudah di-logout otomatis oleh Appwrite.
/// User tidak bisa melakukan action apapun lagi, dialog ini hanya informasi + redirect.
class SessionExpiredDialog extends StatelessWidget {
  final String? newLoginDevice;
  final DateTime? newLoginAt;
  final VoidCallback onDismiss;
  
  const SessionExpiredDialog({
    super.key,
    this.newLoginDevice,
    this.newLoginAt,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final newDeviceName = newLoginDevice != null
        ? DeviceInfoHelper.getPlatformDisplayName(newLoginDevice!)
        : 'Device lain';
    final newDeviceIcon = newLoginDevice != null
        ? DeviceInfoHelper.getPlatformIcon(newLoginDevice!)
        : Icons.devices;
    final loginTimeText = DeviceInfoHelper.formatLoginTime(newLoginAt);

    return AlertDialog(
      icon: Icon(
        Icons.warning_amber_rounded,
        size: 56,
        color: theme.colorScheme.error,
      ),
      title: const Text('Sesi Anda Telah Berakhir'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // New device login info
          Text(
            'Akun Anda baru saja login dari device lain:',
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 16),
          
          // Device info card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.errorContainer.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.error.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  newDeviceIcon,
                  size: 32,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      newDeviceName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.error,
                      ),
                    ),
                    Text(
                      loginTimeText,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Auto-logout info
          Text(
            'Anda telah dilogout otomatis dari device ini.',
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 24),
          
          // Security warning
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.errorContainer.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: theme.colorScheme.error.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.security,
                  size: 20,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Jika ini bukan Anda, segera ganti password!',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                      fontWeight: FontWeight.w600,
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
          onPressed: onDismiss,
          style: FilledButton.styleFrom(
            backgroundColor: theme.colorScheme.error,
            foregroundColor: theme.colorScheme.onError,
          ),
          child: const Text('Mengerti'),
        ),
      ],
    );
  }
}
