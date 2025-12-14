/// Tenant Statistics Model
/// 
/// Contains performance metrics for tenant selection decisions
class TenantStats {
  final String tenantId;
  final double monthlyRevenue; // 30 days
  final int transactionCount;  // 30 days
  final List<TopProduct> topProducts; // Top 5
  final String trend; // 'up', 'down', 'stable'
  
  TenantStats({
    required this.tenantId,
    required this.monthlyRevenue,
    required this.transactionCount,
    required this.topProducts,
    required this.trend,
  });
  
  /// Get formatted revenue string
  String get formattedRevenue {
    if (monthlyRevenue >= 1000000) {
      return 'Rp ${(monthlyRevenue / 1000000).toStringAsFixed(1)}jt';
    } else if (monthlyRevenue >= 1000) {
      return 'Rp ${(monthlyRevenue / 1000).toStringAsFixed(0)}rb';
    } else {
      return 'Rp ${monthlyRevenue.toStringAsFixed(0)}';
    }
  }
  
  /// Get trend icon
  String get trendIcon {
    switch (trend) {
      case 'up':
        return '📈';
      case 'down':
        return '📉';
      default:
        return '➖';
    }
  }
  
  /// Get average per transaction
  double get averagePerTransaction {
    if (transactionCount == 0) return 0;
    return monthlyRevenue / transactionCount;
  }
  
  String get formattedAverage {
    final avg = averagePerTransaction;
    if (avg >= 1000) {
      return 'Rp ${(avg / 1000).toStringAsFixed(0)}rb';
    }
    return 'Rp ${avg.toStringAsFixed(0)}';
  }
}

/// Top Product Model
class TopProduct {
  final String productName;
  final int soldCount;
  
  TopProduct({
    required this.productName,
    required this.soldCount,
  });
  
  factory TopProduct.fromJson(Map<String, dynamic> json) {
    return TopProduct(
      productName: json['product_name'] as String,
      soldCount: json['sold_count'] as int,
    );
  }
}
