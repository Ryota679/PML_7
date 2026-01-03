import 'package:appwrite/appwrite.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_app/core/config/appwrite_config.dart';

/// Appwrite Client Provider
/// 
/// Singleton provider untuk Appwrite Client
final appwriteClientProvider = Provider<Client>((ref) {
  final client = Client()
      .setEndpoint(AppwriteConfig.endpoint)
      .setProject(AppwriteConfig.projectId);
  
  return client;
});

/// Appwrite Account Provider
/// 
/// Provider untuk Appwrite Account service (Authentication)
final appwriteAccountProvider = Provider<Account>((ref) {
  final client = ref.watch(appwriteClientProvider);
  return Account(client);
});

/// Appwrite Database Provider
/// 
/// Provider untuk Appwrite Database service
final appwriteDatabaseProvider = Provider<Databases>((ref) {
  final client = ref.watch(appwriteClientProvider);
  return Databases(client);
});

/// Appwrite Realtime Provider
/// 
/// Provider untuk Appwrite Realtime service
final appwriteRealtimeProvider = Provider<Realtime>((ref) {
  final client = ref.watch(appwriteClientProvider);
  return Realtime(client);
});

/// Appwrite Functions Provider
/// 
/// Provider untuk Appwrite Functions service
final appwriteFunctionsProvider = Provider<Functions>((ref) {
  final client = ref.watch(appwriteClientProvider);
  return Functions(client);
});
