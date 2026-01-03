/// Appwrite Configuration
/// 
/// Konfigurasi koneksi ke Appwrite backend
class AppwriteConfig {
  // Appwrite Server Configuration
  static const String endpoint = 'https://fra.cloud.appwrite.io/v1';
  static const String projectId = 'perojek-pml';
  static const String databaseId = 'kantin-db';
  
  // ⚠️ SECURITY: API Key removed from source code
  // Server operations now use Appwrite Functions (server-side)
  // API keys should NEVER be in client-side code!
  // See: functions/create-user, functions/delete-user for implementation
  
  // Collection IDs
  static const String usersCollectionId = 'users';
  static const String tenantsCollectionId = 'tenants';
  static const String productsCollectionId = 'products';
  static const String categoriesCollectionId = 'categories';
  static const String ordersCollectionId = 'orders';
  static const String orderItemsCollectionId = 'order_items';
  static const String registrationRequestsCollectionId = 'registration_requests';
  static const String invitationCodesCollectionId = 'invitation_codes'; // NEW: OAuth/Freemium

  
  // Appwrite Function IDs
  static const String approveRegistrationFunctionId = '691d57860017535b860c';
  static const String createUserFunctionId = 'create-user'; // Combined function for staff and tenant users
  static const String deleteUserFunctionId = 'delete-user'; // Delete user with cascading cleanup

  // Storage Bucket IDs
  static const String productImagesBucketId = 'product-images';
}
