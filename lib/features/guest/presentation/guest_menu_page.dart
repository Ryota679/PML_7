import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kantin_app/features/guest/providers/cart_provider.dart';
import 'package:kantin_app/features/tenant/providers/category_provider.dart';
import 'package:kantin_app/features/tenant/providers/product_provider.dart';
import 'package:kantin_app/shared/models/category_model.dart';
import 'package:kantin_app/shared/models/product_model.dart';
import 'package:kantin_app/features/guest/presentation/widgets/guest_product_card.dart';
import 'package:kantin_app/core/utils/app_logger.dart';

/// Guest Menu Page
/// Public access - no login required
class GuestMenuPage extends ConsumerStatefulWidget {
  final String tenantId;

  const GuestMenuPage({
    super.key,
    required this.tenantId,
  });

  @override
  ConsumerState<GuestMenuPage> createState() => _GuestMenuPageState();
}

class _GuestMenuPageState extends ConsumerState<GuestMenuPage> {
  String? _selectedCategoryId;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    // Load products and categories
    Future.microtask(() {
      ref.read(tenantProductsProvider(widget.tenantId).notifier).loadProducts();
      ref.read(tenantCategoriesProvider(widget.tenantId).notifier).loadCategories();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productsState = ref.watch(tenantProductsProvider(widget.tenantId));
    final categoriesState = ref.watch(tenantCategoriesProvider(widget.tenantId));
    final cartItemsCount = ref.watch(cartTotalItemsProvider);

    // Filter products based on search and category
    final filteredProducts = _filterProducts(
      productsState.products,
      _selectedCategoryId,
      _searchQuery,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Menu'),
        actions: [
          // Cart badge
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart_outlined),
                onPressed: () {
                  context.push('/cart/${widget.tenantId}');
                },
              ),
              if (cartItemsCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Text(
                      cartItemsCount > 99 ? '99+' : cartItemsCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(tenantProductsProvider(widget.tenantId).notifier).loadProducts();
        },
        child: CustomScrollView(
          slivers: [
            // Tenant Header (optional - bisa ditambah tenant info)
            
            // Search Bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Cari menu...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() => _searchQuery = value);
                  },
                ),
              ),
            ),

            // Category Filter Tabs
            SliverToBoxAdapter(
              child: categoriesState.isLoading
                  ? const SizedBox.shrink()
                  : _buildCategoryTabs(categoriesState.categories),
            ),

            // Products Grid
            if (productsState.isLoading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (productsState.error != null)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text('Error: ${productsState.error}'),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: () {
                          ref.read(tenantProductsProvider(widget.tenantId).notifier).loadProducts();
                        },
                        child: const Text('Coba Lagi'),
                      ),
                    ],
                  ),
                ),
              )
            else if (filteredProducts.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.menu_book_outlined, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        _searchQuery.isNotEmpty
                            ? 'Tidak ada menu yang cocok'
                            : 'Belum ada menu tersedia',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.75,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final product = filteredProducts[index];
                      return GuestProductCard(
                        product: product,
                        onAddToCart: () => _addToCart(product),
                      );
                    },
                    childCount: filteredProducts.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryTabs(List<CategoryModel> categories) {
    if (categories.isEmpty) return const SizedBox.shrink();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // All products chip
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: const Text('Semua'),
              selected: _selectedCategoryId == null,
              onSelected: (selected) {
                setState(() => _selectedCategoryId = null);
              },
            ),
          ),
          // Category chips
          ...categories.map((category) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(category.name),
                selected: _selectedCategoryId == category.id,
                onSelected: (selected) {
                  AppLogger.info('🎯 === CATEGORY TAB CLICKED ===');
                  AppLogger.info('📂 Category Name: ${category.name}');
                  AppLogger.info('🆔 Category ID: ${category.id}');
                  AppLogger.info('✅ Selected: $selected');
                  
                  setState(() {
                    _selectedCategoryId = selected ? category.id : null;
                    AppLogger.info('🔄 New _selectedCategoryId: $_selectedCategoryId');
                  });
                },
              ),
            );
          }),
        ],
      ),
    );
  }

  List<ProductModel> _filterProducts(
    List<ProductModel> products,
    String? categoryId,
    String searchQuery,
  ) {
    AppLogger.info('🔍 === FILTER PRODUCTS START ===');
    AppLogger.info('📦 Total Products: ${products.length}');
    AppLogger.info('🆔 Filter by Category ID: ${categoryId ?? "null (Show All)"}');
    AppLogger.info('🔎 Search Query: "$searchQuery"');
    
    var filtered = products;

    // Filter by category
    if (categoryId != null) {
      AppLogger.info('   └─ Filtering by category...');
      filtered = filtered.where((p) {
        final match = p.categoryId == categoryId;
        if (!match) {
          AppLogger.info('      ✗ ${p.name}: categoryId=${p.categoryId} != $categoryId');
        } else {
          AppLogger.info('      ✓ ${p.name}: categoryId=${p.categoryId} == $categoryId');
        }
        return match;
      }).toList();
      AppLogger.info('   └─ After category filter: ${filtered.length} products');
    }

    // Filter by search query
    if (searchQuery.isNotEmpty) {
      AppLogger.info('   └─ Filtering by search query...');
      filtered = filtered.where((p) {
        return p.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
            (p.description?.toLowerCase().contains(searchQuery.toLowerCase()) ?? false);
      }).toList();
      AppLogger.info('   └─ After search filter: ${filtered.length} products');
    }

    // Only show available and active products
    AppLogger.info('   └─ Filtering by isAvailable && isActive...');
    final beforeActiveFilter = filtered.length;
    filtered = filtered.where((p) {
      final show = p.isAvailable && p.isActive;
      if (!show) {
        AppLogger.info('      ✗ ${p.name}: isAvailable=${p.isAvailable}, isActive=${p.isActive}');
      }
      return show;
    }).toList();
    AppLogger.info('   └─ After active filter: ${filtered.length} products (removed ${beforeActiveFilter - filtered.length})');

    AppLogger.info('✅ === FILTER RESULT: ${filtered.length} products ===');
    if (filtered.isEmpty) {
      AppLogger.warning('⚠️ NO PRODUCTS MATCHED THE FILTERS!');
    } else {
      AppLogger.info('📋 Filtered Products:');
      for (var p in filtered) {
        AppLogger.info('   • ${p.name} (categoryId: ${p.categoryId})');
      }
    }
    AppLogger.info('');
    
    return filtered;
  }

  void _addToCart(ProductModel product) {
    ref.read(cartProvider.notifier).addItem(product);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${product.name} ditambahkan ke keranjang'),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Lihat',
          onPressed: () {
            context.push('/cart/${widget.tenantId}');
          },
        ),
      ),
    );
  }
}
