import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../shared/models/cart_item_model.dart'; // Using CartItemModel

/// Service for persisting cart data to local storage
/// 
/// Allows cart to survive app restarts and browser refreshes
/// Each tenant has a separate cart (identified by tenant_code)
class CartPersistenceService {
  static const String _cartKeyPrefix = 'cart_';
  
  /// Save cart to local storage
  /// 
  /// [tenantCode] - Tenant identifier (e.g., "Q8L2PH")
  /// [items] - List of cart items to save
  Future<void> saveCart(String tenantCode, List<CartItemModel> items) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_cartKeyPrefix$tenantCode';
    
    final json = jsonEncode(
      items.map((item) => item.toJson()).toList()
    );
    
    await prefs.setString(key, json);
  }
  
  /// Load cart from local storage
  /// 
  /// [tenantCode] - Tenant identifier (e.g., "Q8L2PH")
  /// Returns list of cart items, empty list if no cart exists
  Future<List<CartItemModel>> loadCart(String tenantCode) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_cartKeyPrefix$tenantCode';
    
    final json = prefs.getString(key);
    if (json == null) return [];
    
    try {
      final List<dynamic> decoded = jsonDecode(json);
      return decoded.map((e) => CartItemModel.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      // If JSON is corrupted, return empty cart
      if (kDebugMode) print('Error loading cart: $e');
      return [];
    }
  }
  
  /// Clear cart after successful order
  /// 
  /// [tenantCode] - Tenant identifier (e.g., "Q8L2PH")
  Future<void> clearCart(String tenantCode) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_cartKeyPrefix$tenantCode';
    await prefs.remove(key);
  }
  
  /// Get total item count in cart (sum of quantities)
  /// 
  /// [tenantCode] - Tenant identifier (e.g., "Q8L2PH")
  /// Returns total quantity of all items
  Future<int> getCartCount(String tenantCode) async {
    final items = await loadCart(tenantCode);
    return items.fold(0, (sum, item) => sum + item.quantity);
  }
  
  /// Get total price of all items in cart
  /// 
  /// [tenantCode] - Tenant identifier (e.g., "Q8L2PH")
  /// Returns total price in Rupiah
  Future<int> getCartTotal(String tenantCode) async {
    final items = await loadCart(tenantCode);
    return items.fold(0, (sum, item) => sum + item.subtotal);
  }
  
  /// Check if cart has items
  /// 
  /// [tenantCode] - Tenant identifier (e.g., "Q8L2PH")
  Future<bool> hasItems(String tenantCode) async {
    final count = await getCartCount(tenantCode);
    return count > 0;
  }
  
  /// Clear all carts (for testing/debugging)
  /// 
  /// ⚠️ Use with caution! Removes ALL tenant carts
  Future<void> clearAllCarts() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    
    for (var key in keys) {
      if (key.startsWith(_cartKeyPrefix)) {
        await prefs.remove(key);
      }
    }
  }
}
