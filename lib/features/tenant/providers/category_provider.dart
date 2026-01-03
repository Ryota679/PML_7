import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/appwrite_provider.dart';
import '../../../shared/models/category_model.dart';
import '../data/category_repository.dart';

/// Provider for CategoryRepository
final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  final databases = ref.watch(appwriteDatabasesProvider);
  return CategoryRepository(databases);
});

/// State class for categories
class CategoryState {
  final List<CategoryModel> categories;
  final bool isLoading;
  final String? error;

  CategoryState({
    this.categories = const [],
    this.isLoading = false,
    this.error,
  });

  CategoryState copyWith({
    List<CategoryModel>? categories,
    bool? isLoading,
    String? error,
  }) {
    return CategoryState(
      categories: categories ?? this.categories,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// StateNotifier for managing categories
class CategoryNotifier extends StateNotifier<CategoryState> {
  final CategoryRepository _repository;
  final String tenantId;

  CategoryNotifier(this._repository, this.tenantId) : super(CategoryState());

  /// Load categories for the tenant
  Future<void> loadCategories() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final categories = await _repository.getCategoriesByTenant(tenantId);
      state = state.copyWith(
        categories: categories,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Create a new category
  Future<bool> createCategory({
    required String name,
    String? description,
    String? icon,
    int displayOrder = 0,
  }) async {
    try {
      final category = await _repository.createCategory(
        tenantId: tenantId,
        name: name,
        description: description,
        icon: icon,
        displayOrder: displayOrder,
      );

      state = state.copyWith(
        categories: [...state.categories, category],
      );

      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Update a category
  Future<bool> updateCategory({
    required String categoryId,
    String? name,
    String? description,
    String? icon,
    int? displayOrder,
  }) async {
    try {
      final updatedCategory = await _repository.updateCategory(
        categoryId: categoryId,
        name: name,
        description: description,
        icon: icon,
        displayOrder: displayOrder,
      );

      state = state.copyWith(
        categories: state.categories.map((cat) {
          return cat.id == categoryId ? updatedCategory : cat;
        }).toList(),
      );

      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Delete a category
  Future<bool> deleteCategory(String categoryId) async {
    try {
      await _repository.deleteCategory(categoryId);

      state = state.copyWith(
        categories: state.categories
            .where((cat) => cat.id != categoryId)
            .toList(),
      );

      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Toggle category active status
  Future<bool> toggleCategoryStatus(String categoryId, bool isActive) async {
    try {
      final updatedCategory = await _repository.toggleCategoryStatus(
        categoryId,
        isActive,
      );

      state = state.copyWith(
        categories: state.categories.map((cat) {
          return cat.id == categoryId ? updatedCategory : cat;
        }).toList(),
      );

      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }
}

/// Provider for tenant categories
/// Requires tenant ID parameter
final tenantCategoriesProvider = StateNotifierProvider.family<
    CategoryNotifier,
    CategoryState,
    String>((ref, tenantId) {
  final repository = ref.watch(categoryRepositoryProvider);
  return CategoryNotifier(repository, tenantId);
});
