import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/cart_persistence_service.dart';

/// Provider for Cart Persistence Service
/// 
/// Use this provider to access cart storage functionality
/// throughout the app
/// 
/// Example usage:
/// ```dart
/// final cartService = ref.read(cartPersistenceServiceProvider);
/// await cartService.saveCart('Q8L2PH', cartItems);
/// ```
final cartPersistenceServiceProvider = Provider<CartPersistenceService>((ref) {
  return CartPersistenceService();
});
