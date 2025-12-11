import 'package:flutter/material.dart';

///  Upgrade dialog shown when free tier users try to access premium features
/// 
/// Phase 3: Converts free tier users by showing premium benefits
class UpgradeDialog extends StatelessWidget {
  final bool isBusinessOwner;
  final String? businessOwnerEmail;
  final String? businessOwnerPhone;

  const UpgradeDialog({
    Key? key,
    this.isBusinessOwner = true,
    this.businessOwnerEmail,
    this.businessOwnerPhone,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.purple.shade300,
                        Colors.deepPurple.shade500,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.diamond,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text(
                    'Upgrade ke Premium',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Benefits
            const Text(
              'Dapatkan akses penuh:',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            
            if (isBusinessOwner) ..._buildBusinessOwnerBenefits()
            else ..._buildTenantBenefits(),
            
            const SizedBox(height: 24),
            
            // Pricing
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.purple.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.purple.shade200,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Harga',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    'Rp ${isBusinessOwner ? '149' : '49'},000/bulan',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.purple.shade700,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Actions
            if (isBusinessOwner)
              ..._buildBusinessOwnerActions(context)
            else
              ..._buildTenantActions(context),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildBusinessOwnerBenefits() {
    return [
      _buildBenefitItem('Unlimited tenants'),
      _buildBenefitItem('Unlimited users'),
      _buildBenefitItem('Edit tenant & user data'),
      _buildBenefitItem('Advanced analytics (segera)'),
      _buildBenefitItem('Export reports (segera)'),
      _buildBenefitItem('Priority support'),
    ];
  }

  List<Widget> _buildTenantBenefits() {
    return [
      _buildBenefitItem('Unlimited products'),
      _buildBenefitItem('Unlimited categories'),
      _buildBenefitItem('Unlimited staff'),
      _buildBenefitItem('Edit semua data'),
      _buildBenefitItem('Advanced analytics (segera)'),
      _buildBenefitItem('Priority support'),
    ];
  }

  Widget _buildBenefitItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(
            Icons.check_circle,
            color: Colors.green.shade600,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildBusinessOwnerActions(BuildContext context) {
    return [
      ElevatedButton(
        onPressed: () => _contactSales(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.purple.shade700,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: const Text(
          'Hubungi Sales',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      const SizedBox(height: 12),
      OutlinedButton(
        onPressed: () => Navigator.pop(context),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.black87,
          padding: const EdgeInsets.symmetric(vertical: 14),
          side: BorderSide(color: Colors.grey.shade300),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: const Text(
          'Nanti Saja',
          style: TextStyle(fontSize: 16),
        ),
      ),
    ];
  }

  List<Widget> _buildTenantActions(BuildContext context) {
    return [
      // Option 1: Upgrade sendiri
      ElevatedButton(
        onPressed: () => _contactSales(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.purple.shade700,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: const Text(
          'Upgrade Sendiri',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      
      const SizedBox(height: 12),
      
      // Option 2: Hubungi BO (if contact info available)
      if (businessOwnerEmail != null || businessOwnerPhone != null)
        OutlinedButton.icon(
          onPressed: () => _contactBusinessOwner(context),
          icon: const Icon(Icons.phone, size: 20),
          label: const Text(
            'Hubungi Business Owner',
            style: TextStyle(fontSize: 16),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.blue.shade700,
            padding: const EdgeInsets.symmetric(vertical: 14),
            side: BorderSide(color: Colors.blue.shade200),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      
      const SizedBox(height: 12),
      
      // Cancel
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text(
          'Nanti Saja',
          style: TextStyle(fontSize: 16, color: Colors.black54),
        ),
      ),
    ];
  }

  void _contactSales(BuildContext context) {
    // TODO: Implement actual sales contact (WhatsApp, email, etc.)
    // For now, show a placeholder
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hubungi Sales'),
        content: const Text(
          'WhatsApp: +62 XXX XXXX XXXX\n'
          'Email: sales@example.com\n\n'
          'Tim kami siap membantu Anda!',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close sales dialog
              Navigator.pop(context); // Close upgrade dialog
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _contactBusinessOwner(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hubungi Business Owner'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (businessOwnerEmail != null) ...[
              const Text('Email:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(businessOwnerEmail!),
              const SizedBox(height: 12),
            ],
            if (businessOwnerPhone != null) ...[
              const Text('Phone:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(businessOwnerPhone!),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close contact dialog
              Navigator.pop(context); // Close upgrade dialog
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
