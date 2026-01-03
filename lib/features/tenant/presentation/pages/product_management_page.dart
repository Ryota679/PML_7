import 'package:flutter/foundation.dart';
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
import '../../providers/tenant_subscription_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';


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
    
    // Check for over-limit dialog after page loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndShowOverlimitDialog();
    });
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
    final subscriptionStatus = ref.watch(tenantSubscriptionStatusProvider);

    // Count active products
    final activeProductCount = productsState.products.where((p) => p.isAvailable).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Menu'),
        actions: [
          // Counter badge
          subscriptionStatus.when(
            data: (status) {
              if (!status.isBusinessOwnerFreeTier) return const SizedBox.shrink();
              
              final isAtLimit = activeProductCount >= status.productLimit;
              final badgeColor = isAtLimit ? Colors.orange : Colors.green;
              
              return Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: badgeColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: badgeColor, width: 1.5),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isAtLimit ? Icons.warning_amber : Icons.check_circle,
                      color: badgeColor,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$activeProductCount/${status.productLimit}',
                      style: TextStyle(
                        color: badgeColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
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
                  setState(() {
                    _selectedCategoryId = null;
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
                setState(() {
                  _selectedCategoryId = selected ? category.id : null;
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
    // Filter products by category if selected
    final products = categoryFilter == null
        ? allProducts
        : allProducts.where((p) => p.categoryId == categoryFilter).toList();

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
      showDialog(
        context: context,
        builder: (context) => const UpgradeDialog(isBusinessOwner: false),
      );
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
      showDialog(
        context: context,
        builder: (context) => const UpgradeDialog(isBusinessOwner: false),
      );
    } else {
      _showCategoryDialog(context);
    }
  }

  // Phase 4: Build FAB with 10 vs 15 product limit enforcement
  Widget _buildFAB(BuildContext context, String tenantId) {
    final subscriptionStatus = ref.watch(tenantSubscriptionStatusProvider);
    final productsState = ref.watch(tenantProductsProvider(tenantId));
    final currentProductCount = productsState.products.length;

    return subscriptionStatus.when(
      data: (status) {
        // Premium BO: No limit
        if (!status.isBusinessOwnerFreeTier) {
          return FloatingActionButton.extended(
            onPressed: () => _showProductDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('Tambah Produk'),
          );
        }

        // Free Tier BO: Check limit (10 or 15 based on selection)
        final hasReachedLimit = status.isLimitReached(currentProductCount);
        final limitText = status.isTenantSelected ? '15' : '10';

        if (hasReachedLimit) {
          return FloatingActionButton.extended(
            onPressed: () => _showProductLimitDialog(context, status),
            icon: const Icon(Icons.lock),
            label: Text('Limit $limitText Produk'),
            backgroundColor: Colors.grey,
          );
        }

        // Count ACTIVE products (not total)
        final activeProductCount = productsState.products.where((p) => p.isAvailable).length;
        
        // Under limit: Allow CREATE
        if (activeProductCount < status.productLimit) {
          return FloatingActionButton.extended(
            onPressed: () => _showProductDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('Tambah Produk'),
          );
        }
        
        // At limit: Show upgrade button (swap logic via toggle still works)
        return FloatingActionButton.extended(
          onPressed: () => _showProductLimitDialog(context, status),
          icon: const Icon(Icons.lock),
          label: Text('Limit ${status.productLimit} Produk'),
          backgroundColor: Colors.orange.shade700,
        );
      },
      loading: () => const FloatingActionButton(
        onPressed: null,
        child: CircularProgressIndicator(),
      ),
      error: (_, __) => FloatingActionButton.extended(
        onPressed: () => _showProductDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Tambah Produk'),
      ),
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
if (kDebugMode) print('🔄 [TOGGLE] Starting toggle for product: $productId, target: ${isAvailable ? "ON" : "OFF"}');
    
    final user = ref.read(authProvider).user;
    if (user?.tenantId == null) {
  if (kDebugMode) print('❌ [TOGGLE] No user or tenant ID');
      return;
    }

    // If turning OFF, always allow
    if (!isAvailable) {
  if (kDebugMode) print('✅ [TOGGLE] Turning OFF - always allowed');
      await ref
          .read(tenantProductsProvider(user!.tenantId!).notifier)
          .toggleProductAvailability(productId, isAvailable);
  if (kDebugMode) print('✅ [TOGGLE] OFF complete');
      return;
    }

    // If turning ON, check limit ONLY if BO is free tier
if (kDebugMode) print('🔍 [TOGGLE] Turning ON - checking BO tier...');
    final subscriptionStatus = await ref.read(tenantSubscriptionStatusProvider.future);
    
    // During premium/trial: Allow unlimited swap (no enforcement)
    if (!subscriptionStatus.isBusinessOwnerFreeTier) {
  if (kDebugMode) print('✅ [TOGGLE] BO Premium/Trial - Unlimited swap allowed');
      await ref
          .read(tenantProductsProvider(user!.tenantId!).notifier)
          .toggleProductAvailability(productId, isAvailable);
  if (kDebugMode) print('✅ [TOGGLE] ON complete (no limit check)');
      return;
    }
    
    // BO is free tier - enforce limit
if (kDebugMode) print('🔍 [TOGGLE] BO Free Tier - Checking limit...');
if (kDebugMode) print('📊 [TOGGLE] Subscription limit: ${subscriptionStatus.productLimit}');
    
    // Count current active products
    final productsState = ref.read(tenantProductsProvider(user!.tenantId!));
    final activeCount = productsState.products
        .where((p) => p.isAvailable && p.id != productId)
        .length;
    
if (kDebugMode) print('📊 [TOGGLE] Current active count: $activeCount');
    
    // Check if at limit
    if (activeCount >= subscriptionStatus.productLimit) {
  if (kDebugMode) print('❌ [TOGGLE] BLOCKED - At limit ($activeCount/${subscriptionStatus.productLimit})');
      
      // Show simple snackbar warning
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '💡 Limit produk tercapai (${subscriptionStatus.productLimit}/${subscriptionStatus.productLimit}).\n\nUntuk mengaktifkan produk ini, nonaktifkan salah satu produk lain terlebih dahulu.',
                    style: const TextStyle(fontSize: 13, height: 1.4),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.blue.shade700,
            duration: const Duration(seconds: 5),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return; // Don't allow toggle ON if at limit
    }

    // Allow toggle - within limit
if (kDebugMode) print('✅ [TOGGLE] ALLOWED - Within limit ($activeCount/${subscriptionStatus.productLimit})');
    await ref
        .read(tenantProductsProvider(user.tenantId!).notifier)
        .toggleProductAvailability(productId, isAvailable);
if (kDebugMode) print('✅ [TOGGLE] ON complete');
  }
  
  // Phase 4: Show product limit dialog with selection-aware messaging
  void _showProductLimitDialog(
    BuildContext context,
    TenantSubscriptionStatus status,
  ) {
    final limitText = status.productLimit.toString();
    final selectionStatus = status.isTenantSelected ? 'Terpilih' : 'Non-Prioritas';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF101010),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: Colors.grey.shade900, width: 1),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.orange.shade900, Colors.deepOrange.shade900],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.lock_outline, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Text(
                'Limit Tercapai',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Status: $selectionStatus (Free Tier)',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade400,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Anda telah mencapai batas maksimal $limitText produk aktif.',
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey.shade300,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            if (!status.isTenantSelected) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.shade900.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.shade800, width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.orange, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Tenant Non-Prioritas',
                          style: TextStyle(
                            color: Colors.orange,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tenant terpilih mendapat limit 15 produk. Hubungi pemilik bisnis untuk upgrade.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade300,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
            Text(
              'Untuk menambah produk baru:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
                color: Colors.grey.shade300,
              ),
            ),
            const SizedBox(height: 12),
            _buildLimitOption('1', 'Non-aktifkan produk yang tidak terpakai'),
            _buildLimitOption('2', 'Upgrade ke Premium (Unlimited)'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(foregroundColor: Colors.grey),
            child: const Text('Tutup'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              showDialog(
                context: context,
                builder: (context) => const UpgradeDialog(isBusinessOwner: false),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade700,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            ),
            child: const Text('Upgrade Premium'),
          ),
        ],
      ),
    );
  }

  Widget _buildLimitOption(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.cyan.shade900,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade300,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  // Issue #5: Check and show over-limit dialog
  Future<void> _checkAndShowOverLimitDialog() async {
    final user = ref.read(authProvider).user;
    if (user?.tenantId == null) return;
    
    // IMPORTANT: Only auto-deactivate for tenant owner, NOT Business Owner
    // BO viewing tenant products should not trigger auto-deactivation
    // This prevents permission errors and ensures auto-deactivation happens
    // when the actual tenant owner logs in after BO downgrade
    if (user?.role != 'tenant') {
  if (kDebugMode) print('⏭️ [AUTO-DEACTIVATE] Skipped - User is not tenant owner (role: ${user?.role})');
      return;
    }
    
    final tenantId = user!.tenantId!;
    
    // 1. Check if user has permanently dismissed
    final prefs = await SharedPreferences.getInstance();
    final hideDialog = prefs.getBool('hide_overlimit_dialog_$tenantId') ?? false;
    if (hideDialog) return;
    
    // 2. Get subscription status and products
    final subscriptionStatus = await ref.read(tenantSubscriptionStatusProvider.future);
    final productsState = ref.read(tenantProductsProvider(tenantId));
    
    // 3. Check if over limit
    final activeProducts = productsState.products.where((p) => p.isAvailable).toList();
    final activeCount = activeProducts.length;
    
    if (activeCount <= subscriptionStatus.productLimit) return;
    
    // 4. AUTO-DEACTIVATE excess products (random pick)
if (kDebugMode) print('🔴 [AUTO-DEACTIVATE] Over limit! Active: $activeCount, Limit: ${subscriptionStatus.productLimit}');
    final excessCount = activeCount - subscriptionStatus.productLimit;
if (kDebugMode) print('🔴 [AUTO-DEACTIVATE] Need to deactivate: $excessCount products');
    
    // Shuffle and pick random products to deactivate
    final shuffled = List.from(activeProducts)..shuffle();
    final toDeactivate = shuffled.take(excessCount).toList();
    
if (kDebugMode) print('🔴 [AUTO-DEACTIVATE] Deactivating products:');
    for (var product in toDeactivate) {
  if (kDebugMode) print('   • ${product.name} (${product.id})');
      await ref
          .read(tenantProductsProvider(tenantId).notifier)
          .toggleProductAvailability(product.id, false);
    }
    
if (kDebugMode) print('✅ [AUTO-DEACTIVATE] Complete! Deactivated $excessCount products');
    
    // 5. Show dialog (informational) - use CURRENT count after deactivation
    final newActiveCount = subscriptionStatus.productLimit; // Now at limit
    if (mounted) {
      _showDeactivationDialog(activeCount, newActiveCount, subscriptionStatus.productLimit, tenantId);
    }
  }
  
  /// Check if should show over-limit dialog
  /// Triggers when totalProducts > limit AND activeProducts <= limit
  /// This indicates auto-deactivation occurred
  Future<void> _checkAndShowOverlimitDialog() async {
    try {
      final user = ref.read(authProvider).user;
      if (user?.tenantId == null) return;

      // Check subscription status
      final subscriptionStatus = await ref.read(tenantSubscriptionStatusProvider.future);
      
      // Only show for free tier
      if (!subscriptionStatus.isBusinessOwnerFreeTier) return;

      final tenantId = user!.tenantId!;
      final limit = subscriptionStatus.productLimit; // 15 for selected, 10 for non-selected

      // Check if user permanently dismissed this
      final prefs = await SharedPreferences.getInstance();
      final dismissed = prefs.getBool('hide_overlimit_dialog_$tenantId') ?? false;
      if (dismissed) return;

      // Check if dialog was shown recently (within 5 minutes to avoid spam)
      final lastShown = prefs.getInt('last_overlimit_dialog_shown_$tenantId') ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;
      if (now - lastShown < 5 * 60 * 1000) return; // 5 minutes cooldown

      // Get current product count
      final productsState = ref.read(tenantProductsProvider(tenantId));
      final activeCount = productsState.products.where((p) => p.isAvailable).length;
      final totalCount = productsState.products.length;

      // Show dialog if user has more total products than limit
      // This indicates deactivation happened
      if (totalCount > limit && activeCount <= limit) {
        AppLogger.info('Showing overlimit dialog: total=$totalCount, active=$activeCount, limit=$limit');
        
        // Save timestamp to prevent spam
        await prefs.setInt('last_overlimit_dialog_shown_$tenantId', now);
        
        // Show dialog
        if (mounted) {
          _showDeactivationDialog(totalCount, activeCount, limit, tenantId);
        }
      }
    } catch (e) {
      AppLogger.error('Failed to check overlimit dialog', e);
    }
  }
  
  void _showDeactivationDialog(int originalCount, int currentCount, int limit, String tenantId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.grey.shade800, width: 1),
        ),
        title: Row(
          children: [
            Icon(
              Icons.warning_amber,
              color: Colors.orange.shade600,
              size: 28,
            ),
            const SizedBox(width: 12),
            const Text(
              'Produk Melebihi Limit',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(
        'Anda memiliki $originalCount produk, limit $limit.\n\n'
        'Beberapa produk telah dinonaktifkan otomatis. Sekarang ada $currentCount produk aktif.\n\n'
        'Anda bisa swap produk aktif dengan toggle di halaman ini untuk mengatur produk mana yang tetap aktif.',
        style: TextStyle(
          color: Colors.grey.shade300,
          fontSize: 14,
          height: 1.5,
        ),
      ),
        actions: [
          TextButton(
            onPressed: () async {
              // Permanently dismiss
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('hide_overlimit_dialog_$tenantId', true);
              Navigator.pop(context);
            },
            child: Text(
              'Jangan Ingatkan Lagi',
              style: TextStyle(color: Colors.grey.shade400),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text('Mengerti'),
          ),
        ],
      ),
    );
  }
}
