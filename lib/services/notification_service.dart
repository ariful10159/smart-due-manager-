import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tzData;
import 'package:timezone/timezone.dart' as tz;
import 'package:url_launcher/url_launcher.dart';

import '../route_observer.dart';
import '../screens/notifications_screen.dart';
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

    // ✅ চ্যানেল দুটো এখানেই আগে থেকে বানিয়ে রাখা হয় — নাহলে app চালু হওয়ার পর প্রথম
    // local notification schedule হওয়ার আগেই (cold-start এ) কোনো FCM push এলে
    // 'push_channel' চ্যানেলটা তখনো তৈরি না থাকায় Android O+ এ সেটা দেখানো যেত না।
    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        'reminder_channel',
        'Reminders',
        importance: Importance.max,
      ),
    );
    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        'push_channel',
        'Push Notifications',
        importance: Importance.max,
      ),
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

      // ✅ Foreground এ থাকা অবস্থায় দেখানো admin push ট্যাপ করলে Notifications
      // screen এ নিয়ে যাওয়া হয় (background/killed অবস্থায় ট্যাপ করলে এটা না,
      // FcmService.onMessageOpenedApp/getInitialMessage হ্যান্ডেল করে — ওগুলো
      // flutter_local_notifications-এর payload/response দিয়ে যায় না)।
      if (data['type'] == 'admin_push') {
        appNavigatorKey.currentState?.push(
          MaterialPageRoute(builder: (_) => const NotificationsScreen()),
        );
        return;
      }

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

  // ✅ Admin panel থেকে পাঠানো push, app foreground এ থাকা অবস্থায় দেখানোর জন্য —
  // Android foreground এ FCM notification payload নিজে থেকে system tray তে দেখায় না,
  // তাই flutter_local_notifications দিয়ে ম্যানুয়ালি দেখাতে হয় (দেখুন FcmService)।
  static Future<void> showPushNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    await _notifications.show(
      id,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'push_channel',
          'Push Notifications',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      payload: payload,
    );
  }

  // ✅ আগে schedule করা reminder notification বাতিল করা (reminder cancel/edit করলে)
  static Future<void> cancelReminder(int id) async {
    await _notifications.cancel(id);
    debugPrint('🗑️ REMINDER NOTIFICATION CANCELLED: $id');
  }

  // ✅ আগে customerId কে djb2 hash করে একটা int notification id বানানো হতো।
  // এটা customer.id এর সাথে সবসময় একই ম্যাপ হতো (আগের identity-hashCode বাগ
  // ঠিক করেছিল), কিন্তু hash হওয়ায় দুইজন ভিন্ন কাস্টমারের id একই সংখ্যায়
  // মিলে যাওয়ার (collision) সম্ভাবনা থেকেই যেত — কাস্টমার সংখ্যা কয়েকশ/হাজার
  // হলে birthday-paradox অনুযায়ী এই ঝুঁকি বাস্তব হয়ে ওঠে। Collision হলে
  // একজনের schedule করা notification অন্যজনেরটা silently overwrite করে
  // ফেলত — কেউ বুঝতেই পারত না কেন তার reminder notification আসছে না।
  //
  // এখন প্রতিটা customerId-কে ডিভাইসে (SharedPreferences) স্থায়ীভাবে একটা
  // sequential, guaranteed-unique id assign করে রাখা হয় — hash না হওয়ায়
  // কখনো দুইজনের id মিলবে না।
  static const _idMapKey = 'notification_id_map_v1';
  static const _nextIdKey = 'notification_next_id_v1';

  static Future<int> reminderIdFor(String customerId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_idMapKey);
    final map = raw != null
        ? Map<String, dynamic>.from(jsonDecode(raw) as Map)
        : <String, dynamic>{};

    final existing = map[customerId];
    if (existing is int) return existing;

    final nextId = prefs.getInt(_nextIdKey) ?? 1;
    map[customerId] = nextId;
    await prefs.setString(_idMapKey, jsonEncode(map));
    await prefs.setInt(_nextIdKey, nextId + 1);
    return nextId;
  }
}
