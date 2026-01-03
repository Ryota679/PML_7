import 'package:appwrite/appwrite.dart';
import '../../../core/config/appwrite_config.dart';
import '../../../core/utils/app_logger.dart';
import '../../../core/services/api_error_interceptor.dart';
import '../../../shared/models/product_model.dart';
import '../../../core/services/image_upload_service.dart';

/// Repository for managing products
class ProductRepository {
  final Databases _databases;
  final Storage _storage;

  ProductRepository(this._databases, this._storage);

  /// Get all products for a specific tenant
  Future<List<ProductModel>> getProductsByTenant(String tenantId) async {
    try {
      AppLogger.info('Fetching products for tenant: $tenantId');

      final response = await ApiErrorInterceptor.wrapApiCall(
        apiCall: () => _databases.listDocuments(
          databaseId: AppwriteConfig.databaseId,
          collectionId: AppwriteConfig.productsCollectionId,
          queries: [
            Query.equal('tenant_id', tenantId),
            Query.orderAsc('display_order'),
            Query.orderAsc('name'),
            Query.limit(100),
          ],
        ),
        context: 'Get Products',
      );

      final products = response.documents
          .map((doc) => ProductModel.fromDocument(doc))
          .toList();

      AppLogger.info('Found ${products.length} products');
      return products;
    } catch (e, stackTrace) {
      AppLogger.error('Error fetching products', e, stackTrace);
      rethrow;
    }
  }

  /// Get products by category
  Future<List<ProductModel>> getProductsByCategory(
    String tenantId,
    String categoryId,
  ) async {
    try {
      AppLogger.info('Fetching products for category: $categoryId');

      final response = await ApiErrorInterceptor.wrapApiCall(
        apiCall: () => _databases.listDocuments(
          databaseId: AppwriteConfig.databaseId,
          collectionId: AppwriteConfig.productsCollectionId,
          queries: [
            Query.equal('tenant_id', tenantId),
            Query.equal('category_id', categoryId),
            Query.equal('is_active', true),
            Query.orderAsc('display_order'),
            Query.orderAsc('name'),
            Query.limit(100),
          ],
        ),
        context: 'Get Products by Category',
      );

      final products = response.documents
          .map((doc) => ProductModel.fromDocument(doc))
          .toList();

      AppLogger.info('Found ${products.length} products in category');
      return products;
    } catch (e, stackTrace) {
      AppLogger.error('Error fetching products by category', e, stackTrace);
      rethrow;
    }
  }

  /// Create a new product
  Future<ProductModel> createProduct({
    required String tenantId,
    required String categoryId,
    required String name,
    String? description,
    required int price,
    String? imageUrl,
    bool isAvailable = true,
    bool isActive = true,
    int? stock,
    int displayOrder = 0,
  }) async {
    try {
      AppLogger.info('Creating product: $name for tenant: $tenantId');

      final response = await ApiErrorInterceptor.wrapApiCall(
        apiCall: () => _databases.createDocument(
          databaseId: AppwriteConfig.databaseId,
          collectionId: AppwriteConfig.productsCollectionId,
          documentId: ID.unique(),
          data: {
            'tenant_id': tenantId,
            'category_id': categoryId,
            'name': name,
            'description': description,
            'price': price,
            'image_url': imageUrl,
            'is_available': isAvailable,
            'is_active': isActive,
            'stock': stock,
            'display_order': displayOrder,
          },
          // No document-level permissions - rely on collection permissions (Users role)
        ),
        context: 'Create Product',
      );

      final product = ProductModel.fromDocument(response);
      AppLogger.info('Product created successfully: ${product.id}');
      return product;
    } catch (e, stackTrace) {
      AppLogger.error('Error creating product', e, stackTrace);
      rethrow;
    }
  }

