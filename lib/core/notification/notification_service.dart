import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../../features/tasks/models/task.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
  FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    tz.initializeTimeZones();

    // ✅ FIXED timezone (NO CRASH)
    final dynamic timeZoneData =
    await FlutterTimezone.getLocalTimezone();

    final String timeZoneName = timeZoneData is String
        ? timeZoneData
        : timeZoneData.name;

    tz.setLocalLocation(tz.getLocation(timeZoneName));

    const androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
      onDidReceiveBackgroundNotificationResponse:
      _onBackgroundNotificationTap,
    );

    await _requestPermissions();
  }

  static void _onNotificationTap(NotificationResponse response) {
    debugPrint('Notification tapped: ${response.payload}');
  }

  @pragma('vm:entry-point')
  static void _onBackgroundNotificationTap(
      NotificationResponse response) {
    debugPrint(
        'Background notification tapped: ${response.payload}');
  }

  static Future<void> _requestPermissions() async {
    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      await androidPlugin.requestExactAlarmsPermission();
    }

    final iosPlugin = _plugin
        .resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();

    await iosPlugin?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );

    final macPlugin = _plugin
        .resolvePlatformSpecificImplementation<
        MacOSFlutterLocalNotificationsPlugin>();

    await macPlugin?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  static Future<void> scheduleTaskReminder(Task task) async {
    await cancelTaskReminder(task);

    if (task.status == TaskStatus.done) return;

    final dueDate = task.dueDate;
    final now = DateTime.now();

    final tomorrowReminder = DateTime(
      dueDate.year,
      dueDate.month,
      dueDate.day,
      9,
    ).subtract(const Duration(days: 1));

    final todayReminder = DateTime(
      dueDate.year,
      dueDate.month,
      dueDate.day,
      9,
    );

    if (tomorrowReminder.isAfter(now)) {
      await _scheduleNotification(
        id: task.id.hashCode.abs(),
        title: '⏰ Task Due Tomorrow',
        body: '"${task.title}" is due tomorrow!',
        scheduledTime: tomorrowReminder,
      );
    }

    if (todayReminder.isAfter(now)) {
      await _scheduleNotification(
        id: (task.id.hashCode + 1).abs(),
        title: '🔴 Task Due Today!',
        body: '"${task.title}" is due today.',
        scheduledTime: todayReminder,
      );
    }
  }

  static Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    final tz.TZDateTime tzTime =
    tz.TZDateTime.from(scheduledTime, tz.local);

    const androidDetails = AndroidNotificationDetails(
      'task_reminders',
      'Task Reminders',
      channelDescription:
      'Reminders for upcoming task due dates',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: Color(0xFF7C3AED),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
      macOS: iosDetails,
    );

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      tzTime,
      details,
      androidScheduleMode:
      AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.absoluteTime,
    );
  }
  static Future<void> debugTestNotification() async {
    debugPrint("🚀 Starting notification test...");

    // 1️⃣ Check permission
    final enabled = await areNotificationsEnabled();
    debugPrint("🔔 Notifications enabled: $enabled");

    // 2️⃣ Instant notification test
    await showInstant(
      title: "✅ Instant Test",
      body: "If you see this → instant works",
    );

    debugPrint("⚡ Instant notification triggered");

    // 3️⃣ Scheduled notification after 5 sec
    final testTime = DateTime.now().add(const Duration(seconds: 5));

    await _scheduleNotification(
      id: 999,
      title: "⏳ Scheduled Test",
      body: "If you see this → schedule works",
      scheduledTime: testTime,
    );

    debugPrint("⏰ Scheduled for: $testTime");
  }
  static Future<void> cancelTaskReminder(Task task) async {
    await _plugin.cancel(task.id.hashCode.abs());
    await _plugin.cancel((task.id.hashCode + 1).abs());
  }

  static Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  static Future<void> showInstant({
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'task_reminders',
      'Task Reminders',
      channelDescription:
      'Reminders for upcoming task due dates',
      importance: Importance.high,
      priority: Priority.high,
      color: Color(0xFF7C3AED),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
      macOS: iosDetails,
    );

    await _plugin.show(0, title, body, details);
  }

  static Future<bool> areNotificationsEnabled() async {
    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin == null) return true;

    return await androidPlugin.areNotificationsEnabled() ??
        true;
  }

   static Future<void> checkPermissions() async {
    final iosPlugin = _plugin
        .resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();

    if (iosPlugin != null) {
      final granted = await iosPlugin.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );

      debugPrint('iOS permission granted: $granted');
    }
  }
}

final notificationServiceProvider =
Provider<NotificationService>((ref) {
  return NotificationService();
});