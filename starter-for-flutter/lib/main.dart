import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:appwrite/appwrite.dart'; // Diperlukan untuk inisialisasi
import 'package:kantin_app/src/app.dart';
import 'package:kantin_app/src/core/constants/app_constants.dart'; // Import konstanta Anda

// --- LANGKAH PENTING: Inisialisasi Appwrite Client di Awal ---
// Kita membuat instance client di sini untuk memastikan hanya ada satu.
// Ini akan dimasukkan ke dalam Provider nanti.
final client = Client()
    .setEndpoint(AppConstants.endpoint)
    .setProject(AppConstants.projectId)
    .setSelfSigned(status: true); // Gunakan hanya untuk development (misal: localhost)
                                  // Hapus atau set 'false' untuk produksi.

void main() {
  // Pastikan semua widget Flutter siap sebelum menjalankan aplikasi.
  WidgetsFlutterBinding.ensureInitialized();
  
  runApp(
    ProviderScope(
      // Kita tidak perlu meng-override provider di sini karena
      // struktur provider kita sudah benar (menggunakan Provider biasa, bukan StateNotifierProvider
      // untuk client-nya). Kode yang Anda miliki sebelumnya sudah bagus.
      child: const MyApp(),
    ),
  );
}