import 'package:flutter/material.dart';
import 'package:appwrite/models.dart';
import 'package:appwrite/appwrite.dart';
import 'package:kantin_app/data/repository/base_appwrite_repository.dart';
import 'package:kantin_app/data/repository/tenant_repository.dart';
import 'package:kantin_app/data/repository/category_repository.dart';

class BusinessOwnerDashboard extends StatefulWidget {
  const BusinessOwnerDashboard({super.key});

  @override
  State<BusinessOwnerDashboard> createState() => _BusinessOwnerDashboardState();
}

class _BusinessOwnerDashboardState extends State<BusinessOwnerDashboard> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _categoryController = TextEditingController();
  final TenantRepository _tenantRepository = TenantRepository(BaseAppwriteRepository().client);
  final CategoryRepository _categoryRepository = CategoryRepository(BaseAppwriteRepository().client);
  List<Document> _categories = [];

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await _categoryRepository.getCategories();
      if (!mounted) return;
      setState(() {
        _categories = categories;
      });
    } on AppwriteException catch (e) {
      debugPrint(e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Business Owner Dashboard'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Tenant Name'),
            ),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Tenant Email'),
            ),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Tenant Password'),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                setState(() {
                  // _isLoading = true; // Add a loading state variable if you don't have one
                });
                final name = _nameController.text;
                final email = _emailController.text;
                final password = _passwordController.text;
                final messenger = ScaffoldMessenger.of(context); 
                try {
                  await _tenantRepository.createTenant(name, email, password);
                  if (!mounted) return;
                  messenger.showSnackBar(
                    const SnackBar(content: Text('Tenant created successfully!')),
                  );
                  _nameController.clear();
                  _emailController.clear();
                  _passwordController.clear();
                } on AppwriteException catch (e) {
                  debugPrint('Appwrite Error: ${e.message}'); 
                  debugPrint('Appwrite Code: ${e.code}');
                  debugPrint('Appwrite Response: ${e.response}');
                  if (!mounted) return;
                  messenger.showSnackBar(
                    SnackBar(content: Text('Error: ${e.message ?? "Failed to create tenant."}')),
                  );
                } finally {
                  if (mounted) {
                    setState(() {
                      // _isLoading = false;
                    });
                  }
                }
              },
              child: const Text('Create Tenant'),
            ),
            const SizedBox(height: 32),
            const Text('Categories', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Expanded(
              child: ListView.builder(
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  return ListTile(
                    title: Text(category.data['name']),
                  );
                },
              ),
            ),
            TextField(
              controller: _categoryController,
              decoration: const InputDecoration(labelText: 'New Category Name'),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = _categoryController.text;
                await _categoryRepository.createCategory(name);
                if (!mounted) return;
                _categoryController.clear();
                _loadCategories();
              },
              child: const Text('Add Category'),
            ),
          ],
        ),
      ),
    );
  }
}
