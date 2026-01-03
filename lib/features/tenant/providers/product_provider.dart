import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/appwrite_provider.dart';
import '../../../shared/models/product_model.dart';
import '../data/product_repository.dart';
import '../../auth/providers/auth_provider.dart';

/// Provider for ProductRepository
final productRepositoryProvider = Provider<ProductRepository>((ref) {
  final databases = ref.watch(appwriteDatabasesProvider);
  final storage = ref.watch(appwriteStorageProvider);
  return ProductRepository(databases, storage);
});

/// State class for products
class ProductState {
  final List<ProductModel> products;
  final bool isLoading;
  final String? error;

  ProductState({
    this.products = const [],
    this.isLoading = false,
    this.error,
  });

  ProductState copyWith({
    List<ProductModel>? products,
    bool? isLoading,
    String? error,
  }) {
    return ProductState(
      products: products ?? this.products,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// StateNotifier for managing products
class ProductNotifier extends StateNotifier<ProductState> {
  final ProductRepository _repository;
  final String tenantId;
  final AuthNotifier? authNotifier;

  ProductNotifier(this._repository, this.tenantId, {this.authNotifier}) : super(ProductState());

  /// Load all products for the tenant
  Future<void> loadProducts() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final products = await _repository.getProductsByTenant(tenantId);
      state = state.copyWith(
        products: products,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Load products by category
  Future<void> loadProductsByCategory(String categoryId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final products = await _repository.getProductsByCategory(
        tenantId,
        categoryId,
      );
      state = state.copyWith(
        products: products,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Create a new product
  Future<bool> createProduct({
    required String categoryId,
    required String name,
    String? description,
    required int price,
    String? imageUrl,
    bool isAvailable = true,
    int? stock,
    int displayOrder = 0,
  }) async {
    // 🔒 FORCE CHECK: Verify user still active before critical operation
   if (authNotifier != null) {
if (kDebugMode) print('🔒 [FORCE CHECK] Verifying active status before CREATE product...');
      final deactivatedInfo = await authNotifier!.checkUserActiveStatus();
      if (deactivatedInfo != null) {
  if (kDebugMode) print('⚠️ [FORCE CHECK] User deactivated! Blocking create operation.');
  if (kDebugMode) print('🚪 [FORCE CHECK] Auto-logout triggered...');
        await authNotifier!.logout();
        return false;
      }
if (kDebugMode) print('✅ [FORCE CHECK] User active, proceeding with create...');
    }
    
    try {
      final product = await _repository.createProduct(
        tenantId: tenantId,
        categoryId: categoryId,
        name: name,
        description: description,
        price: price,
        imageUrl: imageUrl,
        isAvailable: isAvailable,
        stock: stock,
        displayOrder: displayOrder,
      );

      state = state.copyWith(
        products: [...state.products, product],
      );

      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Update a product
  Future<bool> updateProduct({
    required String productId,
    String? categoryId,
    String? name,
    String? description,
    int? price,
    String? imageUrl,
    bool? isAvailable,
    int? stock,
    int? displayOrder,
  }) async {
    // 🔒 FORCE CHECK: Verify user still active before critical operation
    if (authNotifier != null) {
if (kDebugMode) print('🔒 [FORCE CHECK] Verifying active status before UPDATE product...');
      final deactivatedInfo = await authNotifier!.checkUserActiveStatus();
      if (deactivatedInfo != null) {
  if (kDebugMode) print('⚠️ [FORCE CHECK] User deactivated! Blocking update operation.');
  if (kDebugMode) print('🚪 [FORCE CHECK] Auto-logout triggered...');
        await authNotifier!.logout();
        return false;
      }
if (kDebugMode) print('✅ [FORCE CHECK] User active, proceeding with update...');
    }
    
    try {
      final updatedProduct = await _repository.updateProduct(
        productId: productId,
        categoryId: categoryId,
        name: name,
        description: description,
        price: price,
        imageUrl: imageUrl,
        isAvailable: isAvailable,
        stock: stock,
        displayOrder: displayOrder,
      );

      state = state.copyWith(
        products: state.products.map((prod) {
          return prod.id == productId ? updatedProduct : prod;
        }).toList(),
      );

      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Delete a product
  Future<bool> deleteProduct(String productId) async {
    // 🔒 FORCE CHECK: Verify user still active before critical operation
    if (authNotifier != null) {
if (kDebugMode) print('🔒 [FORCE CHECK] Verifying active status before DELETE product...');
      final deactivatedInfo = await authNotifier!.checkUserActiveStatus();
      if (deactivatedInfo != null) {
  if (kDebugMode) print('⚠️ [FORCE CHECK] User deactivated! Blocking delete operation.');
  if (kDebugMode) print('🚪 [FORCE CHECK] Auto-logout triggered...');
        await authNotifier!.logout();
        return false;
      }
if (kDebugMode) print('✅ [FORCE CHECK] User active, proceeding with delete...');
    }
    
    try {
      await _repository.deleteProduct(productId);

      state = state.copyWith(
        products: state.products
            .where((prod) => prod.id != productId)
            .toList(),
      );

      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Toggle product availability
  Future<bool> toggleProductAvailability(
    String productId,
    bool isAvailable,
  ) async {
    try {
      final updatedProduct = await _repository.toggleProductAvailability(
        productId,
        isAvailable,
      );

      state = state.copyWith(
        products: state.products.map((prod) {
          return prod.id == productId ? updatedProduct : prod;
        }).toList(),
      );

      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Update product stock
  Future<bool> updateStock(String productId, int stock) async {
    try {
      final updatedProduct = await _repository.updateStock(productId, stock);

      state = state.copyWith(
        products: state.products.map((prod) {
          return prod.id == productId ? updatedProduct : prod;
        }).toList(),
      );

      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }
}

/// Provider for tenant products
/// Requires tenant ID parameter
final tenantProductsProvider = StateNotifierProvider.family<
    ProductNotifier,
    ProductState,
    String>((ref, tenantId) {
  final repository = ref.watch(productRepositoryProvider);
  final authNotifier = ref.watch(authProvider.notifier);
  return ProductNotifier(repository, tenantId, authNotifier: authNotifier);
});
