import 'package:flutter_riverpod/flutter_riverpod.dart';
// Sesuaikan path import ini jika berbeda di struktur Anda
import 'package:kantin_app/src/features/tenant_management/data/datasources/repositories/tenant_repository_impl.dart';
import 'package:kantin_app/src/features/tenant_management/domain/repositories/tenant_repository.dart';

// 1. Ubah tipe state dari <void> menjadi <Map<String, dynamic>?>
// Tanda tanya (?) berarti state awalnya bisa null.
final createTenantProvider = StateNotifierProvider<CreateTenantNotifier,
    AsyncValue<Map<String, dynamic>?>>((ref) {
  final tenantRepository = ref.watch(tenantRepositoryProvider);
  return CreateTenantNotifier(tenantRepository);
});

// 2. Ubah kelas Notifier agar sesuai dengan tipe state yang baru
class CreateTenantNotifier
    extends StateNotifier<AsyncValue<Map<String, dynamic>?>> {
  final TenantRepository _tenantRepository;

  // State awal adalah data dengan nilai null
  CreateTenantNotifier(this._tenantRepository)
      : super(const AsyncValue.data(null));

  Future<void> createTenant({
    required String name,
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    try {
      // 3. Tangkap hasil dari repository
      final result = await _tenantRepository.createTenant(
        name: name,
        email: email,
        password: password,
      );
      // 4. Simpan hasil (berupa Map) ke dalam state
      state = AsyncValue.data(result);
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }
}