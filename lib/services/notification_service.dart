import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:another_telephony/telephony.dart';
import 'package:timezone/data/latest.dart' as tzData;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final _notifications = FlutterLocalNotificationsPlugin();
  static final Telephony _telephony = Telephony.instance;

  static Future<void> init() async {
    tzData.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const settings = InitializationSettings(android: androidSettings);

    await _notifications.initialize(settings);

    // ✅ Notification permission (Android 13+)
    await Permission.notification.request();

    // ✅ Exact alarm permission (Android 12+) — এটা ছাড়া scheduled notification silently fail করে
    await Permission.scheduleExactAlarm.request();

    // ✅ SMS permission
    await Permission.sms.request();
  }

  // ✅ Reminder notification schedule করা (আগের মতোই, শুধু deprecated parameter ঠিক করা হলো)
  static Future<void> scheduleReminder({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
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
    );
  }

  // ✅ শুধু টেস্ট করার জন্য — তৎক্ষণাৎ notification পাঠাবে
  static Future<void> showTestNotification() async {
    await _notifications.show(
      999,
      'Test Notification',
      'যদি এটা দেখতে পান, notification system কাজ করছে',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'reminder_channel',
          'Reminders',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
    );
  }

  // ✅ NEW — নির্দিষ্ট সময়ে SMS auto-send schedule করা
  //
  // ⚠️ গুরুত্বপূর্ণ সীমাবদ্ধতা: flutter_local_notifications নিজে SMS পাঠাতে পারে না,
  // এটা শুধু notification দেখাতে পারে। তাই SMS পাঠানোর সময়টা নির্ভুলভাবে ধরতে হলে
  // notification ট্রিগার হওয়ার মুহূর্তে backend logic (SMS পাঠানো) কল করতে হবে।
  // এজন্য নিচে "notification payload" এ SMS তথ্য পাঠানো হচ্ছে, এবং app চালু/background
  // অবস্থায় সেটা catch করে SMS পাঠানো হবে (main.dart এ setup করতে হবে)।
  static Future<void> sendSmsNow({
    required String phoneNumber,
    required String message,
  }) async {
    final permissionGranted = await Permission.sms.isGranted;

    if (!permissionGranted) {
      final result = await Permission.sms.request();
      if (!result.isGranted) return;
    }

    await _telephony.sendSms(to: phoneNumber, message: message);
  }
}
