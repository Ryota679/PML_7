import 'package:freezed_annotation/freezed_annotation.dart';

part 'order_notification.freezed.dart';

/// Model for order notification
@freezed
class OrderNotification with _$OrderNotification {
  const factory OrderNotification({
    required String orderId,
    required String orderNumber,
    required String customerName,
    required DateTime timestamp,
    @Default(false) bool isRead,
  }) = _OrderNotification;
}
