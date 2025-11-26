/// Appwrite Configuration
/// 
/// Konfigurasi koneksi ke Appwrite backend
class AppwriteConfig {
  // Appwrite Server Configuration
  static const String endpoint = 'https://fra.cloud.appwrite.io/v1';
  static const String projectId = 'perojek-pml';
  static const String databaseId = 'kantin-db';
  
  // API Key for Server Operations (Admin Only)
  // ⚠️ SECURITY WARNING: This should be moved to environment variables or Appwrite Functions
  // For MVP/Development only - DO NOT expose in production!
  // Create API key in Appwrite Console: Settings → API Keys
  // Required scopes: users.write
  static const String serverApiKey = 'standard_9d167733ad351429a14b1ac9d6937670cc8c5a626643f187d47a8260ba064000cb55bebc669f478b5041141f2b7e1d1bc5dad2ca7310cdb5e7dfd22fa8399ac6245c2b397d7b5d4400d57233929e9ca584382a8f0d1623725007d15974365e3a85421685c46c0aa2a92427e0a3dbb241b89e6fc054e45d8ace5c3d24d165b2b5';  // REPLACE THIS!
  
  // Collection IDs
  static const String usersCollectionId = 'users';
  static const String tenantsCollectionId = 'tenants';
  static const String productsCollectionId = 'products';
  static const String categoriesCollectionId = 'categories';
  static const String ordersCollectionId = 'orders';
  static const String registrationRequestsCollectionId = 'registration_requests';
  
  // Appwrite Function IDs
  static const String approveRegistrationFunctionId = '691d57860017535b860c';
  static const String createTenantUserFunctionId = 'createTenantUser';

  // Storage Bucket IDs
  static const String productImagesBucketId = 'product-images';
}
