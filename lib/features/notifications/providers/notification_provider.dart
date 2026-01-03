import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_app/core/config/appwrite_config.dart';
import 'package:kantin_app/core/providers/appwrite_provider.dart';
import 'package:kantin_app/core/services/local_notification_service.dart';
import 'package:kantin_app/core/utils/logger.dart';
import 'package:kantin_app/features/auth/providers/auth_provider.dart';
import 'package:kantin_app/features/orders/services/order_subscription_service.dart';
import 'package:appwrite/appwrite.dart';

/// State for notifications
class NotificationState {
  final int pendingOrdersCount;  // Count of orders not yet completed
  final bool isSubscribed;

  const NotificationState({
    this.pendingOrdersCount = 0,
    this.isSubscribed = false,
  });

  NotificationState copyWith({
    int? pendingOrdersCount,
    bool? isSubscribed,
  }) {
    return NotificationState(
      pendingOrdersCount: pendingOrdersCount ?? this.pendingOrdersCount,
      isSubscribed: isSubscribed ?? this.isSubscribed,
    );
  }
}

/// Provider for notification management
class NotificationNotifier extends StateNotifier<NotificationState> {
  NotificationNotifier(this._ref) : super(const NotificationState()) {
    _initialize();
  }

  final Ref _ref;

  void _initialize() {
    // Listen to new orders (create events) - SHOW NOTIFICATION
    OrderSubscriptionService.instance.onOrderCreated.listen((order) {
      AppLogger.info('🛒 [NOTIFICATION] New order: ${order.orderNumber}');
      
      // Show notification
      LocalNotificationService.instance.showOrderNotification(
        orderId: order.id ?? '',
        orderNumber: order.orderNumber,
        customerName: order.customerName,
      );

      // Refresh pending count
      _refreshPendingCount();
    });

    // Listen to order updates (status changes) - SILENT REFRESH ONLY
    OrderSubscriptionService.instance.onOrderUpdated.listen((order) {
      AppLogger.info('🔄 [NOTIFICATION] Order updated: ${order.orderNumber} -> ${order.status.name}');
      
      // Refresh badge count silently (no notification)
      _refreshPendingCount();
    });
  }

  /// Start order subscription for tenant/staff
  Future<void> startOrderSubscription() async {
    final user = _ref.read(authProvider).user;
    
    if (user == null) {
      AppLogger.warning('⚠️ [NOTIFICATION] No user, cannot subscribe');
      return;
    }

    // Only for tenant/staff
    if (user.role != 'tenant' && user.role != 'staff') {
      AppLogger.info('ℹ️ [NOTIFICATION] User is ${user.role}, skipping subscription');
      return;
    }

    // Request notification permissions
    final permissionGranted = await LocalNotificationService.instance.requestPermissions();
    if (!permissionGranted) {
      AppLogger.warning('⚠️ [NOTIFICATION] Notification permission denied');
      return;
    }

    // Get tenant ID - both tenant and staff have tenantId field
    final tenantId = user.tenantId;

    if (tenantId == null) {
      AppLogger.error('❌ [NOTIFICATION] No tenantId found for ${user.role}');
      return;
    }

    AppLogger.info('📡 [NOTIFICATION] Starting subscription for tenant: $tenantId');
    await OrderSubscriptionService.instance.subscribe(tenantId);
    
    state = state.copyWith(isSubscribed: true);

    // Fetch initial pending count
    await _refreshPendingCount();
  }

  /// Stop order subscription
  void stopOrderSubscription() {
    AppLogger.info('🔌 [NOTIFICATION] Stopping subscription');
    OrderSubscriptionService.instance.unsubscribe();
    state = state.copyWith(isSubscribed: false);
  }

  /// Fetch pending orders count from Appwrite
  Future<void> _refreshPendingCount() async {
    final user = _ref.read(authProvider).user;
    if (user == null) return;

    final tenantId = user.tenantId;
    if (tenantId == null) return;

    try {
      final databases = _ref.read(appwriteDatabasesProvider);

      AppLogger.info('🔍 [NOTIFICATION] Querying orders for tenant: $tenantId');

      // Query ALL orders for this tenant (no status filter to avoid schema error)
      final result = await databases.listDocuments(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.ordersCollectionId,
        queries: [
          Query.equal('tenant_id', tenantId),
        ],
      );

      AppLogger.info('📦 [NOTIFICATION] Query returned ${result.documents.length} documents (total: ${result.total})');

      // Count pending orders in memory
      int pendingCount = 0;
      for (var doc in result.documents) {
        final status = doc.data['order_status'] as String?;  // Changed from 'status' to 'order_status'
        final docTenantId = doc.data['tenant_id'] as String?;
        
        AppLogger.info('  📄 Order ${doc.$id}: tenant_id=$docTenantId, status=$status');
        
        // Only count orders with status = 'pending'
        if (status == 'pending') {
          pendingCount++;
          AppLogger.info('    ✅ Counted as pending');
        } else {
          AppLogger.info('    ❌ Skipped (status: $status)');
        }
      }

      AppLogger.info('📊 [NOTIFICATION] Pending orders: $pendingCount / ${result.total} total');

      state = state.copyWith(pendingOrdersCount: pendingCount);
    } catch (e) {
      AppLogger.error('❌ [NOTIFICATION] Failed to fetch pending count', e);
    }
  }

  /// Manually refresh count (called when order status changes)
  Future<void> refreshCount() async {
    await _refreshPendingCount();
  }
}

/// Notification provider
final notificationProvider =
    StateNotifierProvider<NotificationNotifier, NotificationState>((ref) {
  return NotificationNotifier(ref);
});
