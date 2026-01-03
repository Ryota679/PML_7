import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kantin_app/shared/models/user_model.dart';

/// Trial Expiry Warning Banner
/// 
/// Shows warning when Business Owner's trial is about to expire
/// or has expired and they haven't selected 2 tenants yet.
/// 
/// Displays at H-7, H-3, and H-1 before expiry
class TrialExpiryBanner extends ConsumerWidget {
  final UserModel user;
  
  const TrialExpiryBanner({
    super.key,
    required this.user,
  });
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Don't show if user is premium or already submitted selection
    if (user.isPremium || user.selectionSubmittedAt != null) {
      return const SizedBox.shrink();
    }
    
    final daysRemaining = _getDaysRemaining();
    
    // Don't show if more than 7 days remaining
    if (daysRemaining == null || daysRemaining > 7) {
      return const SizedBox.shrink();
    }
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _getGradientColors(daysRemaining),
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _getIcon(daysRemaining),
                color: Colors.white,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _getTitle(daysRemaining),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _getMessage(daysRemaining),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => context.push('/freemium-tenant-selection'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: _getButtonTextColor(daysRemaining),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Pilih Tenant Sekarang →',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  /// Get days remaining in trial (null if no expiry or already expired)
  int? _getDaysRemaining() {
    if (user.subscriptionExpiresAt == null) return null;
    
    final now = DateTime.now();
    final expiresAt = user.subscriptionExpiresAt!;
    
    if (expiresAt.isBefore(now)) {
      // Trial already expired
      return 0;
    }
    
    final difference = expiresAt.difference(now);
    return difference.inDays;
  }
  
  /// Get icon based on urgency
  IconData _getIcon(int daysRemaining) {
    if (daysRemaining == 0) return Icons.error_outline;
    if (daysRemaining <= 1) return Icons.warning_amber;
    return Icons.info_outline;
  }
  
  /// Get title based on urgency
  String _getTitle(int daysRemaining) {
    if (daysRemaining == 0) {
      return '⚠️ Pilih 2 Tenant Prioritas Anda';
    } else if (daysRemaining == 1) {
      return '⏰ Trial Berakhir Besok!';
    } else {
      return '📢 Trial Premium Akan Berakhir';
    }
  }
  
  /// Get message based on urgency
  String _getMessage(int daysRemaining) {
    if (daysRemaining == 0) {
      return 'Trial Premium telah berakhir. Pilih 2 tenant yang akan mendapat limit lebih baik (20 produk, 2 staff). Tenant lainnya tetap aktif dengan limit ketat (10 produk, 1 staff).';
    } else if (daysRemaining == 1) {
      return 'Trial Premium Anda akan berakhir besok. Pilih 2 tenant prioritas yang akan mendapat limit lebih baik sebelum trial habis.';
    } else {
      return 'Trial Premium Anda akan berakhir dalam $daysRemaining hari. Pilih 2 tenant yang akan mendapat limit lebih baik (20 produk, 2 staff) atau upgrade ke Premium untuk unlimited access.';
    }
  }
  
  /// Get gradient colors based on urgency
  List<Color> _getGradientColors(int daysRemaining) {
    if (daysRemaining == 0) {
      // Red gradient - trial expired
      return [
        const Color(0xFFDC2626),
        const Color(0xFFB91C1C),
      ];
    } else if (daysRemaining <= 1) {
      // Orange gradient - 1 day warning
      return [
        const Color(0xFFEA580C),
        const Color(0xFFC2410C),
      ];
    } else if (daysRemaining <= 3) {
      // Amber gradient - 3 days warning
      return [
        const Color(0xFFF59E0B),
        const Color(0xFFD97706),
      ];
    } else {
      // Blue gradient - 7 days warning
      return [
        const Color(0xFF2563EB),
        const Color(0xFF1D4ED8),
      ];
    }
  }
  
  /// Get button text color based on urgency
  Color _getButtonTextColor(int daysRemaining) {
    if (daysRemaining == 0) {
      return const Color(0xFFDC2626);
    } else if (daysRemaining <= 1) {
      return const Color(0xFFEA580C);
    } else if (daysRemaining <= 3) {
      return const Color(0xFFF59E0B);
    } else {
      return const Color(0xFF2563EB);
    }
  }
}
