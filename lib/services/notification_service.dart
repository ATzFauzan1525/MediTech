import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Background message received: ${message.messageId}');
}

class NotificationService {
  static final FirebaseMessaging _firebaseMessaging =
      FirebaseMessaging.instance;

  static const String _notifEnabledKey = 'notification_enabled';
  static const String _lastNotifDateKey = 'last_notif_date';
  static bool _initialized = false;

  static Future<void> initialize({bool requestPermissions = true}) async {
    if (_initialized) return;

    try {
      if (requestPermissions) {
        await _firebaseMessaging.requestPermission(
          alert: true,
          badge: true,
          sound: true,
        );

        final token = await _firebaseMessaging.getToken();
        debugPrint('FCM Token: $token');

        FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
        FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

        final initialMessage = await _firebaseMessaging.getInitialMessage();
        if (initialMessage != null) {
          _handleMessageOpenedApp(initialMessage);
        }
      }

      await checkAndShowNotification();
    } catch (e) {
      debugPrint('Notification init error: $e');
    } finally {
      _initialized = true;
    }
  }

  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    debugPrint('Foreground message: ${message.notification?.title}');
    final enabled = await isNotificationEnabled();
    if (!enabled) return;

    debugPrint('Notification received: ${message.notification?.body}');
  }

  static void _handleMessageOpenedApp(RemoteMessage message) {
    debugPrint('Message opened app: ${message.notification?.title}');
  }

  static Future<void> checkAndShowNotification() async {
    final enabled = await isNotificationEnabled();
    if (!enabled) return;

    final now = DateTime.now();
    final todayKey = '${now.year}-${now.month}-${now.day}';

    final prefs = await SharedPreferences.getInstance();
    final lastDate = prefs.getString(_lastNotifDateKey);

    if (lastDate != todayKey && now.hour >= 22) {
      await prefs.setString(_lastNotifDateKey, todayKey);
    }
  }

  // ===================== SETTINGS =====================

  static Future<bool> isNotificationEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_notifEnabledKey) ?? true;
    } catch (_) {
      return true;
    }
  }

  static Future<void> setNotificationEnabled(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_notifEnabledKey, enabled);
    } catch (_) {}
  }
}
