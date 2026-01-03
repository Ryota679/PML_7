import 'package:flutter/material.dart';
import 'package:kantin_app/core/config/appwrite_config.dart';
import 'package:appwrite/appwrite.dart';

/// Debug Page untuk Test Koneksi Admin
class DebugAdminPage extends StatefulWidget {
  const DebugAdminPage({super.key});

  @override
  State<DebugAdminPage> createState() => _DebugAdminPageState();
}

class _DebugAdminPageState extends State<DebugAdminPage> {
  final _emailController = TextEditingController(text: 'fuad@gmail.com');
  final _passwordController = TextEditingController();
  final List<String> _logs = [];
  bool _isLoading = false;

  void _addLog(String message) {
    setState(() {
      _logs.add('[${DateTime.now().toString().substring(11, 19)}] $message');
    });
  }

  Future<void> _testConnection() async {
    setState(() {
      _logs.clear();
      _isLoading = true;
    });

    try {
      _addLog('🔍 Starting Appwrite Connection Test...');
      _addLog('');
      
      // Initialize Appwrite
      final client = Client()
          .setEndpoint(AppwriteConfig.endpoint)
          .setProject(AppwriteConfig.projectId);
      
      final account = Account(client);
      final databases = Databases(client);
      
      _addLog('✅ Appwrite Client Initialized');
      _addLog('   Endpoint: ${AppwriteConfig.endpoint}');
      _addLog('   Project: ${AppwriteConfig.projectId}');
      _addLog('');
      
      // Step 1: Logout old session (if any)
      _addLog('Step 1: Checking existing session...');
      try {
        await account.deleteSession(sessionId: 'current');
        _addLog('✅ Old session cleared');
      } catch (e) {
        _addLog('ℹ️  No existing session to clear');
      }
      _addLog('');
      
      // Step 2: Login
      _addLog('Step 2: Testing Login...');
      _addLog('   Email: ${_emailController.text}');
      
      final session = await account.createEmailPasswordSession(
        email: _emailController.text,
        password: _passwordController.text,
      );
      
      _addLog('✅ Login Successful!');
      _addLog('   Session ID: ${session.$id}');
      _addLog('');
      
      // Step 3: Get Current User
      _addLog('Step 3: Getting Current User...');
      final user = await account.get();
      
      _addLog('✅ User Retrieved!');
      _addLog('   User ID: ${user.$id}');
      _addLog('   Email: ${user.email}');
      _addLog('   Name: ${user.name}');
      _addLog('');
      
      // Step 4: Get User Profile
      _addLog('Step 4: Fetching User Profile from Database...');
      _addLog('   Database: ${AppwriteConfig.databaseId}');
      _addLog('   Collection: ${AppwriteConfig.usersCollectionId}');
      _addLog('   Query: user_id = ${user.$id}');
      _addLog('');
      
      final response = await databases.listDocuments(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.usersCollectionId,
        queries: [
          Query.equal('user_id', user.$id),
          Query.limit(1),
        ],
      );
      
      if (response.documents.isEmpty) {
        _addLog('❌ ERROR: User Profile NOT FOUND!');
        _addLog('');
        _addLog('💡 Possible Issues:');
        _addLog('   1. No document with user_id = ${user.$id}');
        _addLog('   2. Check Appwrite Console → Databases → kantin-db → users');
        _addLog('   3. Make sure user_id field matches exactly');
        return;
      }
      
      final doc = response.documents.first;
      _addLog('✅ User Profile Found!');
      _addLog('');
      _addLog('Document Data:');
      _addLog('   • Document ID: ${doc.$id}');
      _addLog('   • user_id: ${doc.data['user_id']}');
      _addLog('   • email: ${doc.data['email']}');
      _addLog('   • full_name: ${doc.data['full_name']}');
      _addLog('   • role: ${doc.data['role']}');
      _addLog('');
      
      // Step 5: Verify Role
      _addLog('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      _addLog('Step 5: Role Verification');
      _addLog('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      _addLog('');
      
      final role = doc.data['role'];
      _addLog('Current role: "$role"');
      _addLog('Expected role: "adminsystem"');
      _addLog('');
      
      if (role == 'adminsystem') {
        _addLog('✅ ROLE IS CORRECT!');
        _addLog('   User should redirect to /admin dashboard');
      } else {
        _addLog('❌ ROLE IS WRONG!');
        _addLog('   Fix: Update role in Appwrite Console to "adminsystem"');
        _addLog('   (lowercase, no spaces)');
      }
      _addLog('');
      
      // Step 6: Test Routing
      _addLog('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      _addLog('Step 6: Routing Logic Test');
      _addLog('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      _addLog('');
      
      if (role == 'adminsystem') {
        _addLog('✅ Will redirect to: /admin');
      } else if (role == 'owner_business') {
        _addLog('→ Will redirect to: /business-owner');
      } else if (role == 'tenant') {
        _addLog('→ Will redirect to: /tenant');
      } else {
        _addLog('❌ Unknown role: "$role"');
        _addLog('   No redirect will happen!');
      }
      _addLog('');
      
      // Cleanup
      _addLog('Cleaning up session...');
      await account.deleteSession(sessionId: 'current');
      _addLog('✅ Logged out');
      _addLog('');
      
      // Summary
      _addLog('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      _addLog('SUMMARY');
      _addLog('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      _addLog('✅ Appwrite connection: SUCCESS');
      _addLog('✅ Login: SUCCESS');
      _addLog('✅ User retrieval: SUCCESS');
      _addLog('✅ Profile: FOUND');
      _addLog(role == 'adminsystem' ? '✅ Role: CORRECT' : '❌ Role: WRONG');
      _addLog('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      
    } catch (e) {
      _addLog('');
      _addLog('❌ ERROR OCCURRED!');
      _addLog('');
      _addLog('Error: $e');
      _addLog('');
      
      if (e.toString().contains('Invalid credentials')) {
        _addLog('💡 Fix: Check email/password');
      } else if (e.toString().contains('user_session_already_exists')) {
        _addLog('💡 Fix: Session already exists.');
        _addLog('   Solution: Close app and try again');
      } else if (e.toString().contains('Collection') && e.toString().contains('not found')) {
        _addLog('💡 Fix: Collection "users" does not exist');
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug Admin Connection'),
        backgroundColor: Colors.blue,
      ),
      body: Column(
        children: [
          // Input Form
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Column(
              children: [
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _testConnection,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text('Test Connection'),
                  ),
                ),
              ],
            ),
          ),
          
          // Logs
          Expanded(
            child: Container(
              color: Colors.black,
              padding: const EdgeInsets.all(16),
              child: ListView.builder(
                itemCount: _logs.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      _logs[index],
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        color: _logs[index].contains('❌')
                            ? Colors.red
                            : _logs[index].contains('✅')
                                ? Colors.green
                                : _logs[index].contains('💡')
                                    ? Colors.yellow
                                    : Colors.white,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
