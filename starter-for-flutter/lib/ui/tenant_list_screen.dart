import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_app/src/features/tenant_management/presentation/providers/tenant_list_provider.dart';

class TenantListScreen extends ConsumerWidget {
  const TenantListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tenantsAsync = ref.watch(tenantListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Tenants'),
      ),
      body: tenantsAsync.when(
        data: (tenants) {
          if (tenants.documents.isEmpty) {
            return const Center(
              child: Text('No tenants found.'),
            );
          }
          return ListView.builder(
            itemCount: tenants.documents.length,
            itemBuilder: (context, index) {
              final tenant = tenants.documents[index];
              return ListTile(
                title: Text(tenant.data['name']),
                subtitle: Text(tenant.data['owner_user_id']),
              );
            },
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stackTrace) => Center(
          child: Text('Error: $error'),
        ),
      ),
    );
  }
}
