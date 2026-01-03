import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_app/features/notifications/providers/notification_provider.dart';

/// Notification bell widget dengan badge counter
class NotificationBell extends ConsumerWidget {
  const NotificationBell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationState = ref.watch(notificationProvider);
    final pendingCount = notificationState.pendingOrdersCount;

    return IconButton(
      icon: Stack(
        children: [
          const Icon(Icons.notifications),
          if (pendingCount > 0)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(
                  minWidth: 18,
                  minHeight: 18,
                ),
                child: Text(
                  pendingCount > 99 ? '99+' : '$pendingCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
      onPressed: () {
        // Show pending orders info
        final message = pendingCount > 0
            ? 'Ada $pendingCount pesanan menunggu. Lihat di menu "Pesanan".'
            : 'Tidak ada pesanan menunggu saat ini.';
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            duration: const Duration(seconds: 2),
          ),
        );
      },
      tooltip: pendingCount > 0
          ? '$pendingCount pesanan menunggu'
          : 'Lihat pesanan',
    );
  }
}
