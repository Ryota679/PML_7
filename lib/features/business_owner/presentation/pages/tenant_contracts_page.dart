import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../data/tenant_user_with_info.dart';
import '../providers/tenant_contracts_provider.dart';
import '../widgets/add_contract_token_dialog.dart';

/// Page for business owner to manage tenant contracts
class TenantContractsPage extends ConsumerWidget {
  const TenantContractsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tenantUsersAsync = ref.watch(tenantContractsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Kontrak Tenant'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(tenantContractsProvider.notifier).refresh(),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(tenantContractsProvider.notifier).refresh(),
        child: tenantUsersAsync.when(
          data: (tenantUsers) {
            if (tenantUsers.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.store_outlined, size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text(
                        'Belum ada tenant',
                        style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Buat tenant terlebih dahulu melalui menu "Kelola Tenant"',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: tenantUsers.length,
              itemBuilder: (context, index) {
                final tenantUserInfo = tenantUsers[index];
                return _buildTenantCard(context, ref, tenantUserInfo);
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Error: $error',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => ref.read(tenantContractsProvider.notifier).refresh(),
                    child: const Text('Coba Lagi'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTenantCard(BuildContext context, WidgetRef ref, TenantUserWithInfo tenantUserInfo) {
    final user = tenantUserInfo.user;
    final tenantName = tenantUserInfo.tenantName;
    
    final now = DateTime.now();
    final contractEndDate = user.contractEndDate;
    
    int? daysRemaining;
    bool isExpired = false;
    bool isExpiringSoon = false;

    if (contractEndDate != null) {
      daysRemaining = contractEndDate.difference(now).inDays;
      isExpired = daysRemaining < 0;
      isExpiringSoon = daysRemaining >= 0 && daysRemaining <= 7;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tenant name (main title)
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.blue.shade100,
                  child: Icon(
                    Icons.store,
                    color: Colors.blue.shade700,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tenantName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Pengelola: ${user.fullName} (@${user.username})',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Contract status
            if (contractEndDate != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isExpired
                      ? Colors.red.shade50
                      : isExpiringSoon
                          ? Colors.orange.shade50
                          : Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isExpired
                        ? Colors.red.shade200
                        : isExpiringSoon
                            ? Colors.orange.shade200
                            : Colors.green.shade200,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isExpired ? Icons.error : Icons.calendar_today,
                      size: 16,
                      color: isExpired
                          ? Colors.red.shade700
                          : isExpiringSoon
                              ? Colors.orange.shade700
                              : Colors.green.shade700,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isExpired
                                ? 'Kontrak Habis'
                                : isExpiringSoon
                                    ? 'Segera Habis'
                                    : 'Kontrak Aktif',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isExpired
                                  ? Colors.red.shade700
                                  : isExpiringSoon
                                      ? Colors.orange.shade700
                                      : Colors.green.shade700,
                            ),
                          ),
                          Text(
                            isExpired
                                ? 'Expired ${daysRemaining!.abs()} hari yang lalu'
                                : 'Sisa $daysRemaining hari (${DateFormat('dd MMM yyyy').format(contractEndDate)})',
                            style: TextStyle(
                              fontSize: 12,
                              color: isExpired
                                  ? Colors.red.shade600
                                  : isExpiringSoon
                                      ? Colors.orange.shade600
                                      : Colors.green.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: Colors.grey.shade600),
                    const SizedBox(width: 8),
                    Text(
                      'Belum ada kontrak',
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),

            // Add token button
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: () => _showAddContractTokenDialog(context, ref, user),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Tambah Token'),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.green,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddContractTokenDialog(
    BuildContext context,
    WidgetRef ref,
    user,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AddContractTokenDialog(user: user),
    );

    if (result == true) {
      ref.read(tenantContractsProvider.notifier).refresh();
    }
  }
}
