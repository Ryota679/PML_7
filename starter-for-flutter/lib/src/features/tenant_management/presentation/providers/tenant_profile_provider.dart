import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_app/src/features/tenant_management/data/datasources/repositories/tenant_repository_impl.dart';
import 'package:kantin_app/src/features/tenant_management/domain/repositories/tenant_repository.dart';
import 'package:appwrite/models.dart';

// Provider untuk update tenant profile
final updateTenantProfileProvider = StateNotifierProvider.autoDispose<
    UpdateTenantProfileNotifier, AsyncValue<Document?>>((ref) {
  final tenantRepository = ref.watch(tenantRepositoryProvider);
  return UpdateTenantProfileNotifier(tenantRepository);
});

class UpdateTenantProfileNotifier
    extends StateNotifier<AsyncValue<Document?>> {
  final TenantRepository _tenantRepository;

  UpdateTenantProfileNotifier(this._tenantRepository)
      : super(const AsyncValue.data(null));

  Future<void> updateProfile({
    required String tenantId,
    String? name,
    String? logoUrl,
    String? description,
    String? status,
  }) async {
    state = const AsyncValue.loading();
    try {
      final result = await _tenantRepository.updateTenant(
        tenantId: tenantId,
        name: name,
        logoUrl: logoUrl,
        description: description,
        status: status,
      );
      state = AsyncValue.data(result);
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }

  void reset() {
    state = const AsyncValue.data(null);
  }
}

