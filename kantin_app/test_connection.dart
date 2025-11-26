import 'package:appwrite/appwrite.dart';
import 'package:kantin_app/core/config/appwrite_config.dart';

/// Test Connection to Appwrite
/// 
/// File untuk testing koneksi ke Appwrite database
/// Run dengan: dart run test_connection.dart
void main() async {
  print('🔄 Testing Appwrite Connection...\n');

  try {
    // Initialize Appwrite Client
    final client = Client()
        .setEndpoint(AppwriteConfig.endpoint)
        .setProject(AppwriteConfig.projectId);

    print('✅ Endpoint: ${AppwriteConfig.endpoint}');
    print('✅ Project ID: ${AppwriteConfig.projectId}');
    print('✅ Database ID: ${AppwriteConfig.databaseId}\n');

    // Test Database Connection
    final databases = Databases(client);
    
    print('🔄 Testing database connection...');
    
    // Try to list collections
    try {
      final collections = await databases.listCollections(
        databaseId: AppwriteConfig.databaseId,
      );
      
      print('✅ Database connected successfully!');
      print('📊 Found ${collections.total} collection(s):\n');
      
      for (var collection in collections.collections) {
        print('  - ${collection.name} (ID: ${collection.$id})');
      }
      
      print('\n✅ Connection test SUCCESSFUL! 🎉');
    } catch (e) {
      print('❌ Database connection failed!');
      print('Error: $e');
      print('\n⚠️  Please check:');
      print('  1. Database ID is correct');
      print('  2. Collections are created in Appwrite Console');
      print('  3. Permissions are set correctly');
    }
  } catch (e) {
    print('❌ Failed to initialize Appwrite client!');
    print('Error: $e');
    print('\n⚠️  Please check:');
    print('  1. Endpoint URL is correct');
    print('  2. Project ID is correct');
    print('  3. Internet connection is stable');
  }
}
