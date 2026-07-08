import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'timezone_helper.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const String _notifEnabledKey = 'notification_enabled';
  static const String _lastNotifDateKey = 'last_notif_date';
  static bool _initialized = false;
  static bool _exactAlarmGranted = false;

  // ===================== INIT =====================

  static Future<void> initialize() async {
    if (_initialized) return;

    try {
      tz.initializeTimeZones();
      try {
        final String localTimeZone = TimezoneHelper.resolveLocalTimezone();
        tz.setLocalLocation(tz.getLocation(localTimeZone));
      } catch (e) {
        debugPrint(
          'Could not get local timezone, defaulting to system locale: $e',
        );
      }

      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const InitializationSettings initializationSettings =
          InitializationSettings(android: initializationSettingsAndroid);

      await _localNotifications.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (details) {
          debugPrint('Notification clicked: ${details.payload ?? ""}');
        },
      );

      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _localNotifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

      if (androidImplementation != null) {
        const AndroidNotificationChannel dailyChannel =
            AndroidNotificationChannel(
              'medisync_daily',
              'Daily Health Reminder',
              description: 'Pengingat harian untuk mengisi data kesehatan',
              importance: Importance.high,
              enableVibration: true,
            );

        await androidImplementation.createNotificationChannel(dailyChannel);
        final notificationsPermissionGranted =
            await androidImplementation.requestNotificationsPermission();
        debugPrint(
          'Notifications permission granted: $notificationsPermissionGranted',
        );

        if (Platform.isAndroid) {
          _exactAlarmGranted =
              await androidImplementation.requestExactAlarmsPermission() ??
              false;
          debugPrint('Exact alarm permission granted: $_exactAlarmGranted');
        }
      } else {
        _exactAlarmGranted = true;
      }

      await scheduleDailyReminder();
      await _checkAndShowScheduledNotification();
    } catch (e) {
      debugPrint('Notification init error: $e');
    } finally {
      _initialized = true;
    }
  }

  // ===================== CHECK SCHEDULED NOTIFICATION =====================

  static Future<void> checkAndShowNotification() async {
    final enabled = await isNotificationEnabled();
    if (!enabled) return;

    final now = DateTime.now();
    final todayKey = '${now.year}-${now.month}-${now.day}';

    final prefs = await SharedPreferences.getInstance();
    final lastDate = prefs.getString(_lastNotifDateKey);

    if (lastDate != todayKey && now.hour >= 22) {
      await showDailyReminder();
      await prefs.setString(_lastNotifDateKey, todayKey);
    }
  }

  static Future<void> _checkAndShowScheduledNotification() async {
    await checkAndShowNotification();
  }

  // ===================== TEST NOTIFICATION =====================

  static Future<bool> showTestNotification() async {
    final enabled = await isNotificationEnabled();
    if (!enabled) return false;

    try {
      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
            'medisync_daily',
            'Daily Health Reminder',
            importance: Importance.high,
            priority: Priority.high,
          );

      const NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
      );

      await _localNotifications.show(
        999,
        'MediSync Test',
        'Notifikasi berhasil! Kamu akan diingatkan setiap jam 22:00.',
        platformChannelSpecifics,
      );
      return true;
    } catch (e) {
      debugPrint('Test notification error: $e');
      return false;
    }
  }

  // ===================== DAILY REMINDER =====================

  static Future<AndroidScheduleMode> _resolveScheduleMode() async {
    if (Platform.isAndroid && !_exactAlarmGranted) {
      final androidImplementation =
          _localNotifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

      if (androidImplementation != null) {
        try {
          _exactAlarmGranted =
              await androidImplementation.requestExactAlarmsPermission() ??
              false;
        } catch (e) {
          debugPrint('Exact alarm permission request error: $e');
        }
      }
    }

    return _exactAlarmGranted
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;
  }

  static DateTime computeNextReminderTime([DateTime? now]) {
    final base = now ?? DateTime.now();
    final candidate = DateTime(base.year, base.month, base.day, 22, 0);

    if (!candidate.isAfter(base)) {
      return candidate.add(const Duration(days: 1));
    }

    return candidate;
  }

  static Future<bool> scheduleDailyReminder() async {
    final enabled = await isNotificationEnabled();
    if (!enabled) {
      await cancelDailyReminder();
      return false;
    }

    await _localNotifications.cancel(1);

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'medisync_daily',
          'Daily Health Reminder',
          importance: Importance.high,
          priority: Priority.high,
        );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    final now = tz.TZDateTime.now(tz.local);
    final prefs = await SharedPreferences.getInstance();
    final lastDate = prefs.getString(_lastNotifDateKey);
    final todayKey = '${now.year}-${now.month}-${now.day}';

    final nextReminderTime = computeNextReminderTime(DateTime(now.year, now.month, now.day, now.hour, now.minute, now.second));
    var scheduledDate = tz.TZDateTime.from(nextReminderTime, tz.local);

    try {
      final nowForFallback = DateTime.now();
      if (lastDate != todayKey && nowForFallback.hour >= 22) {
        await showDailyReminder();
        await prefs.setString(_lastNotifDateKey, todayKey);
        return true;
      }

      final scheduleMode = await _resolveScheduleMode();
      debugPrint('Scheduling daily reminder at: $scheduledDate with mode: $scheduleMode');
      await _localNotifications.zonedSchedule(
        1,
        'MediSync Reminder',
        'Jangan lupa catat data kesehatanmu hari ini.',
        scheduledDate,
        platformChannelSpecifics,
        androidScheduleMode: scheduleMode,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
      debugPrint('Daily reminder scheduled successfully');
      return true;
    } catch (e) {
      debugPrint('Schedule notification error: $e');
      return false;
    }
  }

  static Future<void> showDailyReminder() async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'medisync_daily',
          'Daily Health Reminder',
          importance: Importance.high,
          priority: Priority.high,
        );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    await _localNotifications.show(
      1,
      'MediSync Reminder',
      'Jangan lupa catat data kesehatanmu hari ini.',
      platformChannelSpecifics,
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
