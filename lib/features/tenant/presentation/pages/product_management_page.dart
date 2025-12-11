import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/models/category_model.dart';
import '../../../../shared/models/product_model.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/product_provider.dart';
import '../widgets/category_dialog.dart';
import '../widgets/product_card.dart';
import '../widgets/product_dialog.dart';
import '../../../business_owner/providers/tenant_provider.dart';
import 'package:kantin_app/shared/widgets/upgrade_dialog.dart';
import '../../../business_owner/data/tenant_repository.dart';
import '../../../../core/providers/appwrite_provider.dart';
import '../../../../core/config/appwrite_config.dart';
import '../../../../core/utils/app_logger.dart';


/// Product Management Page for Tenant
/// Allows tenant to manage products and categories
class ProductManagementPage extends ConsumerStatefulWidget {
  const ProductManagementPage({super.key});

  @override
  ConsumerState<ProductManagementPage> createState() =>
      _ProductManagementPageState();
}

class _ProductManagementPageState
    extends ConsumerState<ProductManagementPage> {
  String? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    // Load data on init
    Future.microtask(() => _loadData());
  }

  void _loadData() {
    final user = ref.read(authProvider).user;
    if (user?.tenantId != null) {
      ref.read(tenantCategoriesProvider(user!.tenantId!).notifier).loadCategories();
      ref.read(tenantProductsProvider(user.tenantId!).notifier).loadProducts();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    
    if (user?.tenantId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Kelola Menu')),
        body: const Center(
          child: Text('User tidak terhubung dengan tenant'),
        ),
      );
    }

    final categoriesState = ref.watch(tenantCategoriesProvider(user!.tenantId!));
    final productsState = ref.watch(tenantProductsProvider(user.tenantId!));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Menu'),
        actions: [
          IconButton(
            icon: const Icon(Icons.category),
            onPressed: () => _handleCategoryButton(context),
            tooltip: 'Kelola Kategori',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Refresh',
         ),
        ],
      ),
      body: _buildBody(categoriesState, productsState),
      floatingActionButton: _buildFAB(context, user.tenantId!),
    );
  }

  Widget _buildBody(CategoryState categoriesState, ProductState productsState) {
    if (categoriesState.isLoading || productsState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (categoriesState.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: ${categoriesState.error}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadData,
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      );
    }

    if (categoriesState.categories.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.category_outlined, size: 100, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text('Belum ada kategori'),
            const SizedBox(height: 8),
            const Text('Buat kategori terlebih dahulu'),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _showCategoryDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('Buat Kategori'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Category tabs
        _buildCategoryTabs(categoriesState.categories),
        
        // Products list
        Expanded(
          child: _buildProductsList(
            productsState.products,
            _selectedCategoryId,
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryTabs(List<CategoryModel> categories) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            // "All" tab
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: const Text('Semua'),
                selected: _selectedCategoryId == null,
                onSelected: (selected) {
                  AppLogger.info('🎯 === "SEMUA" TAB CLICKED ===');
                  AppLogger.info('✅ Show all products');
                  setState(() {
                    _selectedCategoryId = null;
                    AppLogger.info('🔄 _selectedCategoryId set to: null');
                  });
                },
              ),
            );
          }

          final category = categories[index - 1];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (category.icon != null) ...[
                    Text(category.icon!),
                    const SizedBox(width: 4),
                  ],
                  Text(category.name),
                ],
              ),
              selected: _selectedCategoryId == category.id,
              onSelected: (selected) {
                AppLogger.info('🎯 === CATEGORY TAB CLICKED ===');
                AppLogger.info('📂 Category Name: ${category.name}');
                AppLogger.info('🆔 Category ID: ${category.id}');
                AppLogger.info('✅ Selected: $selected');
                setState(() {
                  _selectedCategoryId = selected ? category.id : null;
                  AppLogger.info('🔄 _selectedCategoryId set to: $_selectedCategoryId');
                });
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductsList(
    List<ProductModel> allProducts,
    String? categoryFilter,
  ) {
    AppLogger.info('🔍 === BUILD PRODUCTS LIST ===');
    AppLogger.info('📦 Total Products: ${allProducts.length}');
    AppLogger.info('🆔 Category Filter: ${categoryFilter ?? "null (Show All)"}');
    
    // Filter products by category if selected
    final products = categoryFilter == null
        ? allProducts
        : allProducts.where((p) {
            final match = p.categoryId == categoryFilter;
            if (!match) {
              AppLogger.info('   ✗ ${p.name}: categoryId=${p.categoryId} != $categoryFilter');
            } else {
              AppLogger.info('   ✓ ${p.name}: categoryId=${p.categoryId} == $categoryFilter');
            }
            return match;
          }).toList();

    AppLogger.info('✅ === FILTERED RESULT: ${products.length} products ===');
    if (products.isEmpty) {
      AppLogger.warning('⚠️ NO PRODUCTS MATCHED!');
    } else {
      AppLogger.info('📋 Products to display:');
      for (var p in products) {
        AppLogger.info('   • ${p.name} (categoryId: ${p.categoryId})');
      }
    }
    AppLogger.info('');

    if (products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_basket_outlined,
                size: 100, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text('Belum ada produk'),
            const SizedBox(height: 8),
            Text(
              categoryFilter == null
                  ? 'Tap tombol + untuk menambah produk'
                  : 'Belum ada produk di kategori ini',
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return ProductCard(
          product: product,
          onEdit: () => _handleEditProduct(context, product),
          onDelete: () => _confirmDeleteProduct(product),
          onToggleAvailability: (isAvailable) =>
              _toggleProductAvailability(product.id, isAvailable),
        );
      },
    );
  }
  
  // Phase 3: Handle edit product click
  void _handleEditProduct(BuildContext context, ProductModel product) async {
    final user = ref.read(authProvider).user;
    if (user?.tenantId == null) return;
    
    final isFreeTier = await _isBusinessOwnerFreeTier(user!.tenantId!);
    if (isFreeTier) {
      _showPhase3UpgradeDialog(context);
    } else {
      _showProductDialog(context, product: product);
    }
  }

  
  // Phase 3: Check if Business Owner is free tier
  Future<bool> _isBusinessOwnerFreeTier(String tenantId) async {
    try {
      // Get tenant to find owner ID
      final tenantRepo = ref.read(tenantRepositoryProvider);
      final tenant = await tenantRepo.getTenantById(tenantId);
      if (tenant == null) return false;
      
      // Get owner user document from users collection
      final databases = ref.read(appwriteDatabasesProvider);
      final userDoc = await databases.getDocument(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.usersCollectionId,
        documentId: tenant.ownerId,
      );
      
      // Check if owner is free tier
      final paymentStatus = userDoc.data['payment_status'] as String?;
      if (paymentStatus == 'premium' || paymentStatus == 'active') {
        return false; // Premium user
      }
      
      // Check if trial is active
      if (paymentStatus == 'trial') {
        final expiresAt = userDoc.data['subscription_expires_at'] as String?;
        if (expiresAt != null) {
          final expiryDate = DateTime.parse(expiresAt);
          if (expiryDate.isAfter(DateTime.now())) {
            return false; // Active trial
          }
        }
      }
      
      // Free tier (trial expired or never had)
      return true;
    } catch (e) {
      AppLogger.error('Error checking BO tier', e);
      return false; // On error, allow access
    }
  }

  // Phase 3: Handle category button click
  void _handleCategoryButton(BuildContext context) async {
    final user = ref.read(authProvider).user;
    if (user?.tenantId == null) return;
    
    final isFreeTier = await _isBusinessOwnerFreeTier(user!.tenantId!);
    if (isFreeTier) {
      _showPhase3UpgradeDialog(context);
    } else {
      _showCategoryDialog(context);
    }
  }

  // Phase 3: Build FAB with enforcement
  Widget _buildFAB(BuildContext context, String tenantId) {
    return FutureBuilder<bool>(
      future: _isBusinessOwnerFreeTier(tenantId),
      builder: (context, snapshot) {
        final isFreeTier = snapshot.data ?? false;
        
        if (isFreeTier) {
          return FloatingActionButton.extended(
            onPressed: () => _showPhase3UpgradeDialog(context),
            icon: const Icon(Icons.lock),
            label: const Text('Tambah Produk (Premium)'),
            backgroundColor: Colors.grey,
          );
        }
        
        return FloatingActionButton.extended(
          onPressed: () => _showProductDialog(context),
          icon: const Icon(Icons.add),
          label: const Text('Tambah Produk'),
        );
      },
    );
  }

  void _showCategoryDialog(BuildContext context, {CategoryModel? category}) {
    showDialog(
      context: context,
      builder: (context) => CategoryDialog(category: category),
    );
  }

  void _showProductDialog(BuildContext context, {ProductModel? product}) {
    final user = ref.read(authProvider).user;
    if (user?.tenantId == null) return;

    final categories = ref.read(tenantCategoriesProvider(user!.tenantId!)).categories;

    if (categories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Buat kategori terlebih dahulu'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => ProductDialog(
        product: product,
        categories: categories,
      ),
    );
  }

  void _confirmDeleteProduct(ProductModel product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Produk?'),
        content: Text('Yakin ingin menghapus "${product.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteProduct(product.id);
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteProduct(String productId) async {
    final user = ref.read(authProvider).user;
    if (user?.tenantId == null) return;

    final success = await ref
        .read(tenantProductsProvider(user!.tenantId!).notifier)
        .deleteProduct(productId);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Produk berhasil dihapus' : 'Gagal menghapus produk'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  Future<void> _toggleProductAvailability(String productId, bool isAvailable) async {
    final user = ref.read(authProvider).user;
    if (user?.tenantId == null) return;

    await ref
        .read(tenantProductsProvider(user!.tenantId!).notifier)
        .toggleProductAvailability(productId, isAvailable);
  }
  
  // Phase 3: Show upgrade dialog
  void _showPhase3UpgradeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const UpgradeDialog(
        isBusinessOwner: false, // Tenant context, will show tenant benefits
      ),
    );
  }
}
