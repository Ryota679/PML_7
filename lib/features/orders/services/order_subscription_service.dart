import 'dart:async';

import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import 'package:kantin_app/core/config/appwrite_config.dart';
import 'package:kantin_app/core/utils/logger.dart';
import 'package:kantin_app/shared/models/order_model.dart';

/// Service untuk subscribe ke order changes via Appwrite Realtime
class OrderSubscriptionService {
  OrderSubscriptionService._();
  static final instance = OrderSubscriptionService._();

  RealtimeSubscription? _subscription;
  final _orderCreatedController = StreamController<OrderModel>.broadcast();
  final _orderUpdatedController = StreamController<OrderModel>.broadcast();

  /// Stream of newly created orders
  Stream<OrderModel> get onOrderCreated => _orderCreatedController.stream;
  
  /// Stream of updated orders (status changes)
  Stream<OrderModel> get onOrderUpdated => _orderUpdatedController.stream;

  /// Start subscribing to orders for specific tenant
  Future<void> subscribe(String tenantId) async {
    // Clean up existing subscription
    unsubscribe();

    AppLogger.info('📡 [ORDER-SUBSCRIPTION] Subscribing to orders for tenant: $tenantId');

    try {
      // Create Appwrite client
      final client = Client()
        ..setEndpoint(AppwriteConfig.endpoint)
        ..setProject(AppwriteConfig.projectId);
      
      final realtime = Realtime(client);

      // Subscribe to orders collection
      // Filter: where tenant_id == tenantId
      _subscription = realtime.subscribe([
        'databases.${AppwriteConfig.databaseId}.collections.${AppwriteConfig.ordersCollectionId}.documents',
      ]);

      _subscription!.stream.listen((response) {
        AppLogger.info('📨 [ORDER-SUBSCRIPTION] Realtime event: ${response.events}');

        // Check if it's a document create OR update event
        final isCreateEvent = response.events.any((event) => 
          event.contains('.create')
        );
        final isUpdateEvent = response.events.any((event) => 
          event.contains('.update')
        );

        if ((isCreateEvent || isUpdateEvent) && response.payload.isNotEmpty) {
          try {
            final orderDoc = models.Document.fromMap(response.payload);
            final order = OrderModel.fromDocument(orderDoc);

            // Only emit if order belongs to this tenant
            if (order.tenantId == tenantId) {
              if (isCreateEvent) {
                AppLogger.info('🛒 [ORDER-SUBSCRIPTION] New order detected: ${order.orderNumber}');
                _orderCreatedController.add(order);
              } else if (isUpdateEvent) {
                // Order status changed - this will trigger badge refresh
                AppLogger.info('🔄 [ORDER-SUBSCRIPTION] Order updated: ${order.orderNumber}, status: ${order.status.name}');
                _orderUpdatedController.add(order);  // Use separate stream
              }
            }
          } catch (e) {
            AppLogger.error('⚠️ [ORDER-SUBSCRIPTION] Failed to parse order', e);
          }
        }
      }, onError: (error) {
        AppLogger.error('❌ [ORDER-SUBSCRIPTION] Subscription error', error);
      });

      AppLogger.info('✅ [ORDER-SUBSCRIPTION] Subscribed successfully');
    } catch (e) {
      AppLogger.error('❌ [ORDER-SUBSCRIPTION] Failed to subscribe', e);
    }
  }

  /// Stop subscription
  void unsubscribe() {
    if (_subscription != null) {
      AppLogger.info('🔌 [ORDER-SUBSCRIPTION] Unsubscribing...');
      _subscription!.close();
      _subscription = null;
    }
  }

  /// Dispose resources
  void dispose() {
    unsubscribe();
    _orderCreatedController.close();
    _orderUpdatedController.close();
  }
}
