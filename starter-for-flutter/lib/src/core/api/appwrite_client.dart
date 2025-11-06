import 'package:appwrite/appwrite.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_app/src/core/constants/app_constants.dart'; // Sesuaikan path import

// Provider ini hanya membuat instance Client
final appwriteClientProvider = Provider<Client>((ref) {
  Client client = Client();
  client
      .setEndpoint(AppConstants.endpoint)
      .setProject(AppConstants.projectId)
      .setSelfSigned(status: true); // Hanya untuk development, hapus di produksi
  return client;
});

// Provider ini untuk mengakses service Functions
final appwriteFunctionsProvider = Provider<Functions>((ref) {
  final client = ref.watch(appwriteClientProvider);
  return Functions(client);
});

// Provider ini untuk mengakses service Account (Auth)
final appwriteAccountProvider = Provider<Account>((ref) {
  final client = ref.watch(appwriteClientProvider);
  return Account(client);
});