  /// Update an existing product
  Future<ProductModel> updateProduct({
    required String productId,
    String? categoryId,
    String? name,
    String? description,
    int? price,
    String? imageUrl,
    bool? isAvailable,
    bool? isActive,
    int? stock,
    int? displayOrder,
  }) async {
    try {
      AppLogger.info('Updating product: $productId');

      final data = <String, dynamic>{};
      if (categoryId != null) data['category_id'] = categoryId;
      if (name != null) data['name'] = name;
      if (description != null) data['description'] = description;
      if (price != null) data['price'] = price;
      if (imageUrl != null) data['image_url'] = imageUrl;
      if (isAvailable != null) data['is_available'] = isAvailable;
      if (isActive != null) data['is_active'] = isActive;
      if (stock != null) data['stock'] = stock;
      if (displayOrder != null) data['display_order'] = displayOrder;

      final response = await ApiErrorInterceptor.wrapApiCall(
        apiCall: () => _databases.updateDocument(
          databaseId: AppwriteConfig.databaseId,
          collectionId: AppwriteConfig.productsCollectionId,
          documentId: productId,
          data: data,
        ),
        context: 'Update Product',
      );

      final product = ProductModel.fromDocument(response);
      AppLogger.info('Product updated successfully');
      return product;
    } catch (e, stackTrace) {
      AppLogger.error('Error updating product', e, stackTrace);
      rethrow;
    }
  }

  /// Delete a product and its associated image from storage
  Future<void> deleteProduct(String productId) async {
    try {
      AppLogger.info('Deleting product: $productId');

      // Step 1: Get product data to check for image
      final product = await ApiErrorInterceptor.wrapApiCall(
        apiCall: () => _databases.getDocument(
          databaseId: AppwriteConfig.databaseId,
          collectionId: AppwriteConfig.productsCollectionId,
          documentId: productId,
        ),
        context: 'Get Product for Deletion',
      );

      final productModel = ProductModel.fromDocument(product);

      // Step 2: Delete image from storage if it exists
      if (productModel.imageUrl != null && productModel.imageUrl!.isNotEmpty) {
        try {
          final fileId = _extractFileIdFromUrl(productModel.imageUrl!);
          if (fileId != null) {
            AppLogger.info('Deleting image from storage: $fileId');
            await _storage.deleteFile(
              bucketId: AppwriteConfig.productImagesBucketId,
              fileId: fileId,
            );
            AppLogger.info('✅ Image deleted from storage');
          }
        } catch (e) {
          // Log error but continue with product deletion
          AppLogger.warning('Failed to delete image from storage: $e');
        }
      }

      // Step 3: Delete product from database
      await ApiErrorInterceptor.wrapApiCall(
        apiCall: () => _databases.deleteDocument(
          databaseId: AppwriteConfig.databaseId,
          collectionId: AppwriteConfig.productsCollectionId,
          documentId: productId,
        ),
        context: 'Delete Product',
      );

      AppLogger.info('✅ Product deleted successfully');
    } catch (e, stackTrace) {
      AppLogger.error('Error deleting product', e, stackTrace);
      rethrow;
    }
  }

  /// Extract file ID from Appwrite storage URL
  /// Format: https://cloud.appwrite.io/v1/storage/buckets/[bucketId]/files/[fileId]/view?project=[projectId]
  String? _extractFileIdFromUrl(String url) {
    try {
      // Check if URL is from Appwrite storage
      if (!url.contains('storage/buckets')) {
        AppLogger.info('URL is not from Appwrite storage, skipping delete');
        return null;
      }

      // Extract fileId from URL
      final uri = Uri.parse(url);
      final pathSegments = uri.pathSegments;
      
      // Find 'files' segment and get the next one (fileId)
      final filesIndex = pathSegments.indexOf('files');
      if (filesIndex != -1 && filesIndex + 1 < pathSegments.length) {
        final fileId = pathSegments[filesIndex + 1];
        AppLogger.info('Extracted fileId: $fileId');
        return fileId;
      }

      return null;
    } catch (e) {
      AppLogger.warning('Failed to extract fileId from URL: $e');
      return null;
    }
  }

  /// Toggle product availability
  Future<ProductModel> toggleProductAvailability(
    String productId,
    bool isAvailable,
  ) async {
    return updateProduct(productId: productId, isAvailable: isAvailable);
  }

  /// Update product stock
  Future<ProductModel> updateStock(String productId, int stock) async {
    return updateProduct(productId: productId, stock: stock);
  }
}
