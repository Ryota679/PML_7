import 'package:appwrite/models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_app/src/core/api/appwrite_client.dart';
import 'package:kantin_app/src/features/tenant_management/data/datasources/repositories/tenant_repository_impl.dart';

// Provider untuk Business Owner melihat semua tenant yang telah dibuatnya
final businessOwnerTenantsProvider = FutureProvider.autoDispose<DocumentList>((ref) async {
  final tenantRepository = ref.watch(tenantRepositoryProvider);
  final account = ref.watch(appwriteAccountProvider);
  
  // Dapatkan ID business owner yang sedang login
  final user = await account.get();
  
  // Query semua tenant yang dibuat oleh business owner ini
  return tenantRepository.getTenantsByBusinessOwner(user.$id);
});

