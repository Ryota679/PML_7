import 'package:appwrite/models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_app/src/features/tenant_management/data/datasources/repositories/tenant_repository_impl.dart';

final tenantListProvider = FutureProvider.autoDispose<DocumentList>((ref) async {
  final tenantRepository = ref.watch(tenantRepositoryProvider);
  return tenantRepository.getTenants();
});
