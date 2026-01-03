import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:appwrite/appwrite.dart';
import 'package:kantin_app/core/config/appwrite_config.dart';
import '../models/tenant_stats_model.dart';

/// Tenant Statistics Service
/// 
/// Fetches performance metrics for tenant selection
class TenantStatsService {
  final Databases _databases;
  
  TenantStatsService()
      : _databases = Databases(Client()
          ..setEndpoint(AppwriteConfig.endpoint)
          ..setProject(AppwriteConfig.projectId));

  /// Get statistics for a tenant (last 30 days)
  Future<TenantStats> getTenantStats(String tenantId) async {
    try {
      // Calculate date 30 days ago
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      final sixtyDaysAgo = DateTime.now().subtract(const Duration(days: 60));
      
      // Query orders for this tenant in last 30 days
      final recentOrders = await _databases.listDocuments(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.ordersCollectionId,
        queries: [
          Query.equal('tenant_id', tenantId),
          Query.equal('order_status', 'completed'), // Only completed orders
          Query.greaterThan('\$createdAt', thirtyDaysAgo.toIso8601String()),
          Query.limit(1000), // Max orders to fetch
        ],
      );
      
      // Query orders for previous 30 days (for trend)
      final previousOrders = await _databases.listDocuments(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.ordersCollectionId,
        queries: [
          Query.equal('tenant_id', tenantId),
          Query.equal('order_status', 'completed'),
          Query.greaterThan('\$createdAt', sixtyDaysAgo.toIso8601String()),
          Query.lessThan('\$createdAt', thirtyDaysAgo.toIso8601String()),
          Query.limit(1000),
        ],
      );
      
      // Calculate revenue
      double monthlyRevenue = 0;
      for (final order in recentOrders.documents) {
        final total = order.data['total_price'];
        if (total != null) {
          monthlyRevenue += (total is int) ? total.toDouble() : total as double;
        }
      }
      
      double previousRevenue = 0;
      for (final order in previousOrders.documents) {
        final total = order.data['total_price'];
        if (total != null) {
          previousRevenue += (total is int) ? total.toDouble() : total as double;
        }
      }
      
      // Calculate trend
      String trend = 'stable';
      if (monthlyRevenue > previousRevenue * 1.1) {
        trend = 'up';
      } else if (monthlyRevenue < previousRevenue * 0.9) {
        trend = 'down';
      }
      
      // Get top products
      final topProducts = await _getTopProducts(tenantId, thirtyDaysAgo);
      
      return TenantStats(
        tenantId: tenantId,
        monthlyRevenue: monthlyRevenue,
        transactionCount: recentOrders.total,
        topProducts: topProducts,
        trend: trend,
      );
    } catch (e) {
      // Return empty stats on error
      return TenantStats(
        tenantId: tenantId,
        monthlyRevenue: 0,
        transactionCount: 0,
        topProducts: [],
        trend: 'stable',
      );
    }
  }
  
  /// Get top 5 products for a tenant
  Future<List<TopProduct>> _getTopProducts(String tenantId, DateTime since) async {
    try {
      // Query completed orders for this tenant (items stored as JSON in orders.items)
      final orders = await _databases.listDocuments(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.ordersCollectionId,
        queries: [
          Query.equal('tenant_id', tenantId),
          Query.equal('order_status', 'completed'), // Only completed orders
          Query.greaterThan('created_at', since.toIso8601String()),
          Query.limit(1000), // Get up to 1000 orders
        ],
      );
      
      // Aggregate products from all orders
      final Map<String, int> productCounts = {};
      
      for (final order in orders.documents) {
        // Parse items from JSON string
        final itemsJson = order.data['items'] as String?;
        if (itemsJson != null && itemsJson.isNotEmpty) {
          try {
            final List<dynamic> items = jsonDecode(itemsJson);
            
            for (final item in items) {
              final productName = item['product_name'] as String?;
              final quantity = item['quantity'] as int? ?? 1;
              
              if (productName != null) {
                productCounts[productName] = (productCounts[productName] ?? 0) + quantity;
              }
            }
          } catch (e) {
            // Skip orders with invalid JSON
            if (kDebugMode) print('Error parsing order items JSON: $e');
            continue;
          }
        }
      }
      
      // Sort by count and take top 5
      final sortedProducts = productCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      
      return sortedProducts
          .take(5)
          .map((e) => TopProduct(
                productName: e.key,
                soldCount: e.value,
              ))
          .toList();
    } catch (e) {
      if (kDebugMode) print('Error getting top products: $e');
      return [];
    }
  }
  
  /// Get stats for multiple tenants (batch)
  Future<Map<String, TenantStats>> getBatchStats(List<String> tenantIds) async {
    final Map<String, TenantStats> statsMap = {};
    
    // Fetch in parallel
    final futures = tenantIds.map((id) => getTenantStats(id));
    final results = await Future.wait(futures);
    
    for (var i = 0; i < tenantIds.length; i++) {
      statsMap[tenantIds[i]] = results[i];
    }
    
    return statsMap;
  }
}
