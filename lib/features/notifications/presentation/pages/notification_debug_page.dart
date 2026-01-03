import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_app/core/config/appwrite_config.dart';
import 'package:kantin_app/core/services/local_notification_service.dart';
import 'package:kantin_app/features/auth/providers/auth_provider.dart';
import 'package:kantin_app/features/notifications/providers/notification_provider.dart';
import 'package:kantin_app/features/orders/services/order_subscription_service.dart';

/// Debug console for troubleshooting notifications
class NotificationDebugPage extends ConsumerStatefulWidget {
  const NotificationDebugPage({super.key});

  @override
  ConsumerState<NotificationDebugPage> createState() => _NotificationDebugPageState();
}

class _NotificationDebugPageState extends ConsumerState<NotificationDebugPage> {
  String _logs = '';

  void _addLog(String message) {
    setState(() {
      final timestamp = DateTime.now().toString().substring(11, 19);
      _logs = '[$timestamp] $message\n$_logs';
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final notificationState = ref.watch(notificationProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('🐛 Notification Debug'),
        backgroundColor: Colors.deepPurple,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Status Card
          _buildStatusCard(user, notificationState),
          const SizedBox(height: 16),

          // Test Actions
          _buildTestActionsCard(),
          const SizedBox(height: 16),

          // Logs
          _buildLogsCard(),
        ],
      ),
    );
  }

  Widget _buildStatusCard(user, notificationState) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '📊 Status',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            _buildStatusRow('User Role', user?.role ?? 'Not logged in'),
            _buildStatusRow('Tenant ID', user?.tenantId ?? user?.id ?? 'N/A'),
            _buildStatusRow(
              'Subscription Active',
              notificationState.isSubscribed ? '✅ YES' : '❌ NO',
              color: notificationState.isSubscribed ? Colors.green : Colors.red,
            ),
            _buildStatusRow(
              'Pending Orders',
              notificationState.pendingOrdersCount.toString(),
              color: notificationState.pendingOrdersCount > 0 ? Colors.orange : Colors.grey,
            ),
            const Divider(),
            _buildStatusRow('Database ID', AppwriteConfig.databaseId),
            _buildStatusRow('Collection ID', AppwriteConfig.ordersCollectionId),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(
            value,
            style: TextStyle(
              color: color ?? Colors.black87,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTestActionsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '🧪 Test Actions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            
            // Test Notification
            ElevatedButton.icon(
              onPressed: () {
                _addLog('Testing local notification...');
                LocalNotificationService.instance.showOrderNotification(
                  orderId: 'test-${DateTime.now().millisecondsSinceEpoch}',
                  orderNumber: 'TEST-${DateTime.now().hour}${DateTime.now().minute}',
                  customerName: 'Debug Test Customer',
                );
                _addLog('✅ Notification sent');
              },
              icon: const Icon(Icons.notifications_active),
              label: const Text('Test Notification'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            ),
            const SizedBox(height: 8),

            // Request Permissions
            ElevatedButton.icon(
              onPressed: () async {
                _addLog('Requesting notification permissions...');
                final granted = await LocalNotificationService.instance.requestPermissions();
                _addLog(granted ? '✅ Permission granted' : '❌ Permission denied');
              },
              icon: const Icon(Icons.security),
              label: const Text('Request Permissions'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            ),
            const SizedBox(height: 8),

            // Refresh Count
            ElevatedButton.icon(
              onPressed: () async {
                _addLog('Refreshing pending orders count...');
                await ref.read(notificationProvider.notifier).refreshCount();
                final count = ref.read(notificationProvider).pendingOrdersCount;
                _addLog('✅ Count refreshed: $count orders');
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh Badge Count'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            ),
            const SizedBox(height: 8),

            // Start Subscription
            ElevatedButton.icon(
              onPressed: () async {
                _addLog('Starting order subscription...');
                await ref.read(notificationProvider.notifier).startOrderSubscription();
                _addLog('✅ Subscription started');
              },
              icon: const Icon(Icons.play_arrow),
              label: const Text('Start Subscription'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
            ),
            const SizedBox(height: 8),

            // Stop Subscription
            ElevatedButton.icon(
              onPressed: () {
                _addLog('Stopping order subscription...');
                ref.read(notificationProvider.notifier).stopOrderSubscription();
                _addLog('✅ Subscription stopped');
              },
              icon: const Icon(Icons.stop),
              label: const Text('Stop Subscription'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '📝 Logs',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _logs = '';
                    });
                  },
                  child: const Text('Clear'),
                ),
              ],
            ),
            const Divider(),
            Container(
              height: 300,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SingleChildScrollView(
                reverse: true,
                child: Text(
                  _logs.isEmpty ? 'No logs yet. Try clicking buttons above!' : _logs,
                  style: const TextStyle(
                    color: Colors.greenAccent,
                    fontFamily: 'monospace',
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
