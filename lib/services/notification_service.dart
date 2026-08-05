import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest.dart' as tzData;
import 'package:timezone/timezone.dart' as tz;
import 'package:url_launcher/url_launcher.dart';

import '../utils/helpers.dart';

class NotificationService {
  static final _notifications = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    tzData.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const settings = InitializationSettings(android: androidSettings);

    await _notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // ✅ Notification permission (Android 13+)
    await Permission.notification.request();

    // ✅ Exact alarm permission (Android 12+) — এটা ছাড়া scheduled notification silently fail করে
    await Permission.scheduleExactAlarm.request();
  }

  // ✅ Notification ট্যাপ করলে (SMS reminder হলে) default SMS app prefilled
  // অবস্থায় খুলে দেওয়া হয় — Play Store policy অনুযায়ী app নিজে SMS পাঠাতে পারে না
  static Future<void> _onNotificationTapped(NotificationResponse response) async {
    final payload = response.payload;
    if (payload == null || payload.isEmpty) return;

    try {
      final data = jsonDecode(payload) as Map<String, dynamic>;
      final phone = data['phone'] as String?;
      final message = data['message'] as String?;
      if (phone == null || message == null) return;

      final uri = buildSmsComposeUri(phone, message);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    } catch (e) {
      debugPrint('❌ NOTIFICATION PAYLOAD PARSE FAILED: $e');
    }
  }

  // ✅ Reminder notification schedule করা — smsPhone/smsMessage দিলে notification
  // ট্যাপ করলে সেই কাস্টমারকে SMS পাঠানোর জন্য default SMS app খুলে যাবে
  static Future<void> scheduleReminder({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? smsPhone,
    String? smsMessage,
  }) async {
    final payload = (smsPhone != null && smsMessage != null)
        ? jsonEncode({'phone': smsPhone, 'message': smsMessage})
        : null;

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'reminder_channel',
          'Reminders',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );
  }

  // ✅ আগে schedule করা reminder notification বাতিল করা (reminder cancel/edit করলে)
  static Future<void> cancelReminder(int id) async {
    await _notifications.cancel(id);
    debugPrint('🗑️ REMINDER NOTIFICATION CANCELLED: $id');
  }
}
