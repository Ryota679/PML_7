import 'package:flutter/material.dart';
import 'package:appwrite/models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_app/data/repository/category_repository_provider.dart';
import 'package:kantin_app/ui/tenant_list_screen.dart';
import 'package:kantin_app/src/features/tenant_management/presentation/screens/create_tenant_screen.dart';

class BusinessOwnerDashboard extends ConsumerStatefulWidget {
  const BusinessOwnerDashboard({super.key});

  @override
  ConsumerState<BusinessOwnerDashboard> createState() => _BusinessOwnerDashboardState();
}

class _BusinessOwnerDashboardState extends ConsumerState<BusinessOwnerDashboard> {
  final _categoryController = TextEditingController();
  List<Document> _categories = [];

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await ref.read(categoryRepositoryProvider).getCategories();
      if (!mounted) return;
      setState(() {
        _categories = categories;
      });
    } catch (e) {
      debugPrint(e.toString());
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
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CreateTenantScreen()),
                );
              },
              child: const Text('Create Tenant'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const TenantListScreen()),
                );
              },
              child: const Text('My Tenants'),
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
                await ref.read(categoryRepositoryProvider).createCategory(name);
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
