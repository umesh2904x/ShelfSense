// lib/services/notification_service.dart
// Handles local notifications for expiry reminders (Android/iOS only)

import 'dart:io' show Platform;
import 'dart:ui' show Color;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import '../models/product.dart';

/// Service class for scheduling and managing local notifications
/// Note: Local notifications only work on Android/iOS, not on web
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;
  bool _notificationsEnabled = false;

  /// Whether notifications are supported on current platform
  bool get isSupported => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  bool get notificationsEnabled => _notificationsEnabled;

  /// Initialize the notification plugin
  /// Must be called before scheduling any notifications
  Future<void> initialize() async {
    if (!isSupported) {
      // Notifications not supported on web
      return;
    }
    if (_isInitialized) return;

    // Initialize timezone database (required for scheduling)
    tz.initializeTimeZones();

    // Android initialization settings
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS initialization settings
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(initSettings);
    _isInitialized = true;
    await refreshPermissionStatus();
  }

  Future<void> refreshPermissionStatus() async {
    if (!isSupported) return;

    if (Platform.isAndroid) {
      final implementation =
          _notifications.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      _notificationsEnabled =
          await implementation?.areNotificationsEnabled() ?? false;
    } else {
      final implementation =
          _notifications.resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>();
      final status = await implementation?.checkPermissions();
      _notificationsEnabled = status?.isEnabled ?? false;
    }
  }

  Future<bool> requestPermission() async {
    if (!isSupported) return false;
    if (!_isInitialized) await initialize();

    if (Platform.isAndroid) {
      final implementation =
          _notifications.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (implementation != null) {
        final granted = await implementation.requestNotificationsPermission();
        _notificationsEnabled =
            granted ?? await implementation.areNotificationsEnabled() ?? false;
        if (_notificationsEnabled) {
          await implementation.requestExactAlarmsPermission();
        }
      }
    } else {
      final implementation =
          _notifications.resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>();
      _notificationsEnabled = await implementation?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          false;
    }
    return _notificationsEnabled;
  }

  /// Schedule reminders for a product
  /// Schedules 3 notifications: 7 days before, 3 days before, and on expiry day (at 9:00 AM)
  /// Skips any reminder that would be in the past
  Future<void> scheduleReminders(Product product) async {
    if (!isSupported || !_isInitialized || !_notificationsEnabled) return;

    final now = tz.TZDateTime.now(tz.local);
    final expiryDate = tz.TZDateTime.from(product.expiryDate, tz.local);

    // Reminder offsets: 7 days, 3 days, 0 days (expiry day)
    const reminders = [7, 3, 0];

    for (final daysBefore in reminders) {
      final reminderDate = expiryDate.subtract(Duration(days: daysBefore));

      // Set time to 9:00 AM
      final scheduledDate = tz.TZDateTime(
        tz.local,
        reminderDate.year,
        reminderDate.month,
        reminderDate.day,
        9, // 9:00 AM
        0,
      );

      // Skip if the scheduled time is already in the past
      if (scheduledDate.isBefore(now)) continue;

      // Create unique notification ID for this product + reminder combination
      final notificationId = _getNotificationId(product.id, daysBefore);

      // Create notification content
      const title = 'ShelfSense Reminder';
      final body = daysBefore == 0
          ? '${product.name} expires today!'
          : '${product.name} expires in $daysBefore day${daysBefore > 1 ? 's' : ''}';

      await _notifications.zonedSchedule(
        notificationId,
        title,
        body,
        scheduledDate,
        _notificationDetails(),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
  }

  /// Cancel all reminders for a specific product
  /// Called when product is edited or deleted
  Future<void> cancelReminders(String productId) async {
    if (!isSupported) return;

    const reminders = [7, 3, 0];
    for (final daysBefore in reminders) {
      final notificationId = _getNotificationId(productId, daysBefore);
      await _notifications.cancel(notificationId);
    }
  }

  /// Cancel all notifications (used for logout/cleanup)
  Future<void> cancelAll() async {
    if (!isSupported) return;
    await _notifications.cancelAll();
  }

  /// Generate a unique notification ID from product ID and days offset
  int _getNotificationId(String productId, int daysBefore) {
    final hash = productId.hashCode;
    return (hash ^ (daysBefore * 1000)).abs();
  }

  // Green primary color constant for notifications
  static const Color _notificationColor = Color(0xFF4CAF50);

  /// Notification details (appearance)
  NotificationDetails _notificationDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        'expiry_reminders', // Channel ID
        'Expiry Reminders', // Channel name
        channelDescription: 'Notifications for product expiry dates',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        color: _notificationColor, // Green primary color
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
  }
}
