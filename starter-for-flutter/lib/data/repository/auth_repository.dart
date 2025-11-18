import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' show User;

class AuthRepository {
  final Account _account;
  final Databases _databases; // <-- 1. TAMBAHKAN INI

  // Perbarui constructor untuk menginisialisasi _databases
  AuthRepository(Client client)
      : _account = Account(client),
        _databases = Databases(client); // <-- 2. TAMBAHKAN INI

  /// FUNGSI BARU UNTUK MEMBUAT TENANT
  /// Fungsi ini akan:
  /// 1. Membuat user baru di Appwrite Auth.
  /// 2. Jika berhasil, mengambil ID user tersebut.
  /// 3. Membuat dokumen baru di koleksi 'tenants' dengan ID user sebagai 'owner_user_id'.
  Future<void> createTenant({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      // Langkah 1: Buat user di Auth dan dapatkan hasilnya
      final user = await _account.create(
        userId: ID.unique(),
        email: email,
        password: password,
        name: name,
      );

      // Langkah 2: Buat dokumen di database setelah user berhasil dibuat
      await _databases.createDocument(
        // GANTI DENGAN ID DATABASE ANDA
        databaseId: 'kantin-db',
        // ID Koleksi tenants
        collectionId: 'tenants',
        // Buat ID dokumen yang unik
        documentId: ID.unique(),
        // Data yang dikirim ke database - sesuai dengan schema di data.md
        data: {
          'name': name,
          'logoUrl':
              'https://img.ly/30', // Placeholder URL default (size <= 30)
          'owner_user_id': user
              .$id, // <-- PENTING: Mengirim ID user (sesuai schema di data.md)
          'description': null, // Optional
          'status': null, // Optional
          'userId': user.$id, // Optional: ID user tenant
          'qrCodeUrl': null, // Optional, akan di-set nanti jika diperlukan
        },
        permissions: [
          // (Opsional) Berikan hak akses, contoh: user hanya bisa baca/tulis datanya sendiri
          Permission.read(Role.user(user.$id)),
          Permission.update(Role.user(user.$id)),
          Permission.delete(Role.user(user.$id)),
        ],
      );
    } on AppwriteException catch (e) {
      // Jika terjadi error, tampilkan pesan yang lebih jelas
      // Anda bisa menangani error ini di UI
      throw Exception('Gagal membuat tenant: ${e.message}');
    }
  }

  // --- FUNGSI-FUNGSI YANG SUDAH ADA (TIDAK BERUBAH) ---

  Future<void> login(String email, String password) async {
    try {
      await logout();
    } catch (e) {
      // Ignore errors from logout, as it's possible no session exists.
    }
    await _account.createEmailPasswordSession(
      email: email,
      password: password,
    );
  }

  Future<void> logout() async {
    await _account.deleteSession(sessionId: 'current');
  }

  Future<User> getAccount() async {
    return await _account.get();
  }
}
