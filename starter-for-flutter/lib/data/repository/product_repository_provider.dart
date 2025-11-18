import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_app/data/repository/product_repository.dart';
import 'package:kantin_app/src/core/api/appwrite_client.dart';

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  final client = ref.watch(appwriteClientProvider);
  return ProductRepository(client);
});
