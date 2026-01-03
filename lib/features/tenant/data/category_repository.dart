import 'package:appwrite/appwrite.dart';
import '../../../core/config/appwrite_config.dart';
import '../../../core/utils/app_logger.dart';
import '../../../core/services/api_error_interceptor.dart';
import '../../../shared/models/category_model.dart';

/// Repository for managing product categories
class CategoryRepository {
  final Databases _databases;

  CategoryRepository(this._databases);

  /// Get all categories for a specific tenant
  Future<List<CategoryModel>> getCategoriesByTenant(String tenantId) async {
    try {
      AppLogger.info('Fetching categories for tenant: $tenantId');

      final response = await ApiErrorInterceptor.wrapApiCall(
        apiCall: () => _databases.listDocuments(
          databaseId: AppwriteConfig.databaseId,
          collectionId: AppwriteConfig.categoriesCollectionId,
          queries: [
            Query.equal('tenant_id', tenantId),
            Query.equal('is_active', true),
            Query.orderAsc('display_order'),
            Query.orderAsc('name'),
            Query.limit(100),
          ],
        ),
        context: 'Get Categories',
      );

      final categories = response.documents
          .map((doc) => CategoryModel.fromDocument(doc))
          .toList();

      AppLogger.info('Found ${categories.length} categories');
      return categories;
    } catch (e, stackTrace) {
      AppLogger.error('Error fetching categories', e, stackTrace);
      rethrow;
    }
  }

  /// Create a new category
  Future<CategoryModel> createCategory({
    required String tenantId,
    required String name,
    String? description,
    String? icon,
    int displayOrder = 0,
  }) async {
    try {
      AppLogger.info('Creating category: $name for tenant: $tenantId');

      final response = await ApiErrorInterceptor.wrapApiCall(
        apiCall: () => _databases.createDocument(
          databaseId: AppwriteConfig.databaseId,
          collectionId: AppwriteConfig.categoriesCollectionId,
          documentId: ID.unique(),
          data: {
            'tenant_id': tenantId,
            'name': name,
            'description': description,
            'icon': icon,
            'display_order': displayOrder,
            'is_active': true,
          },
        ),
        context: 'Create Category',
      );

      final category = CategoryModel.fromDocument(response);
      AppLogger.info('Category created successfully: ${category.id}');
      return category;
    } catch (e, stackTrace) {
      AppLogger.error('Error creating category', e, stackTrace);
      rethrow;
    }
  }

  /// Update an existing category
  Future<CategoryModel> updateCategory({
    required String categoryId,
    String? name,
    String? description,
    String? icon,
    int? displayOrder,
    bool? isActive,
  }) async {
    try {
      AppLogger.info('Updating category: $categoryId');

      final data = <String, dynamic>{};
      if (name != null) data['name'] = name;
      if (description != null) data['description'] = description;
      if (icon != null) data['icon'] = icon;
      if (displayOrder != null) data['display_order'] = displayOrder;
      if (isActive != null) data['is_active'] = isActive;

      final response = await ApiErrorInterceptor.wrapApiCall(
        apiCall: () => _databases.updateDocument(
          databaseId: AppwriteConfig.databaseId,
          collectionId: AppwriteConfig.categoriesCollectionId,
          documentId: categoryId,
          data: data,
        ),
        context: 'Update Category',
      );

      final category = CategoryModel.fromDocument(response);
      AppLogger.info('Category updated successfully');
      return category;
    } catch (e, stackTrace) {
      AppLogger.error('Error updating category', e, stackTrace);
      rethrow;
    }
  }

  /// Delete a category
  Future<void> deleteCategory(String categoryId) async {
    try {
      AppLogger.info('Deleting category: $categoryId');

      await ApiErrorInterceptor.wrapApiCall(
        apiCall: () => _databases.deleteDocument(
          databaseId: AppwriteConfig.databaseId,
          collectionId: AppwriteConfig.categoriesCollectionId,
          documentId: categoryId,
        ),
        context: 'Delete Category',
      );

      AppLogger.info('Category deleted successfully');
    } catch (e, stackTrace) {
      AppLogger.error('Error deleting category', e, stackTrace);
      rethrow;
    }
  }

  /// Toggle category active status
  Future<CategoryModel> toggleCategoryStatus(
    String categoryId,
    bool isActive,
  ) async {
    return updateCategory(categoryId: categoryId, isActive: isActive);
  }
}
