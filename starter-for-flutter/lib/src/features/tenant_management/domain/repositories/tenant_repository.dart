
import 'package:appwrite/models.dart';

abstract class TenantRepository {
  Future<Map<String, dynamic>> createTenant({
    required String name,
    required String email,
    required String password,
  });

  Future<DocumentList> getTenants();
  Future<Document?> getTenantByOwner(String userId); // Untuk tenant mencari tenant mereka sendiri
  Future<DocumentList> getTenantsByBusinessOwner(String businessOwnerId); // Untuk business owner melihat semua tenant mereka
  Future<Document> getTenantById(String tenantId);
  
  // Update tenant profile (untuk tenant mengatur sendiri profilnya)
  Future<Document> updateTenant({
    required String tenantId,
    String? name,
    String? logoUrl,
    String? description,
    String? status,
  });
}
