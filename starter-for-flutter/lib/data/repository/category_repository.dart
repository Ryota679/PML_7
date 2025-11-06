import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' show Document;
import 'package:kantin_app/config/environment.dart';

class CategoryRepository {
  final Databases _databases;

  CategoryRepository(Client client) : _databases = Databases(client);

  Future<List<Document>> getCategories() async {
    final response = await _databases.listDocuments(
      databaseId: Environment.appwriteDatabaseId,
      collectionId: 'categories',
    );
    return response.documents;
  }

  Future<void> createCategory(String name) async {
    await _databases.createDocument(
      databaseId: Environment.appwriteDatabaseId,
      collectionId: 'categories',
      documentId: ID.unique(),
      data: {'name': name},
    );
  }
}
