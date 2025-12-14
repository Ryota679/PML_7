import 'package:appwrite/appwrite.dart';

void main() async {
  // Appwrite Configuration
  const endpoint = 'https://fra.cloud.appwrite.io/v1';
  const projectId = 'perojek-pml';
  const databaseId = 'kantin-db';
  const usersCollectionId = 'users';
  
  print('🔍 Testing Appwrite Connection...\n');
  
  // Initialize Appwrite Client
  final client = Client()
      .setEndpoint(endpoint)
      .setProject(projectId);
  
  final account = Account(client);
  final databases = Databases(client);
  
  try {
    // Step 1: Test Login
    print('Step 1: Testing Login...');
    print('Email: fuad@gmail.com');
    print('Trying to login...\n');
    
    final session = await account.createEmailPasswordSession(
      email: 'fuad@gmail.com',
      password: 'fuadganteng', // GANTI dengan password yang benar
    );
    
    print('✅ Login Successful!');
    print('Session ID: ${session.$id}\n');
    
    // Step 2: Get Current User
    print('Step 2: Getting Current User...');
    final user = await account.get();
    
    print('✅ User Retrieved!');
    print('User ID: ${user.$id}');
    print('Email: ${user.email}');
    print('Name: ${user.name}\n');
    
    // Step 3: Get User Profile from Database
    print('Step 3: Fetching User Profile from Database...');
    print('Database ID: $databaseId');
    print('Collection ID: $usersCollectionId');
    print('Query: user_id = ${user.$id}\n');
    
    final response = await databases.listDocuments(
      databaseId: databaseId,
      collectionId: usersCollectionId,
      queries: [
        Query.equal('user_id', user.$id),
        Query.limit(1),
      ],
    );
    
    if (response.documents.isEmpty) {
      print('❌ ERROR: User profile NOT FOUND in database!');
      print('\nPossible issues:');
      print('1. No document with user_id = ${user.$id} exists in "users" collection');
      print('2. Check Appwrite Console → Databases → kantin-db → users');
      print('3. Make sure user_id field matches exactly\n');
      return;
    }
    
    print('✅ User Profile Found!');
    final doc = response.documents.first;
    print('\nDocument Data:');
    print('- Document ID: ${doc.$id}');
    print('- user_id: ${doc.data['user_id']}');
    print('- email: ${doc.data['email']}');
    print('- full_name: ${doc.data['full_name']}');
    print('- role: ${doc.data['role']}');
    print('- created_at: ${doc.data['created_at']}');
    
    // Step 4: Verify Role
    print('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('Step 4: Role Verification');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    
    final role = doc.data['role'];
    print('\nCurrent role: "$role"');
    print('Expected role: "adminsystem"');
    
    if (role == 'adminsystem') {
      print('\n✅ ROLE IS CORRECT!');
      print('User should redirect to /admin dashboard');
    } else {
      print('\n❌ ROLE IS WRONG!');
      print('Fix: Update role in Appwrite Console to "adminsystem" (lowercase, no spaces)');
    }
    
    // Step 5: Test Routing Logic
    print('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('Step 5: Routing Logic Test');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
    
    if (role == 'adminsystem') {
      print('✅ Will redirect to: /admin');
    } else if (role == 'owner_business') {
      print('→ Will redirect to: /business-owner');
    } else if (role == 'tenant') {
      print('→ Will redirect to: /tenant');
    } else {
      print('❌ Unknown role! No redirect will happen.');
    }
    
    // Cleanup
    print('\nCleaning up session...');
    await account.deleteSession(sessionId: 'current');
    print('✅ Logged out\n');
    
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('SUMMARY');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('✅ Appwrite connection: SUCCESS');
    print('✅ Login: SUCCESS');
    print('✅ User retrieval: SUCCESS');
    print(response.documents.isEmpty ? '❌ Profile: NOT FOUND' : '✅ Profile: FOUND');
    print(role == 'adminsystem' ? '✅ Role: CORRECT' : '❌ Role: WRONG');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
    
  } catch (e) {
    print('\n❌ ERROR OCCURRED!\n');
    print('Error: $e\n');
    
    if (e.toString().contains('Invalid credentials')) {
      print('💡 Fix: Check email/password');
    } else if (e.toString().contains('user_session_already_exists')) {
      print('💡 Fix: Session already exists. Run this script again or logout first.');
    } else if (e.toString().contains('Collection') && e.toString().contains('not found')) {
      print('💡 Fix: Collection "users" does not exist in database "kantin-db"');
    } else if (e.toString().contains('Document') && e.toString().contains('not found')) {
      print('💡 Fix: No document with matching user_id in "users" collection');
    }
  }
}
