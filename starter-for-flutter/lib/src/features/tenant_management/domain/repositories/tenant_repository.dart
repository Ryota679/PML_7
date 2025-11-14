
import 'package:appwrite/models.dart';

abstract class TenantRepository {
  Future<Map<String, dynamic>> createTenant({
    required String name,
    required String email,
    required String password,
  });

  Future<DocumentList> getTenants();
  Future<Document?> getTenantByOwner(String userId);
  Future<Document> getTenantById(String tenantId);
}
