import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:kantin_app/core/utils/purchase_result_notifier.dart';

part 'billing_provider.g.dart';

@Riverpod(keepAlive: true)
class BillingService extends _$BillingService {
  late InAppPurchase _iap;
  late StreamSubscription<List<PurchaseDetails>> _subscription;
  
  // Product IDs from Google Play Console
  static const String _kPremiumTenantId = 'premium_tenant_monthly'; // Rp 49.000
  static const String _kPremiumOwnerId = 'owner_pro_monthly';       // Rp 99.000
  
  static const Set<String> _kProductIds = {_kPremiumTenantId, _kPremiumOwnerId};

  @override
  Future<BillingState> build() async {
    print('[BILLING] Initializing BillingService...');
    
    if (kIsWeb) {
      print('[BILLING] Web platform detected - billing not available');
      return const BillingState(isAvailable: false);
    }

    try {
      _iap = InAppPurchase.instance;
      print('[BILLING] InAppPurchase instance created');
      
      // Check availability
      print('[BILLING] Checking if billing is available...');
      final isAvailable = await _iap.isAvailable().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          print('[BILLING] Timeout while checking availability');
          return false;
        },
      );
      
      print('[BILLING] Billing available: $isAvailable');
      if (!isAvailable) {
        return const BillingState(isAvailable: false);
      }
    } catch (e, st) {
      print('[BILLING] Error during initialization: $e');
      print('[BILLING] Stack trace: $st');
      return const BillingState(isAvailable: false);
    }

    // Start listening to purchase updates
    final purchaseUpdated = _iap.purchaseStream;
    _subscription = purchaseUpdated.listen(
      _onPurchaseUpdate,
      onDone: () => _subscription.cancel(),
      onError: (error) {
        print('[BILLING] Purchase stream error: $error');
      },
    );

    // Initial load
    await loadProducts();

    // Return the current state (loadProducts already set it)
    final currentState = state.value ?? const BillingState(isAvailable: true);
    print('[BILLING] Initialization complete. Products in state: ${currentState.products.length}');
    return currentState;
  }

  Future<void> loadProducts() async {
    print('[BILLING] Loading products...');
    state = const AsyncValue.loading();
    try {
      // Query with timeout to prevent infinite loading
      print('[BILLING] Querying product details for: $_kProductIds');
      final ProductDetailsResponse response = 
          await _iap.queryProductDetails(_kProductIds).timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              print('[BILLING] Timeout while loading products (10s)');
              throw TimeoutException('Connection to billing service timed out');
            },
          );
      
      print('[BILLING] Query completed. Products found: ${response.productDetails.length}');
      
      if (response.error != null) {
        print('[BILLING] Query error: ${response.error}');
        state = AsyncValue.error(response.error!, StackTrace.current);
        return;
      }
      
      if (response.notFoundIDs.isNotEmpty) {
        print('[BILLING] Products not found: ${response.notFoundIDs}');
      }
      
      for (final product in response.productDetails) {
        print('[BILLING] Product: ${product.id} - ${product.title} - ${product.price}');
      }

      state = AsyncValue.data(
        BillingState(
          isAvailable: true,
          products: response.productDetails,
        ),
      );
      print('[BILLING] Products loaded successfully');
    } catch (e, st) {
      print('[BILLING] Failed to load products: $e');
      print('[BILLING] Stack trace: $st');
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> purchaseSubscription(String productId) async {
    print('[BILLING] purchaseSubscription called for: $productId');
    final currentState = state.value;
    if (currentState == null || currentState.products.isEmpty) {
      print('[BILLING] No products available to purchase');
      return;
    }

    print('[BILLING] Available products: ${currentState.products.map((p) => p.id).toList()}');
    
    // Find the specific product
    ProductDetails? productDetails;
    try {
      productDetails = currentState.products.firstWhere(
        (product) => product.id == productId,
      );
    } catch (e) {
      print('[BILLING] Product not found: $productId');
      return;
    }

    print('[BILLING] Product found: ${productDetails.id} - ${productDetails.title}');

    final PurchaseParam purchaseParam = PurchaseParam(
      productDetails: productDetails,
    );

    try {
      print('[BILLING] Calling buyNonConsumable...');
      // For subscriptions, always use non-consumable flow (buyNonConsumable)
      // Google Play handles the recurring part.
      await _iap.buyNonConsumable(purchaseParam: purchaseParam);
      print('[BILLING] buyNonConsumable called successfully');
    } catch (e) {
      print('[BILLING] Purchase failed: $e');
    }
  }

  Future<void> restorePurchases() async {
    try {
      await _iap.restorePurchases();
    } catch (e) {
      if (kDebugMode) print('Restore failed: $e');
    }
  }

  void _onPurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) {
    print('[BILLING] Purchase update received: ${purchaseDetailsList.length} items');
    
    for (final purchaseDetails in purchaseDetailsList) {
      print('[BILLING] Purchase status: ${purchaseDetails.status} for ${purchaseDetails.productID}');
      
      if (purchaseDetails.status == PurchaseStatus.pending) {
        print('[BILLING] Purchase pending...');
        // Update state to show pending
        final currentState = state.value;
        if (currentState != null) {
          state = AsyncValue.data(
            currentState.copyWith(lastPurchaseStatus: PurchaseStatus.pending),
          );
        }
      } else {
        if (purchaseDetails.status == PurchaseStatus.error) {
          final errorMsg = purchaseDetails.error?.message ?? 'Unknown error';
          print('[BILLING] ❌ Purchase error: $errorMsg');
          
          // Notify UI
          PurchaseResultNotifier.notifyError(errorMsg);
          
          // Update state with error
          final currentState = state.value;
          if (currentState != null) {
            state = AsyncValue.data(
              currentState.copyWith(
                lastPurchaseStatus: PurchaseStatus.error,
                lastPurchaseError: errorMsg,
              ),
            );
          }
        } else if (purchaseDetails.status == PurchaseStatus.purchased ||
            purchaseDetails.status == PurchaseStatus.restored) {
          print('[BILLING] ✅ Purchase successful: ${purchaseDetails.productID}');
          
          // Notify UI
          PurchaseResultNotifier.notifySuccess(purchaseDetails.productID);
          
          _verifyPurchase(purchaseDetails);
          
          // Update state with success
          final currentState = state.value;
          if (currentState != null) {
            state = AsyncValue.data(
              currentState.copyWith(
                lastPurchaseStatus: PurchaseStatus.purchased,
                lastPurchaseError: null,
              ),
            );
          }
        } else if (purchaseDetails.status == PurchaseStatus.canceled) {
          print('[BILLING] ⚠️ Purchase cancelled by user');
          
          // Notify UI
          PurchaseResultNotifier.notifyCancelled();
          
          // Update state with cancelled
          final currentState = state.value;
          if (currentState != null) {
            state = AsyncValue.data(
              currentState.copyWith(
                lastPurchaseStatus: PurchaseStatus.canceled,
                lastPurchaseError: null,
              ),
            );
          }
        }

        if (purchaseDetails.pendingCompletePurchase) {
          print('[BILLING] Completing purchase...');
          _iap.completePurchase(purchaseDetails);
        }
      }
    }
  }

  Future<void> _verifyPurchase(PurchaseDetails purchaseDetails) async {
    // SECURITY WARNING: 
    // This is client-side verification for the testing phase ONLY.
    // In production, you MUST verify the 'purchaseDetails.verificationData.serverVerificationData'
    // on a secure backend (Appwrite Function) to prevent fraud.
    
    print('[BILLING] 🔍 Verifying purchase: ${purchaseDetails.productID}');
    print('[BILLING] Purchase ID: ${purchaseDetails.purchaseID}');
    print('[BILLING] Transaction date: ${purchaseDetails.transactionDate}');

    // TODO: Call Appwrite Function here in production phase
    
    // For now, we simulate success and update UI
    // Note: The UI should listen to the user's subscription status 
    // which eventually should be updated by the backend.
    // But for immediate feedback:
    print('[BILLING] ✅ Purchase successful! (Client Verified - Testing Only)');
  }
  
  @override
  void stopListening() {
    _subscription.cancel();
  }
}

class BillingState {
  final bool isAvailable;
  final List<ProductDetails> products;
  final PurchaseStatus? lastPurchaseStatus;
  final String? lastPurchaseError;

  const BillingState({
    this.isAvailable = false,
    this.products = const [],
    this.lastPurchaseStatus,
    this.lastPurchaseError,
  });
  
  BillingState copyWith({
    bool? isAvailable,
    List<ProductDetails>? products,
    PurchaseStatus? lastPurchaseStatus,
    String? lastPurchaseError,
  }) {
    return BillingState(
      isAvailable: isAvailable ?? this.isAvailable,
      products: products ?? this.products,
      lastPurchaseStatus: lastPurchaseStatus ?? this.lastPurchaseStatus,
      lastPurchaseError: lastPurchaseError ?? this.lastPurchaseError,
    );
  }
}
