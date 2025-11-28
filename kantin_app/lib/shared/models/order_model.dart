import 'package:appwrite/models.dart';
import 'package:flutter/material.dart';
import 'package:kantin_app/shared/models/order_item_model.dart';

/// Order status enum
enum OrderStatus {
  pending,
  confirmed,
  preparing,
  ready,
  completed,
  cancelled;

  /// Convert from string
  static OrderStatus fromString(String value) {
    return OrderStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => OrderStatus.pending,
    );
  }

  /// Get display label
  String get label {
    switch (this) {
      case OrderStatus.pending:
        return 'Menunggu';
      case OrderStatus.confirmed:
        return 'Dikonfirmasi';
      case OrderStatus.preparing:
        return 'Diproses';
      case OrderStatus.ready:
        return 'Siap';
      case OrderStatus.completed:
        return 'Selesai';
      case OrderStatus.cancelled:
        return 'Dibatalkan';
    }
  }

  /// Get status color
  Color get color {
    switch (this) {
      case OrderStatus.pending:
        return Colors.orange;
      case OrderStatus.confirmed:
        return Colors.blue;
      case OrderStatus.preparing:
        return Colors.purple;
      case OrderStatus.ready:
        return Colors.green;
      case OrderStatus.completed:
        return Colors.grey;
      case OrderStatus.cancelled:
        return Colors.red;
    }
  }
}

/// Model representing an order
class OrderModel {
  final String? id;
  final String orderNumber;
  final String tenantId;
  final String? customerId; // Link to customer (null for guest orders)
  final String customerName;
  final String customerContact;
  final String? tableNumber;
  final int totalAmount;
  final OrderStatus status;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<OrderItemModel>? items; // Populated separately

  OrderModel({
    this.id,
    required this.orderNumber,
    required this.tenantId,
    this.customerId,
    required this.customerName,
    required this.customerContact,
    this.tableNumber,
    required this.totalAmount,
    required this.status,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.items,
  });

  /// Create OrderModel from Appwrite Document
  factory OrderModel.fromDocument(Document doc) {
    return OrderModel(
      id: doc.$id,
      orderNumber: doc.data['order_number'] as String,
      tenantId: doc.data['tenant_id'] as String,
      customerId: doc.data['customer_id'] as String?,
      customerName: doc.data['customer_name'] as String,
      customerContact: doc.data['customer_contact'] as String,
      tableNumber: doc.data['table_number'] as String?,
      totalAmount: doc.data['total_amount'] as int? ?? 0,
      status: OrderStatus.fromString(doc.data['status'] as String? ?? 'pending'),
      notes: doc.data['notes'] as String?,
      createdAt: DateTime.parse(doc.$createdAt),
      updatedAt: DateTime.parse(doc.$updatedAt),
    );
  }

  /// Convert to Map for Appwrite createDocument
  Map<String, dynamic> toMap() {
    return {
      'order_number': orderNumber,
      'tenant_id': tenantId,
      'customer_id': customerId,
      'customer_name': customerName,
      'customer_contact': customerContact,
      'table_number': tableNumber,
      'total_amount': totalAmount,
      'status': status.name,
      'notes': notes,
    };
  }

  /// Generate unique order number
  /// Format: ORD-YYYYMMDD-HHMMSS-XXX
  static String generateOrderNumber() {
    final now = DateTime.now();
    final dateStr = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    final timeStr = '${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}';
    final random = now.millisecond.toString().padLeft(3, '0');
    return 'ORD-$dateStr-$timeStr-$random';
  }

  /// Check if order is pending
  bool get isPending => status == OrderStatus.pending;

  /// Check if order is completed
  bool get isCompleted => status == OrderStatus.completed;

  /// Check if order is cancelled
  bool get isCancelled => status == OrderStatus.cancelled;

  /// Check if order can be cancelled
  bool get canCancel => status == OrderStatus.pending || status == OrderStatus.confirmed;

  /// Check if this is a guest order (no customer link)
  bool get isGuestOrder => customerId == null;

  /// Check if this is a customer order (linked to customer account)
  bool get isCustomerOrder => customerId != null;

  /// Create a copy with updated fields
  OrderModel copyWith({
    String? id,
    String? orderNumber,
    String? tenantId,
    String? customerId,
    String? customerName,
    String? customerContact,
    String? tableNumber,
    int? totalAmount,
    OrderStatus? status,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<OrderItemModel>? items,
  }) {
    return OrderModel(
      id: id ?? this.id,
      orderNumber: orderNumber ?? this.orderNumber,
      tenantId: tenantId ?? this.tenantId,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerContact: customerContact ?? this.customerContact,
      tableNumber: tableNumber ?? this.tableNumber,
      totalAmount: totalAmount ?? this.totalAmount,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      items: items ?? this.items,
    );
  }

  @override
  String toString() {
    return 'OrderModel(orderNumber: $orderNumber, status: ${status.label}, total: $totalAmount)';
  }
}
