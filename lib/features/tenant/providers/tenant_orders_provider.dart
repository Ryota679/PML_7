import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_app/features/auth/providers/auth_provider.dart';
import 'package:kantin_app/shared/models/order_model.dart';
import 'package:kantin_app/shared/repositories/order_repository.dart';
import 'package:kantin_app/core/providers/appwrite_provider.dart';

/// Provider untuk OrderRepository
final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  final databases = ref.watch(databasesProvider);
  return OrderRepository(databases);
});

/// Provider untuk fetch orders dari tenant tertentu
final tenantOrdersProvider = FutureProvider<List<OrderModel>>((ref) async {
  final user = ref.watch(authProvider).user;
  
  if (user == null || user.tenantId == null) {
    throw Exception('User tidak ter-autentikasi atau tidak memiliki tenant_id');
  }

  final orderRepo = ref.watch(orderRepositoryProvider);
  
  // Fetch all orders for this tenant, sorted by newest first
  return await orderRepo.getOrdersByTenant(
    tenantId: user.tenantId!,
    limit: 100, // Get last 100 orders
  );
});

/// Provider untuk fetch orders dengan filter status tertentu
final tenantOrdersByStatusProvider = 
    FutureProvider.family<List<OrderModel>, OrderStatus?>((ref, status) async {
  final user = ref.watch(authProvider).user;
  
  if (user == null || user.tenantId == null) {
    throw Exception('User tidak ter-autentikasi atau tidak memiliki tenant_id');
  }

  final orderRepo = ref.watch(orderRepositoryProvider);
  
  // Fetch orders with optional status filter
  return await orderRepo.getOrdersByTenant(
    tenantId: user.tenantId!,
    statuses: status != null ? [status.name] : null,
    limit: 100,
  );
});
