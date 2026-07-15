import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:workmanager/workmanager.dart';
import 'package:another_telephony/telephony.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
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
          try {
            await WakelockPlus.enable();
            debugPrint('🔓 WakeLock enabled');
          } catch (e) {
            debugPrint('⚠️ WakeLock enable failed (non-critical): $e');
          }

          debugPrint('⏳ Waiting 5 seconds for radio to warm up...');
          await Future.delayed(const Duration(seconds: 5));

          final telephony = Telephony.instance;
          bool sendSucceeded = false;
          int attempts = 0;

          while (!sendSucceeded && attempts < 3) {
            attempts++;
            final completer = Completer<bool>();

            debugPrint('🚀 Sending SMS, Attempt: $attempts');

            await telephony.sendSms(
              to: phone,
              message: message,
              statusListener: (status) {
                debugPrint(
                  '📊 [BACKGROUND] SMS STATUS attempt=$attempts ($phone): $status',
                );
                if (!completer.isCompleted) {
                  completer.complete(true);
                }
              },
            );

            sendSucceeded = await completer.future.timeout(
              const Duration(seconds: 20),
              onTimeout: () {
                debugPrint('⏳ Attempt $attempts timed out.');
                return false;
              },
            );

            if (!sendSucceeded && attempts < 3) {
              debugPrint(
                '⚠️ Attempt $attempts failed/timed out, retrying in 3s...',
              );
              await Future.delayed(const Duration(seconds: 3));
            }
          }

          debugPrint(
            sendSucceeded
                ? '✅ SMS confirmed sent after $attempts attempt(s)'
                : '❌ SMS failed after $attempts attempts',
          );
        } catch (e, stackTrace) {
          debugPrint('❌ SMS SEND FAILED: $e');
          debugPrint('❌ STACK TRACE: $stackTrace');
        } finally {
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
        appBarTheme: const AppBarTheme(centerTitle: true, elevation: 2),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorSchemeSeed: Colors.deepPurple,
      ),
      // ✅ AuthWrapper দিয়ে ঠিক করা হচ্ছে login করা আছে নাকি না
      home: const AuthWrapper(),
    );
  }
}

// ✅ Login state অনুযায়ী HomeScreen বা LoginScreen দেখানো হচ্ছে
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData) {
          return const HomeScreen();
        }

        return const LoginScreen();
      },
    );
  }
}