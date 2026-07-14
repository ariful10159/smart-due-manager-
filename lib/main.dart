import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:workmanager/workmanager.dart';
import 'package:another_telephony/telephony.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'screens/home_screen.dart';
import 'services/notification_service.dart';

// ✅ Background task handler — এটা অবশ্যই top-level function হতে হবে
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    debugPrint('🔔 WORKMANAGER TASK TRIGGERED: $task at ${DateTime.now()}');

    if (task == 'sendReminderSms') {
      final rawPhone = inputData?['phone'] as String?;
      final message = inputData?['message'] as String?;

      final phone = rawPhone?.replaceAll(RegExp(r'[\s\-]'), '');

      debugPrint('📤 ATTEMPTING SMS: phone=$phone, message=$message');

      if (phone != null && phone.isNotEmpty && message != null) {
        try {
          // ✅ WakeLock enable — background task চলাকালীন ফোন যেন
          // Doze mode এ চলে না যায়, network access বজায় থাকে
          try {
            await WakelockPlus.enable();
            debugPrint('🔓 WakeLock enabled');
          } catch (e) {
            debugPrint('⚠️ WakeLock enable failed (non-critical): $e');
          }

          final telephony = Telephony.instance;

          await telephony.sendSms(
            to: phone,
            message: message,
            statusListener: (status) {
              debugPrint('📊 [BACKGROUND] SMS STATUS ($phone): $status');
            },
          );

          debugPrint(
            '✅ sendSms() call completed for $phone (see status above)',
          );

          // ✅ Delivery status callback আসার জন্য যথেষ্ট সময় দেওয়া হচ্ছে
          await Future.delayed(const Duration(seconds: 15));
        } catch (e, stackTrace) {
          debugPrint('❌ SMS SEND FAILED: $e');
          debugPrint('❌ STACK TRACE: $stackTrace');
        } finally {
          // ✅ কাজ শেষে WakeLock disable করা — ব্যাটারি বাঁচাতে
          try {
            await WakelockPlus.disable();
            debugPrint('🔒 WakeLock disabled');
          } catch (e) {
            debugPrint('⚠️ WakeLock disable failed (non-critical): $e');
          }
        }
      } else {
        debugPrint('❌ SMS DATA MISSING: phone or message is null/empty');
      }
    } else {
      debugPrint('⚠️ UNKNOWN TASK RECEIVED: $task');
    }

    return Future.value(true);
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();
  await NotificationService.init();
  await Workmanager().initialize(callbackDispatcher, isInDebugMode: true);

  runApp(const SmartDueApp());
}

class SmartDueApp extends StatelessWidget {
  const SmartDueApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Due',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 2,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorSchemeSeed: Colors.deepPurple,
      ),
      home: const HomeScreen(),
    );
  }
}