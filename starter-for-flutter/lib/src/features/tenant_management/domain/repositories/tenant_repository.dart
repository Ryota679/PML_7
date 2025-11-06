
abstract class TenantRepository {
  Future<Map<String, dynamic>> createTenant({
    required String name,
    required String email,
    required String password,
  });
}
