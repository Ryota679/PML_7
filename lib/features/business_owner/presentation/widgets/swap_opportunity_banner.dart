import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_app/shared/models/user_model.dart';

/// Swap Opportunity Banner
/// 
/// Shows when user is in grace period (can swap tenant selection)
/// Displays countdown and "Tukar Tenant" button
class SwapOpportunityBanner extends ConsumerWidget {
  final UserModel user;
  
  const SwapOpportunityBanner({
    super.key,
    required this.user,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Grace period swap removed - always hide banner
    // (New D-7 trial swap logic in business_owner_dashboard instead)
    return const SizedBox.shrink();
  }
}
