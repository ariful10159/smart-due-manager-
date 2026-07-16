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

    // ✅ Multipart SMS (বাংলা/Unicode বা লম্বা মেসেজ) পাঠাতে SIM/subscription
    // info দরকার হয় (getGroupIdLevel1 ইত্যাদি) — এটা ছাড়া sendSms fail করে
    await Permission.phone.request();
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
    final smsGranted = await Permission.sms.isGranted;

    if (!smsGranted) {
      final result = await Permission.sms.request();
      if (!result.isGranted) {
        debugPrint('❌ SMS PERMISSION DENIED');
        return;
      }
    }

    // ✅ isMultipart: true হলে প্লাগইন SIM/subscription info পড়ে (getGroupIdLevel1
    // ইত্যাদি) — READ_PHONE_STATE ছাড়া সেটা fail করে এবং sendSms পুরোটাই থ্রো করে
    final phoneGranted = await Permission.phone.isGranted;
    if (!phoneGranted) {
      final result = await Permission.phone.request();
      if (!result.isGranted) {
        debugPrint('❌ PHONE (READ_PHONE_STATE) PERMISSION DENIED');
        return;
      }
    }

    final cleanPhone = phoneNumber.replaceAll(RegExp(r'[\s\-]'), '');

    try {
      await _telephony.sendSms(
        to: cleanPhone,
        message: message,
        // ✅ বাংলা/Unicode টেক্সট বা ১৬০ char এর বেশি length হলে multipart না দিলে
        // silently fail করে (কোনো status callback ই আসে না)
        isMultipart: true,
        statusListener: (status) {
          debugPrint('📊 SMS STATUS ($cleanPhone): $status');
        },
      );
    } catch (e) {
      // ✅ platform exception (যেমন failed_to_fetch_sms) এলে যাতে পুরো অ্যাপ
      // crash না করে, সেটা এখানে ধরে ফেলা হচ্ছে
      debugPrint('❌ SMS SEND FAILED ($cleanPhone): $e');
    }
  }

  // ✅ নির্দিষ্ট সময়ে SMS পাঠানোর জন্য background task schedule করা  
  static Future<void> scheduleSms({    
    required String taskId,    
    required String phoneNumber,    
    required String message,    
    required DateTime scheduledDate,    
    required String customerId, // ✅ NEW — background log এর জন্য  
  }) async {    
    final delay = scheduledDate.difference(DateTime.now());    
    final cleanPhone = phoneNumber.replaceAll(RegExp(r'[\s\-]'), '');    
    
    debugPrint(
      '📱 [REMINDER FLOW] SMS SCHEDULE: taskId=$taskId, phone=$cleanPhone, '
      'scheduledDate=$scheduledDate, delay=$delay, customerId=$customerId',
    );

    if (delay.isNegative) {      
      debugPrint('❌ SMS SCHEDULE SKIPPED: delay is negative');      
      return;    
    }    
    
    await Workmanager().registerOneOffTask(      
      taskId,      
      'sendReminderSms',      
      initialDelay: delay,      
      inputData: {        
        'phone': cleanPhone,        
        'message': message,        
        'customerId': customerId, // ✅ NEW      
      },      
      existingWorkPolicy: ExistingWorkPolicy.replace,    
    );    
    
    debugPrint('✅ SMS TASK REGISTERED: $taskId (fires in $delay)');  
  }

  // ✅ আগে schedule করা SMS task বাতিল করা (reminder cancel/edit করলে)
  static Future<void> cancelScheduledSms(String taskId) async {
    await Workmanager().cancelByUniqueName(taskId);
    debugPrint('🗑️ SMS TASK CANCELLED: $taskId');
  }
}