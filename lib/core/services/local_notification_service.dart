import 'dart:async';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:kantin_app/core/utils/logger.dart';

/// Service untuk handle local notifications
/// No Firebase needed - works with Appwrite Realtime
class LocalNotificationService {
  LocalNotificationService._();
  static final instance = LocalNotificationService._();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  /// Initialize notification service
  Future<void> initialize() async {
    if (_initialized) return;

    AppLogger.info('📢 [NOTIFICATIONS] Initializing local notifications...');

    // Android settings
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS settings  
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    // Initialize with callback for notification taps
    await _notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    _initialized = true;
    AppLogger.info('✅ [NOTIFICATIONS] Local notifications initialized');
  }

  /// Request notification permissions
  Future<bool> requestPermissions() async {
    AppLogger.info('🔔 [NOTIFICATIONS] Requesting permissions...');

    // Android 13+ requires runtime permission
    final androidImplementation =
        _notifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      final granted = await androidImplementation.requestNotificationsPermission();
      AppLogger.info('📱 [NOTIFICATIONS] Android permission: $granted');
      return granted ?? false;
    }

    // iOS
    final iosImplementation =
        _notifications.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();

    if (iosImplementation != null) {
      final granted = await iosImplementation.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      AppLogger.info('🍎 [NOTIFICATIONS] iOS permission: $granted');
      return granted ?? false;
    }

    return true; // Fallback for older Android versions
  }

  /// Show notification for new order
  Future<void> showOrderNotification({
    required String orderId,
    required String orderNumber,
    required String customerName,
  }) async {
    AppLogger.info('📢 [NOTIFICATIONS] Showing notification for order: $orderNumber');

    const androidDetails = AndroidNotificationDetails(
      'orders_channel', // Channel ID
      'Order Notifications', // Channel name
      channelDescription: 'Notifications for new customer orders',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      styleInformation: BigTextStyleInformation(''),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      orderId.hashCode, // Unique ID from orderId
      '🛒 Pesanan Baru!', // Title
      'Pesanan #$orderNumber dari $customerName', // Body
      notificationDetails,
      payload: orderId, // Pass orderId for navigation
    );

    AppLogger.info('✅ [NOTIFICATIONS] Notification shown');
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    final orderId = response.payload;
    AppLogger.info('👆 [NOTIFICATIONS] Notification tapped, orderId: $orderId');

    if (orderId != null) {
      // Navigation will be handled by NotificationProvider
      // which listens to this callback
      _notificationTapController.add(orderId);
    }
  }

  /// Stream controller for notification taps
  final _notificationTapController = StreamController<String>.broadcast();

  /// Stream of notification taps (orderId)
  Stream<String> get onNotificationTap => _notificationTapController.stream;

  /// Dispose resources
  void dispose() {
    _notificationTapController.close();
  }
}
