import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Dialog shown when user tries to login/use app while deactivated
class DeactivatedUserDialog extends StatelessWidget {
  final String userRole; // 'staff' or 'tenant_user'
  final String ownerName;
  final String ownerEmail;
  final String ownerPhone;
  final VoidCallback onLogout;
  final VoidCallback? onUpgrade;

  const DeactivatedUserDialog({
    super.key,
    required this.userRole,
    required this.ownerName,
    required this.ownerEmail,
    required this.ownerPhone,
    required this.onLogout,
    this.onUpgrade,
  });

  String get _message {
    if (userRole == 'staff') {
      return 'Akun staff Anda dinonaktifkan. Tenant dalam mode gratis (1 staff limit).';
    } else {
      return 'Akun Anda dinonaktifkan. Tenant dalam mode gratis (1 user limit).';
    }
  }

  String get _contactLabel {
    if (userRole == 'staff') {
      return 'Hubungi Tenant Owner:';
    } else {
      return 'Hubungi Business Owner:';
    }
  }

  Future<void> _launchWhatsApp() async {
    // Remove + and any spaces from phone number
    final cleanPhone = ownerPhone.replaceAll(RegExp(r'[+\s]'), '');
    final url = Uri.parse('https://wa.me/$cleanPhone');
    
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _launchEmail() async {
    final url = Uri.parse('mailto:$ownerEmail');
    
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: const Column(
        children: [
          Icon(
            Icons.block,
            size: 64,
            color: Colors.red,
          ),
          SizedBox(height: 16),
          Text(
            'Akun Dinonaktifkan',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 24),
          // Contact info removed - shown via button labels instead
        ],
      ),
      actions: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // WhatsApp Button
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _launchWhatsApp,
                icon: const Icon(Icons.chat, color: Colors.green),
                label: const Text('WhatsApp'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.green,
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Email Button
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _launchEmail,
                icon: const Icon(Icons.email, color: Colors.blue),
                label: const Text('Email'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.blue,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            // Logout Button
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  onLogout();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey,
                ),
                child: const Text('Logout'),
              ),
            ),
            if (onUpgrade != null) ...[
              const SizedBox(width: 8),
              // Upgrade Button
              Expanded(
                child: ElevatedButton(
                  onPressed: onUpgrade, // Call directly, no pop needed
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                  ),
                  child: const Text('Upgrade Premium'),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
