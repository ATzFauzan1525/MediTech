import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationService {
  static final FirebaseMessaging _firebaseMessaging =
      FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const String _notifEnabledKey = 'notification_enabled';
  static bool _initialized = false;

  // ===================== INIT =====================

  static Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    tz.initializeTimeZones();

    try {
      await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
    } catch (_) {}

    try {
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const InitializationSettings initializationSettings =
          InitializationSettings(android: initializationSettingsAndroid);

      await _localNotifications.initialize(initializationSettings);
    } catch (_) {}

    try {
      FirebaseMessaging.onMessage.listen(_showLocalNotification);
      FirebaseMessaging.onBackgroundMessage(_backgroundMessageHandler);
    } catch (_) {}
  }

  static Future<void> _backgroundMessageHandler(
      RemoteMessage message) async {}

  static Future<void> _showLocalNotification(RemoteMessage message) async {
    final enabled = await isNotificationEnabled();
    if (!enabled) return;

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'medisync_channel',
      'MediSync Notifications',
      importance: Importance.high,
      priority: Priority.high,
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await _localNotifications.show(
      0,
      message.notification?.title ?? 'MediSync',
      message.notification?.body ?? '',
      platformChannelSpecifics,
    );
  }

  // ===================== DAILY REMINDER =====================

  static Future<void> scheduleDailyReminder() async {
    final enabled = await isNotificationEnabled();
    if (!enabled) {
      await cancelDailyReminder();
      return;
    }

    await _localNotifications.cancel(1);

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'medisync_daily',
      'Daily Health Reminder',
      importance: Importance.high,
      priority: Priority.high,
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      22,
      0,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await _localNotifications.zonedSchedule(
      1,
      'MediSync Reminder',
      'Jangan lupa catat data kesehatanmu hari ini.',
      scheduledDate,
      platformChannelSpecifics,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  static Future<void> cancelDailyReminder() async {
    await _localNotifications.cancel(1);
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

      if (enabled) {
        await scheduleDailyReminder();
      } else {
        await cancelDailyReminder();
      }
    } catch (_) {}
  }
}
