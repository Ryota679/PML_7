import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/appwrite_provider.dart';
import '../../../core/utils/app_logger.dart';
import '../../../shared/models/tenant_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/tenant_repository.dart';

/// Provider for TenantRepository
final tenantRepositoryProvider = Provider<TenantRepository>((ref) {
  final databases = ref.watch(appwriteDatabasesProvider);
  return TenantRepository(databases);
});

/// State for tenant management
class TenantState {
  final List<TenantModel> tenants;
  final bool isLoading;
  final String? error;

  const TenantState({
    this.tenants = const [],
    this.isLoading = false,
    this.error,
  });

  TenantState copyWith({
    List<TenantModel>? tenants,
    bool? isLoading,
    String? error,
  }) {
    return TenantState(
      tenants: tenants ?? this.tenants,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Notifier for managing tenant state
class TenantNotifier extends StateNotifier<TenantState> {
  final TenantRepository _repository;
  final String _ownerId;

  TenantNotifier(this._repository, this._ownerId)
      : super(const TenantState());

  /// Load all tenants for the owner
  Future<void> loadTenants() async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final tenants = await _repository.getTenantsByOwnerId(_ownerId);

      state = state.copyWith(
        tenants: tenants,
        isLoading: false,
      );
    } catch (e, stackTrace) {
      AppLogger.error('Error loading tenants', e, stackTrace);
      state = state.copyWith(
        isLoading: false,
        error: 'Gagal memuat data tenant: $e',
      );
    }
  }

  /// Load only active tenants
  Future<void> loadActiveTenants() async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final tenants = await _repository.getActiveTenants(_ownerId);

      state = state.copyWith(
        tenants: tenants,
        isLoading: false,
      );
    } catch (e, stackTrace) {
      AppLogger.error('Error loading active tenants', e, stackTrace);
      state = state.copyWith(
        isLoading: false,
        error: 'Gagal memuat data tenant: $e',
      );
    }
  }

  /// Create a new tenant
  Future<bool> createTenant({
    required String name,
    required TenantType type,
    String? description,
    String? logoUrl,
    String? phone,
    int displayOrder = 0,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final tenant = await _repository.createTenant(
        ownerId: _ownerId,
        name: name,
        type: type,
        description: description,
        logoUrl: logoUrl,
        phone: phone,
        displayOrder: displayOrder,
      );

      // Add to list
      state = state.copyWith(
        tenants: [tenant, ...state.tenants],
        isLoading: false,
      );

      AppLogger.info('Tenant created successfully');
      return true;
    } catch (e, stackTrace) {
      AppLogger.error('Error creating tenant', e, stackTrace);
      state = state.copyWith(
        isLoading: false,
        error: 'Gagal membuat tenant: $e',
      );
      return false;
    }
  }

  /// Update an existing tenant
  Future<bool> updateTenant(
    String tenantId,
    Map<String, dynamic> updates,
  ) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final updatedTenant = await _repository.updateTenant(tenantId, updates);

      // Update in list
      final updatedList = state.tenants.map((t) {
        return t.id == tenantId ? updatedTenant : t;
      }).toList();

      state = state.copyWith(
        tenants: updatedList,
        isLoading: false,
      );

      AppLogger.info('Tenant updated successfully');
      return true;
    } catch (e, stackTrace) {
      AppLogger.error('Error updating tenant', e, stackTrace);
      state = state.copyWith(
        isLoading: false,
        error: 'Gagal update tenant: $e',
      );
      return false;
    }
  }

  /// Delete a tenant
  Future<bool> deleteTenant(String tenantId) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      await _repository.deleteTenant(tenantId);

      // Remove from list
      final updatedList = state.tenants.where((t) => t.id != tenantId).toList();

      state = state.copyWith(
        tenants: updatedList,
        isLoading: false,
      );

      AppLogger.info('Tenant deleted successfully');
      return true;
    } catch (e, stackTrace) {
      AppLogger.error('Error deleting tenant', e, stackTrace);
      state = state.copyWith(
        isLoading: false,
        error: 'Gagal menghapus tenant: $e',
      );
      return false;
    }
  }

  /// Toggle tenant active status
  Future<bool> toggleStatus(String tenantId, bool isActive) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final updatedTenant = await _repository.toggleTenantStatus(
        tenantId,
        isActive,
      );

      // Update in list
      final updatedList = state.tenants.map((t) {
        return t.id == tenantId ? updatedTenant : t;
      }).toList();

      state = state.copyWith(
        tenants: updatedList,
        isLoading: false,
      );

      AppLogger.info('Tenant status toggled successfully');
      return true;
    } catch (e, stackTrace) {
      AppLogger.error('Error toggling tenant status', e, stackTrace);
      state = state.copyWith(
        isLoading: false,
        error: 'Gagal mengubah status tenant: $e',
      );
      return false;
    }
  }

  /// Update display order
  Future<void> updateDisplayOrder(String tenantId, int newOrder) async {
    try {
      await _repository.updateDisplayOrder(tenantId, newOrder);
      await loadTenants(); // Reload to get updated order
    } catch (e, stackTrace) {
      AppLogger.error('Error updating display order', e, stackTrace);
      state = state.copyWith(
        error: 'Gagal mengubah urutan: $e',
      );
    }
  }
}

/// Provider for tenant management
final tenantProvider =
    StateNotifierProvider.family<TenantNotifier, TenantState, String>(
  (ref, ownerId) {
    final repository = ref.watch(tenantRepositoryProvider);
    return TenantNotifier(repository, ownerId);
  },
);

/// Convenience provider that auto-fetches ownerId from auth
final myTenantsProvider = StateNotifierProvider<TenantNotifier, TenantState>(
  (ref) {
    final auth = ref.watch(authProvider);
    final ownerId = auth.user?.userId ?? '';
    final repository = ref.watch(tenantRepositoryProvider);
    final notifier = TenantNotifier(repository, ownerId);

    // Auto-load on initialization
    if (ownerId.isNotEmpty) {
      Future.microtask(() => notifier.loadTenants());
    }

    return notifier;
  },
);
