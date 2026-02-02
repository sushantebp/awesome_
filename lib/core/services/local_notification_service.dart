import 'dart:developer';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:injectable/injectable.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'dart:io';

@singleton
class LocalNotificationService {
  final _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  static const String _defaultChannelId = 'default_channel';
  static const String _defaultChannelName = 'Default Notification';

  static const String _scheduleChannelId = 'schedule_channel';
  static const String _scheduleChannelName = 'Schedule Notification';

  bool _initialized = false;

  /// Initialize notifications
  Future<void> init() async {
    if (_initialized) return;

    // 1️⃣ Initialize timezone for scheduled notifications
    tz.initializeTimeZones();

    // Dynamically get local timezone
    final TimezoneInfo currentTimeZone =
        await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(currentTimeZone.identifier));

    // 2️⃣ Android initialization settings
    const androidInitSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    // 3️⃣ iOS initialization settings
    const iosInitSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    // 4️⃣ Initialize plugin
    const initSettings = InitializationSettings(
      android: androidInitSettings,
      iOS: iosInitSettings,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // 5️⃣ Request runtime permissions (Android 13+)
    if (Platform.isAndroid) {
      final androidImpl = _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

      // Notification permission (Android 13+)
      await androidImpl?.requestNotificationsPermission();

      // Exact alarms permission (Android 12+)
      await androidImpl?.requestExactAlarmsPermission();
    } else if (Platform.isIOS) {
      final iosImplementation = _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();

      await iosImplementation?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    }

    _initialized = true;
  }

  /// Handle notification tap (must be static or top-level for background)
  @pragma('vm:entry-point')
  static void _onNotificationTap(NotificationResponse response) {
    log('Notification tapped!');
    log('Action ID: ${response.actionId}');
    log('Payload: ${response.payload}');
    log('Response ID: ${response.id}');

    // Handle navigation or actions based on payload
    // You can use a StreamController or callback to notify your app
  }

  /// Show immediate notification
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      _defaultChannelId,
      _defaultChannelName,
      channelDescription: 'General notifications',
      importance: Importance.high,
      priority: Priority.high,
      ticker: 'ticker',
      icon: '@mipmap/ic_launcher',
      playSound: true,
      enableVibration: true,
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

    await _flutterLocalNotificationsPlugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: notificationDetails,
      payload: payload,
    );
  }

  /// Schedule notification for a specific date/time
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    // Convert to timezone aware datetime
    final tzScheduledDate = tz.TZDateTime.from(scheduledDate, tz.local);

    const androidDetails = AndroidNotificationDetails(
      _scheduleChannelId,
      _scheduleChannelName,
      channelDescription: 'Notifications scheduled in advance',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      playSound: true,
      enableVibration: true,
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

    await _flutterLocalNotificationsPlugin.zonedSchedule(
      id: id,
      scheduledDate: tzScheduledDate,
      title: title,
      body: body,
      notificationDetails: notificationDetails,
      payload: payload,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  /// Schedule daily notification at specific time
  Future<void> scheduleDailyNotification({
    required int id,
    required String title,
    required String body,
    required TimeOfDayValue time,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'daily_channel',
      'Daily Channel',
      channelDescription: 'Daily recurring notifications',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      playSound: true,
      enableVibration: true,
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

    await _flutterLocalNotificationsPlugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      notificationDetails: notificationDetails,
      payload: payload,
      scheduledDate: _nextInstanceOfTime(time),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  /// Schedule weekly notification
  Future<void> scheduleWeeklyNotification({
    required int id,
    required String title,
    required String body,
    required int weekday, // 1 = Monday, 7 = Sunday
    required TimeOfDayValue time,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'weekly_channel',
      'Weekly Channel',
      channelDescription: 'Weekly recurring notifications',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      playSound: true,
      enableVibration: true,
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

    await _flutterLocalNotificationsPlugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      notificationDetails: notificationDetails,
      payload: payload,
      scheduledDate: _nextInstanceOfDayAndTime(weekday, time),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  /// Helper: Get next instance of specific time
  tz.TZDateTime _nextInstanceOfTime(TimeOfDayValue time) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
      time.second,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    return scheduledDate;
  }

  /// Helper: Get next instance of specific day and time
  tz.TZDateTime _nextInstanceOfDayAndTime(int weekday, TimeOfDayValue time) {
    tz.TZDateTime scheduledDate = _nextInstanceOfTime(time);

    while (scheduledDate.weekday != weekday) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    return scheduledDate;
  }

  /// Get all pending notifications
  Future<List<PendingNotificationRequest>> getPendingNotifications() async =>
      await _flutterLocalNotificationsPlugin.pendingNotificationRequests();

  /// Get all active notifications (Android only)
  Future<List<ActiveNotification>> getActiveNotifications() async {
    if (Platform.isAndroid) {
      final androidImpl = _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

      return await androidImpl?.getActiveNotifications() ?? [];
    }
    return [];
  }

  /// Cancel a notification by ID
  Future<void> cancelNotification(int id) async {
    await _flutterLocalNotificationsPlugin.cancel(id: id);
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
  }

  /// Check if notifications are enabled
  Future<bool?> areNotificationsEnabled() async {
    if (Platform.isAndroid) {
      final androidImpl = _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      return await androidImpl?.areNotificationsEnabled();
    }
    return null;
  }
}

class TimeOfDayValue {
  final int hour;
  final int minute;
  final int second;

  const TimeOfDayValue({required this.hour, this.minute = 0, this.second = 0});
}
