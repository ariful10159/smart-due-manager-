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
  }

  // ✅ Permission dialog গুলো ইচ্ছাকৃতভাবে main()/runApp() থেকে আলাদা রাখা হয়েছে —
  // এগুলো await করলে runApp() আটকে যায়, ফলে dialog resolve না হওয়া পর্যন্ত
  // Flutter এর প্রথম frame কখনো আঁকা হয় না (কিছু ডিভাইসে/Android ভার্সনে
  // exact alarm permission request silently hang করে — কালো স্ক্রিনে আটকে থাকার
  // এটাই আসল কারণ ছিল)। তাই এটা runApp() এর পর, UI দেখানোর পর ডাকা হয়।
  static Future<void> requestPermissions() async {
    // ✅ Android-নির্দিষ্ট runtime permission — ওয়েবে এই দুটোর কোনো অর্থ নেই এবং
    // scheduleExactAlarm ওয়েবে সাপোর্টেডই না (সরাসরি exception ছোঁড়ে)
    if (kIsWeb) return;

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

  // ✅ আগে schedule/cancel reminder দুটোতেই সরাসরি `customer.hashCode` ব্যবহার হতো —
  // কিন্তু Customer ক্লাসে hashCode override করা নেই, তাই Dart এর ডিফল্ট identity-based
  // hashCode ব্যবহার হতো, যেটা customer.id এর সাথে সম্পর্কহীন এবং প্রতিবার নতুন
  // Customer instance তৈরি হলেই (Firestore stream rebuild, app restart) বদলে যায়।
  // ফলে cancelReminder() আসল schedule করা notification-টা কখনো খুঁজেই পেত না —
  // stale/duplicate notification থেকে যেত। এখানে customer.id (স্থায়ী Firestore doc id)
  // থেকে নিজস্ব djb2 hash দিয়ে একটা সবসময়-একই int বানানো হচ্ছে — Dart এর
  // String.hashCode ব্যবহার করিনি কারণ সেটার exact algorithm ভবিষ্যতে অপরিবর্তিত
  // থাকার কোনো ভাষা-স্পেসিফিকেশন গ্যারান্টি নেই, এই ফাংশনটার আছে।
  static int reminderIdFor(String customerId) {
    var hash = 5381;
    for (final unit in customerId.codeUnits) {
      hash = ((hash << 5) + hash + unit) & 0x7fffffff;
    }
    return hash;
  }
}
