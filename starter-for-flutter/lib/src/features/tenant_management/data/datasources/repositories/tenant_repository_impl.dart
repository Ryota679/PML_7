// KODE LENGKAP & FINAL v2

import 'dart:convert';
import 'package:appwrite/appwrite.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart'; // Added for debugPrint

import 'package:kantin_app/src/core/api/appwrite_client.dart'; 
import 'package:kantin_app/src/features/tenant_management/domain/repositories/tenant_repository.dart';
import 'package:kantin_app/src/core/constants/app_constants.dart';
import 'package:appwrite/models.dart';

final tenantRepositoryProvider = Provider<TenantRepository>((ref) {
  final functions = ref.watch(appwriteFunctionsProvider);
  final databases = ref.watch(appwriteDatabaseProvider);
  return TenantRepositoryImpl(functions, databases);
});

class TenantRepositoryImpl implements TenantRepository {
  final Functions _functions;
  final Databases _databases;

  TenantRepositoryImpl(this._functions, this._databases);

  @override
  Future<Map<String, dynamic>> createTenant({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final payload = {
        'tenantName': name,
        'tenantEmail': email,
        'tenantPassword': password,
      };
      
      final String body = jsonEncode(payload);

      // --- LOG DEBUGGING TAMBAHAN ---
      debugPrint('Mengirim ke fungsi: ${AppConstants.functionCreateTenant}');
      debugPrint('Dengan body: $body');
      // -----------------------------

      final execution = await _functions.createExecution(
        functionId: AppConstants.functionCreateTenant,
        body: body,
        headers: {
          'Content-Type': 'application/json',
        },
      );
      
      if (execution.status == 'completed') {
        final responseData = jsonDecode(execution.responseBody);
        
        if (responseData['success'] == false) {
          throw Exception(responseData['message'] ?? 'Function returned an error');
        }
        return responseData as Map<String, dynamic>;
      } else {
        try {
          final errorData = jsonDecode(execution.responseBody);
          final errorMessage = errorData['message'] as String? ?? 'Function execution failed';
          throw Exception(errorMessage);
        } catch (_) {
          throw Exception('Function failed with status: ${execution.status}');
        }
      }
    } on AppwriteException catch (e) {
      throw Exception(e.message ?? 'Unknown Appwrite error');
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }

  @override
  Future<DocumentList> getTenants() async {
    try {
      final response = await _databases.listDocuments(
        databaseId: AppConstants.databaseId,
        collectionId: AppConstants.tenantsCollectionId,
      );
      return response;
    } on AppwriteException catch (e) {
      throw Exception(e.message ?? 'Unknown Appwrite error');
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }

  @override
  Future<Document?> getTenantByOwner(String userId) async {
    try {
      // Untuk tenant: cari tenant berdasarkan userId (ID user tenant)
      final response = await _databases.listDocuments(
        databaseId: AppConstants.databaseId,
        collectionId: AppConstants.tenantsCollectionId,
        queries: [Query.equal('userId', userId)], // Cari berdasarkan userId (ID user tenant)
      );
      if (response.documents.isNotEmpty) {
        return response.documents.first;
      }
      return null;
    } on AppwriteException catch (e) {
      throw Exception(e.message ?? 'Unknown Appwrite error');
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }

  @override
  Future<DocumentList> getTenantsByBusinessOwner(String businessOwnerId) async {
    try {
      // Untuk business owner: cari semua tenant berdasarkan owner_user_id (ID business owner)
      final response = await _databases.listDocuments(
        databaseId: AppConstants.databaseId,
        collectionId: AppConstants.tenantsCollectionId,
        queries: [Query.equal('owner_user_id', businessOwnerId)], // Cari berdasarkan owner_user_id (ID business owner)
      );
      return response;
    } on AppwriteException catch (e) {
      throw Exception(e.message ?? 'Unknown Appwrite error');
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }

  @override
  Future<Document> getTenantById(String tenantId) async {
    try {
      return await _databases.getDocument(
        databaseId: AppConstants.databaseId,
        collectionId: AppConstants.tenantsCollectionId,
        documentId: tenantId,
      );
    } on AppwriteException catch (e) {
      throw Exception(e.message ?? 'Unknown Appwrite error');
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }

  @override
  Future<Document> updateTenant({
    required String tenantId,
    String? name,
    String? logoUrl,
    String? description,
    String? status,
  }) async {
    try {
      // Hanya update field yang tidak null
      final Map<String, dynamic> updateData = {};
      if (name != null) updateData['name'] = name;
      if (logoUrl != null) updateData['logoUrl'] = logoUrl;
      if (description != null) updateData['description'] = description;
      if (status != null) updateData['status'] = status;

      if (updateData.isEmpty) {
        throw Exception('Tidak ada data yang akan diupdate');
      }

      return await _databases.updateDocument(
        databaseId: AppConstants.databaseId,
        collectionId: AppConstants.tenantsCollectionId,
        documentId: tenantId,
        data: updateData,
      );
    } on AppwriteException catch (e) {
      throw Exception(e.message ?? 'Unknown Appwrite error');
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }
}