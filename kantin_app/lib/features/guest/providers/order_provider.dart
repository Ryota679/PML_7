import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_app/core/providers/appwrite_provider.dart';
import 'package:kantin_app/features/guest/data/order_repository.dart';
import 'package:kantin_app/shared/models/order_model.dart';

/// Order Repository Provider
final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  final databases = ref.watch(appwriteDatabasesProvider);
  return OrderRepository(databases: databases);
});

/// Provider to fetch orders by tenant
final tenantOrdersProvider = FutureProvider.family<List<OrderModel>, String>(
  (ref, tenantId) async {
    final repository = ref.watch(orderRepositoryProvider);
    return repository.getOrdersByTenant(tenantId);
  },
);

/// Provider to fetch orders by tenant with status filter
final tenantOrdersByStatusProvider = FutureProvider.family<List<OrderModel>, ({String tenantId, OrderStatus status})>(
  (ref, params) async {
    final repository = ref.watch(orderRepositoryProvider);
    return repository.getOrdersByTenant(
      params.tenantId,
      status: params.status,
    );
  },
);

/// Provider to fetch single order by ID
final orderByIdProvider = FutureProvider.family<OrderModel, String>(
  (ref, orderId) async {
    final repository = ref.watch(orderRepositoryProvider);
    return repository.getOrderById(orderId);
  },
);

/// State provider for current order being tracked (for guest)
final currentOrderProvider = StateProvider<OrderModel?>((ref) => null);
