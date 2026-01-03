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
      backgroundColor: const Color(0xFF101010), // Hitam legam (Pitch Black variation)
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: Colors.grey.shade900, width: 1),
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
                        Colors.cyan.shade900,
                        Colors.teal.shade900,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.cyan.withOpacity(0.2),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.diamond_outlined,
                    color: Colors.cyanAccent,
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
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey),
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
                color: Colors.grey,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 16),
            
            if (isBusinessOwner) ..._buildBusinessOwnerBenefits()
            else ..._buildTenantBenefits(),
            
            const SizedBox(height: 24),
            
            // Pricing
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A), // Slightly lighter black for contrast
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.grey.shade900,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Harga',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey,
                    ),
                  ),
                  Text(
                    'Rp ${isBusinessOwner ? '149' : '49'},000/bulan',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.cyanAccent,
                      letterSpacing: 0.5,
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
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Icon(
            Icons.check_circle_rounded,
            color: Colors.cyan.shade700,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey.shade300,
                height: 1.3,
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
          backgroundColor: Colors.cyan.shade900,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
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
      TextButton(
        onPressed: () => Navigator.pop(context),
        style: TextButton.styleFrom(
          foregroundColor: Colors.grey,
        ),
        child: const Text(
          'Nanti Saja',
          style: TextStyle(fontSize: 15),
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
          backgroundColor: Colors.cyan.shade900, // Reduced intensity like prompt
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          'Upgrade Sendiri',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
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
            foregroundColor: Colors.cyanAccent,
            padding: const EdgeInsets.symmetric(vertical: 14),
            side: BorderSide(color: Colors.cyan.shade900),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      
      const SizedBox(height: 8),
      
      // Cancel
      TextButton(
        onPressed: () => Navigator.pop(context),
        style: TextButton.styleFrom(
          foregroundColor: Colors.grey,
        ),
        child: const Text(
          'Nanti Saja',
          style: TextStyle(fontSize: 15),
        ),
      ),
    ];
  }

  void _contactSales(BuildContext context) {
    // TODO: Implement actual sales contact (WhatsApp, email, etc.)
    // For now, show a placeholder
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Fitur pembayaran akan segera tersedia!'),
        backgroundColor: Colors.teal,
      ),
    );
  }

  void _contactBusinessOwner(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('Hubungi Business Owner', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (businessOwnerEmail != null) ...[
              const Text('Email:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
              Text(businessOwnerEmail!, style: const TextStyle(color: Colors.white)),
              const SizedBox(height: 12),
            ],
            if (businessOwnerPhone != null) ...[
              const Text('Phone:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
              Text(businessOwnerPhone!, style: const TextStyle(color: Colors.white)),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close contact dialog
            },
            child: const Text('OK', style: TextStyle(color: Colors.cyanAccent)),
          ),
        ],
      ),
    );
  }
}

