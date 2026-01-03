import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_app/shared/models/cart_item_model.dart';
import 'package:kantin_app/shared/models/product_model.dart';

/// Cart State Notifier
/// Manages shopping cart state (local, not persisted to database)
class CartNotifier extends StateNotifier<Map<String, CartItemModel>> {
  CartNotifier() : super({});

  /// Add item to cart or increment quantity if already exists
  void addItem(ProductModel product, {int quantity = 1}) {
    if (state.containsKey(product.id)) {
      // Product already in cart, increment quantity
      final existing = state[product.id]!;
      state = {
        ...state,
        product.id: existing.copyWith(quantity: existing.quantity + quantity),
      };
    } else {
      // New product, add to cart
      state = {
        ...state,
        product.id: CartItemModel(product: product, quantity: quantity),
      };
    }
  }

  /// Remove item from cart
  void removeItem(String productId) {
    final newState = Map<String, CartItemModel>.from(state);
    newState.remove(productId);
    state = newState;
  }

  /// Update item quantity
  void updateQuantity(String productId, int newQuantity) {
    if (newQuantity <= 0) {
      removeItem(productId);
      return;
    }

    if (state.containsKey(productId)) {
      state = {
        ...state,
        productId: state[productId]!.copyWith(quantity: newQuantity),
      };
    }
  }

  /// Increment quantity by 1
  void incrementQuantity(String productId) {
    if (state.containsKey(productId)) {
      final existing = state[productId]!;
      updateQuantity(productId, existing.quantity + 1);
    }
  }

  /// Decrement quantity by 1
  void decrementQuantity(String productId) {
    if (state.containsKey(productId)) {
      final existing = state[productId]!;
      updateQuantity(productId, existing.quantity - 1);
    }
  }

  /// Update item notes
  void updateNotes(String productId, String notes) {
    if (state.containsKey(productId)) {
      state = {
        ...state,
        productId: state[productId]!.copyWith(notes: notes),
      };
    }
  }

  /// Clear all items from cart
  void clearCart() {
    state = {};
  }

  /// Get total number of items (sum of all quantities)
  int get totalItems {
    return state.values.fold<int>(
      0,
      (sum, item) => sum + item.quantity,
    );
  }

  /// Get total amount (sum of all subtotals)
  int get totalAmount {
    return state.values.fold<int>(
      0,
      (sum, item) => sum + item.subtotal,
    );
  }

  /// Get formatted total amount
  String get formattedTotalAmount {
    return 'Rp ${totalAmount.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        )}';
  }

  /// Get list of cart items
  List<CartItemModel> get items => state.values.toList();

  /// Check if cart is empty
  bool get isEmpty => state.isEmpty;

  /// Check if cart has items
  bool get isNotEmpty => state.isNotEmpty;
}

/// Cart Provider
final cartProvider = StateNotifierProvider<CartNotifier, Map<String, CartItemModel>>((ref) {
  return CartNotifier();
});

/// Computed provider for total items count (for badge)
final cartTotalItemsProvider = Provider<int>((ref) {
  final cart = ref.watch(cartProvider);
  return cart.values.fold<int>(0, (sum, item) => sum + item.quantity);
});

/// Computed provider for total amount
final cartTotalAmountProvider = Provider<int>((ref) {
  final cart = ref.watch(cartProvider);
  return cart.values.fold<int>(0, (sum, item) => sum + item.subtotal);
});

/// Computed provider for formatted total amount
final cartFormattedTotalProvider = Provider<String>((ref) {
  final total = ref.watch(cartTotalAmountProvider);
  return 'Rp ${total.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]}.',
      )}';
});

/// Computed provider for cart items list
final cartItemsListProvider = Provider<List<CartItemModel>>((ref) {
  final cart = ref.watch(cartProvider);
  return cart.values.toList();
});

/// Computed provider for cart empty state
final cartIsEmptyProvider = Provider<bool>((ref) {
  final cart = ref.watch(cartProvider);
  return cart.isEmpty;
});
