import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' show Document;
import 'package:kantin_app/config/environment.dart';

class ProductRepository {
  final Databases _databases;

  ProductRepository(Client client) : _databases = Databases(client);

  Future<List<Document>> getProducts(String tenantId) async {
    final response = await _databases.listDocuments(
      databaseId: Environment.appwriteDatabaseId,
      collectionId: 'products',
      queries: [Query.equal('tenantId', tenantId)],
    );
    return response.documents;
  }

  Future<void> createProduct(String name, double price, String categoryId, String tenantId) async {
    await _databases.createDocument(
      databaseId: Environment.appwriteDatabaseId,
      collectionId: 'products',
      documentId: ID.unique(),
      data: {
        'name': name,
        'price': price,
        'categoryId': categoryId,
        'tenantId': tenantId,
        'isAvailable': true,
      },
    );
  }

  Future<void> updateProduct(String productId, {required Map<String, dynamic> data}) async {
    await _databases.updateDocument(
      databaseId: Environment.appwriteDatabaseId,
      collectionId: 'products',
      documentId: productId,
      data: data,
    );
  }

  Future<void> deleteProduct(String productId) async {
    await _databases.deleteDocument(
      databaseId: Environment.appwriteDatabaseId,
      collectionId: 'products',
      documentId: productId,
    );
  }
}
