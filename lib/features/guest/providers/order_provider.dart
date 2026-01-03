import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_app/shared/providers/appwrite_provider.dart';
import 'package:kantin_app/shared/repositories/order_repository.dart';
import 'package:kantin_app/shared/models/order_model.dart';

/// Order Repository Provider
final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  final databases = ref.watch(appwriteDatabaseProvider);
  return OrderRepository(databases);
});

/// Provider to fetch order by order number (for guest tracking)
final orderByNumberProvider = FutureProvider.family<OrderModel?, String>(
  (ref, orderNumber) async {
    final repository = ref.watch(orderRepositoryProvider);
    return repository.getOrderByOrderNumber(orderNumber);
  },
);

/// Provider to fetch single order by ID
final orderByIdProvider = FutureProvider.family<OrderModel, String>(
  (ref, orderId) async {
    final repository = ref.watch(orderRepositoryProvider);
    return repository.getOrderById(orderId);
  },
);

/// Provider to fetch orders by tenant (Sprint 4)
final tenantOrdersProvider = FutureProvider.family<List<OrderModel>, String>(
  (ref, tenantId) async {
    final repository = ref.watch(orderRepositoryProvider);
    return repository.getOrdersByTenant(tenantId: tenantId);
  },
);

/// State provider for current order being tracked (for guest)
final currentOrderProvider = StateProvider<OrderModel?>((ref) => null);
