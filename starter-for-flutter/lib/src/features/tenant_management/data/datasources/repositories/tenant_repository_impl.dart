// KODE LENGKAP & FINAL v2

import 'dart:convert';
import 'package:appwrite/appwrite.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart'; // Added for debugPrint

import 'package:kantin_app/src/core/api/appwrite_client.dart'; 
import 'package:kantin_app/src/features/tenant_management/domain/repositories/tenant_repository.dart';
import 'package:kantin_app/src/core/constants/app_constants.dart';

final tenantRepositoryProvider = Provider<TenantRepository>((ref) {
  final functions = ref.watch(appwriteFunctionsProvider);
  return TenantRepositoryImpl(functions);
});

class TenantRepositoryImpl implements TenantRepository {
  final Functions _functions;

  TenantRepositoryImpl(this._functions);

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
}