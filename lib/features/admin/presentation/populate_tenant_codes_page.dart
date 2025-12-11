import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_app/core/utils/tenant_code_generator.dart';
import 'package:kantin_app/shared/repositories/tenant_repository.dart';

/// Utility page untuk populate tenant codes untuk existing tenants
class PopulateTenantCodesPage extends ConsumerStatefulWidget {
  const PopulateTenantCodesPage({super.key});

  @override
  ConsumerState<PopulateTenantCodesPage> createState() => _PopulateTenantCodesPageState();
}

class _PopulateTenantCodesPageState extends ConsumerState<PopulateTenantCodesPage> {
  bool _isProcessing = false;
  String _statusMessage = '';
  int _successCount = 0;
  int _failCount = 0;

  Future<void> _populateAllCodes() async {
    setState(() {
      _isProcessing = true;
      _statusMessage = 'Scanning all tenants...';
      _successCount = 0;
      _failCount = 0;
    });

    try {
      final tenantRepo = ref.read(tenantRepositoryProvider);
      
      // Get all active tenants
      final tenants = await tenantRepo.getAllActiveTenants();
      
      setState(() {
        _statusMessage = 'Found ${tenants.length} tenants. Updating codes...';
      });

      for (final tenant in tenants) {
        // Skip if already has code
        if (tenant.tenantCode != null && tenant.tenantCode!.isNotEmpty) {
          continue;
        }

        // Generate code
        final code = TenantCodeGenerator.generateCode(tenant.id);
        
        // Update tenant
        final success = await tenantRepo.updateTenantCode(tenant.id, code);
        
        if (success) {
          _successCount++;
          setState(() {
            _statusMessage = 'Updated ${tenant.name}: $code ($_successCount/${tenants.length})';
          });
        } else {
          _failCount++;
        }
      }

      setState(() {
        _isProcessing = false;
        _statusMessage = 'Complete! Success: $_successCount, Failed: $_failCount';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Populated codes for $_successCount tenants'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _statusMessage = 'Error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Populate Tenant Codes'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue.shade700),
                        const SizedBox(width: 12),
                        Text(
                          'Populate Tenant Codes',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'This will scan all active tenants and generate codes for those without one.',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            if (_statusMessage.isNotEmpty)
              Card(
                color: _isProcessing ? Colors.blue.shade50 : Colors.green.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_isProcessing)
                        const LinearProgressIndicator(),
                      const SizedBox(height: 12),
                      Text(_statusMessage),
                      if (_successCount > 0 || _failCount > 0) ...[
                        const SizedBox(height: 8),
                        Text('Success: $_successCount | Failed: $_failCount'),
                      ],
                    ],
                  ),
                ),
              ),
            
            const SizedBox(height: 24),
            
            FilledButton.icon(
              onPressed: _isProcessing ? null : _populateAllCodes,
              icon: _isProcessing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.auto_fix_high),
              label: Text(_isProcessing ? 'Processing...' : 'Populate All Codes'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
