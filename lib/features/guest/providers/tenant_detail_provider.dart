import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_app/features/business_owner/providers/tenant_provider.dart';
import 'package:kantin_app/shared/models/tenant_model.dart';

/// Provider to fetch tenant details by ID
final tenantDetailProvider = FutureProvider.family<TenantModel?, String>((ref, tenantId) async {
  final repository = ref.watch(tenantRepositoryProvider);
  return repository.getTenantById(tenantId);
});
