import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_app/core/config/appwrite_config.dart';
import 'package:kantin_app/core/providers/appwrite_provider.dart';
import 'package:kantin_app/features/auth/providers/auth_provider.dart';
import 'package:kantin_app/shared/models/tenant_model.dart';

/// Provider to fetch current tenant information
final currentTenantProvider = FutureProvider<TenantModel?>((ref) async {
  final user = ref.watch(authProvider).user;
  
  if (user?.tenantId == null) {
    return null;
  }

  try {
    final databases = ref.watch(appwriteDatabasesProvider);
    final tenantDoc = await databases.getDocument(
      databaseId: AppwriteConfig.databaseId,
      collectionId: AppwriteConfig.tenantsCollectionId,
      documentId: user!.tenantId!,
    );

    return TenantModel.fromDocument(tenantDoc);
  } catch (e) {
    return null;
  }
});
