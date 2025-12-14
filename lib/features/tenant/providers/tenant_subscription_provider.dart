import 'package:appwrite/appwrite.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/config/appwrite_config.dart';
import '../../../core/providers/appwrite_provider.dart';
import '../../../shared/models/tenant_model.dart';
import '../../../core/utils/app_logger.dart';

/// Represents the subscription status and limits for the current tenant
class TenantSubscriptionStatus {
  final bool isBusinessOwnerFreeTier;
  final bool isTenantSelected;
  final int productLimit;
  final String? businessOwnerEmail;
  final String? businessOwnerPhone;

  TenantSubscriptionStatus({
    required this.isBusinessOwnerFreeTier,
    required this.isTenantSelected,
    required this.productLimit,
    this.businessOwnerEmail,
    this.businessOwnerPhone,
  });

  /// Check if current product count has reached the limit
  bool isLimitReached(int currentCount) => currentCount >= productLimit;

  /// Get remaining slots
  int remainingSlots(int currentCount) => productLimit - currentCount;
}

/// Provider to fetch subscription status for the current tenant
final tenantSubscriptionStatusProvider =
    FutureProvider<TenantSubscriptionStatus>((ref) async {
  final user = ref.watch(authProvider).user;
  
  if (user?.tenantId == null) {
    AppLogger.warning('No tenant ID found for user');
    // Default to free tier, non-selected (most restrictive)
    return TenantSubscriptionStatus(
      isBusinessOwnerFreeTier: true,
      isTenantSelected: false,
      productLimit: 10,
    );
  }

  final databases = ref.read(appwriteDatabasesProvider);
  
  try {
    // 1. Get tenant document to find owner ID
    final tenantDoc = await databases.getDocument(
      databaseId: AppwriteConfig.databaseId,
      collectionId: AppwriteConfig.tenantsCollectionId,
      documentId: user!.tenantId!,
    );
    
    final ownerId = tenantDoc.data['owner_id'] as String?;
    
    if (ownerId == null) {
      AppLogger.error('Tenant has no owner_id');
      return TenantSubscriptionStatus(
        isBusinessOwnerFreeTier: true,
        isTenantSelected: false,
        productLimit: 10,
      );
    }
    
    // 2. Get Business Owner's user document
    final ownerDoc = await databases.getDocument(
      databaseId: AppwriteConfig.databaseId,
      collectionId: AppwriteConfig.usersCollectionId,
      documentId: ownerId,
    );
    
    // 3. Check BO's payment status
    final paymentStatus = ownerDoc.data['payment_status'] as String?;
    final isFreeTier = paymentStatus != 'premium' && paymentStatus != 'active';
    
    AppLogger.info('📊 Tenant Subscription Check:');
    AppLogger.info('  BO Payment Status: $paymentStatus');
    AppLogger.info('  BO Free Tier: $isFreeTier');
    
    // 4. If BO is premium, all tenants get unlimited
    if (!isFreeTier) {
      AppLogger.info('  ✅ BO Premium - Unlimited access');
      return TenantSubscriptionStatus(
        isBusinessOwnerFreeTier: false,
        isTenantSelected: true, // Premium = all selected
        productLimit: 999, // Effectively unlimited
        businessOwnerEmail: ownerDoc.data['email'] as String?,
        businessOwnerPhone: ownerDoc.data['phone_number'] as String?,
      );
    }
    
    // 5. BO is free tier - check if tenant is selected
    final selectedTenants = ownerDoc.data['selected_tenants'] as List?;
    final isTenantSelected = selectedTenants?.contains(user.tenantId) ?? false;
    
    AppLogger.info('  Selected Tenants: $selectedTenants');
    AppLogger.info('  Current Tenant ID: ${user.tenantId}');
    AppLogger.info('  Is Selected: $isTenantSelected');
    
    // 6. Determine product limit
    final productLimit = isTenantSelected ? 15 : 10;
    
    AppLogger.info('  📦 Product Limit: $productLimit');
    
    return TenantSubscriptionStatus(
      isBusinessOwnerFreeTier: true,
      isTenantSelected: isTenantSelected,
      productLimit: productLimit,
      businessOwnerEmail: ownerDoc.data['email'] as String?,
      businessOwnerPhone: ownerDoc.data['phone_number'] as String?,
    );
  } catch (e, stackTrace) {
    AppLogger.error('Error fetching tenant subscription status', e, stackTrace);
    // On error, default to most restrictive
    return TenantSubscriptionStatus(
      isBusinessOwnerFreeTier: true,
      isTenantSelected: false,
      productLimit: 10,
    );
  }
});
