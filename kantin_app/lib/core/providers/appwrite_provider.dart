import 'package:appwrite/appwrite.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/appwrite_config.dart';

/// Provider for Appwrite Client
final appwriteClientProvider = Provider<Client>((ref) {
  final client = Client()
      .setEndpoint(AppwriteConfig.endpoint)
      .setProject(AppwriteConfig.projectId);
  return client;
});

/// Provider for Appwrite Account
final appwriteAccountProvider = Provider<Account>((ref) {
  final client = ref.watch(appwriteClientProvider);
  return Account(client);
});

/// Provider for Appwrite Databases
final appwriteDatabasesProvider = Provider<Databases>((ref) {
  final client = ref.watch(appwriteClientProvider);
  return Databases(client);
});

/// Provider for Appwrite Storage
final appwriteStorageProvider = Provider<Storage>((ref) {
  final client = ref.watch(appwriteClientProvider);
  return Storage(client);
});

/// Provider for Appwrite Functions
final appwriteFunctionsProvider = Provider<Functions>((ref) {
  final client = ref.watch(appwriteClientProvider);
  return Functions(client);
});

/// Provider for Appwrite Realtime
final realtimeProvider = Provider<Realtime>((ref) {
  final client = ref.watch(appwriteClientProvider);
  return Realtime(client);
});

// Alias for consistency
final databasesProvider = appwriteDatabasesProvider;
final storageProvider = appwriteStorageProvider;
final accountProvider = appwriteAccountProvider;
