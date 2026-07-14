import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:another_telephony/telephony.dart' hide NetworkType;
import 'package:timezone/data/latest.dart' as tzData;
import 'package:timezone/timezone.dart' as tz;
import 'package:workmanager/workmanager.dart';

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

    // ✅ SMS permission — app চালু হওয়ার সময় একবার নেওয়া হচ্ছে
    await Permission.sms.request();
  }

  // ✅ Reminder notification schedule করা
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

  // ✅ তৎক্ষণাৎ SMS পাঠানো (foreground থেকে)
  static Future<void> sendSmsNow({
    required String phoneNumber,
    required String message,
  }) async {
    final permissionGranted = await Permission.sms.isGranted;

    if (!permissionGranted) {
      final result = await Permission.sms.request();
      if (!result.isGranted) {
        debugPrint('❌ SMS PERMISSION DENIED');
        return;
      }
    }

    final cleanPhone = phoneNumber.replaceAll(RegExp(r'[\s\-]'), '');

    await _telephony.sendSms(
      to: cleanPhone,
      message: message,
      statusListener: (status) {
        debugPrint('📊 SMS STATUS ($cleanPhone): $status');
      },
    );
  }

  // ✅ নির্দিষ্ট সময়ে SMS পাঠানোর জন্য background task schedule করা
  static Future<void> scheduleSms({
    required String taskId,
    required String phoneNumber,
    required String message,
    required DateTime scheduledDate,
  }) async {
    final delay = scheduledDate.difference(DateTime.now());
    final cleanPhone = phoneNumber.replaceAll(RegExp(r'[\s\-]'), '');

    debugPrint(
      '📱 [REMINDER FLOW] SMS SCHEDULE: taskId=$taskId, phone=$cleanPhone, '
      'scheduledDate=$scheduledDate, delay=$delay',
    );

    if (delay.isNegative) {
      debugPrint('❌ [REMINDER FLOW] SKIPPED: delay is negative');
      return;
    }

    await Workmanager().registerOneOffTask(
      taskId,
      'sendReminderSms',
      initialDelay: delay,
      inputData: {
        'phone': cleanPhone,
        'message': message,
      },
      existingWorkPolicy: ExistingWorkPolicy.replace,
    );

    debugPrint('✅ [REMINDER FLOW] TASK REGISTERED: $taskId');
  }

  // ✅ আগে schedule করা SMS task বাতিল করা (reminder cancel/edit করলে)
  static Future<void> cancelScheduledSms(String taskId) async {
    await Workmanager().cancelByUniqueName(taskId);
    debugPrint('🗑️ SMS TASK CANCELLED: $taskId');
  }
}


