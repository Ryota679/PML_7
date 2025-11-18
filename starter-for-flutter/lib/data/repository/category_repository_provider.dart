import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_app/data/repository/category_repository.dart';
import 'package:kantin_app/src/core/api/appwrite_client.dart';

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  final client = ref.watch(appwriteClientProvider);
  return CategoryRepository(client);
});
