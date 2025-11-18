import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' show Document;
import 'package:kantin_app/config/environment.dart';
import 'package:flutter/foundation.dart'; // Added for debugPrint

class TenantRepository {
  final Databases _databases;
  final Functions _functions;

  TenantRepository(Client client) : _databases = Databases(client), _functions = Functions(client);

  Future<void> createTenant(String name, String email, String password) async {
    try {
      await _functions.createExecution(
        functionId: 'createTenant', // ID fungsi yang benar
        body:
            '{"tenantName": "$name", "tenantEmail": "$email", "tenantPassword": "$password"}',
        headers: {'Content-Type': 'application/json'},
      );
    } on AppwriteException catch (e) {
      // Lemparkan kembali pengecualian agar UI dapat menanganinya
      debugPrint('Error in createTenant: ${e.message}');
      rethrow;
    }
  }

  Future<Document?> getTenantByOwner(String userId) async {
    final response = await _databases.listDocuments(
      databaseId: Environment.appwriteDatabaseId,
      collectionId: 'tenants',
      queries: [Query.equal('business_owner_id', userId)],
    );
    if (response.documents.isNotEmpty) {
      return response.documents.first;
    }
    return null;
  }

  Future<Document> getTenantById(String tenantId) async {
    return await _databases.getDocument(
      databaseId: Environment.appwriteDatabaseId,
      collectionId: 'tenants',
      documentId: tenantId,
    );
  }
}
