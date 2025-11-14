import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_app/data/repository/order_repository.dart';
import 'package:kantin_app/src/core/api/appwrite_client.dart';

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  final client = ref.watch(appwriteClientProvider);
  return OrderRepository(client);
});
