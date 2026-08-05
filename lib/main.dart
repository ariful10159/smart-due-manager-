import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart' show FlutterQuillLocalizations;
import 'package:workmanager/workmanager.dart';
import 'package:another_telephony/telephony.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'providers/app_settings_controller.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/splash_screen.dart';
import 'services/notification_service.dart';
import 'utils/helpers.dart';
import 'widgets/app_settings_scope.dart';
import 'widgets/app_lock_gate.dart'; // ✅ AppLockGate ইমপোর্ট করা হলো

// ✅ Background task handler
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    debugPrint('🔔 WORKMANAGER TASK TRIGGERED: $task at ${DateTime.now()}');

    if (task == 'sendReminderSms') {
      final rawPhone = inputData?['phone'] as String?;
      final message = inputData?['message'] as String?;

      final phone = rawPhone?.replaceAll(RegExp(r'[\s\-]'), '');

      debugPrint('📤 ATTEMPTING SMS: phone=${maskPhone(phone)}');

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
                  '📊 [BACKGROUND] SMS STATUS attempt=$attempts (${maskPhone(phone)}): $status',
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

          // ✅ SMS পাঠানো সফল হলে Firestore এ log রাখা হচ্ছে
          if (sendSucceeded) {
            final customerId = inputData?['customerId'] as String?;
            if (customerId != null) {
              try {
                await Firebase.initializeApp();
                await FirebaseFirestore.instance
                    .collection('customers')
                    .doc(customerId)
                    .collection('smsLogs')
                    .add({
                      'sentAt': Timestamp.now(),
                      'type': 'reminder',
                    });
                debugPrint('📝 SMS log saved for customer $customerId');
              } catch (e) {
                debugPrint('⚠️ Failed to log SMS (non-critical): $e');
              }
            }
          }
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

  // ✅ ক্র্যাশ রিপোর্টিং — debug build এ ড্যাশবোর্ড স্প্যাম এড়াতে collection বন্ধ রাখা হয়,
  // release/profile build এ চালু থাকে।
  await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(!kDebugMode);

  // ✅ Flutter framework এর ভেতরের (widget build/layout ইত্যাদি) fatal error গুলো Crashlytics এ পাঠানো
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

  // ✅ Flutter framework এর বাইরের (async gap, isolate) error গুলোও ধরার জন্য
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  await NotificationService.init();
  await Workmanager().initialize(callbackDispatcher);

  // ✅ App Settings controller ইনিশিয়ালাইজ করা হচ্ছে (theme, currency, business info)
  final settingsController = AppSettingsController();
  await settingsController.init();

  runApp(SmartDueApp(settingsController: settingsController));
}

class SmartDueApp extends StatelessWidget {
  const SmartDueApp({super.key, required this.settingsController});

  final AppSettingsController settingsController;

  @override
  Widget build(BuildContext context) {
    return AppSettingsScope(
      controller: settingsController,
      child: AnimatedBuilder(
        animation: settingsController,
        builder: (context, _) {
          final settings = settingsController.settings;

          return MaterialApp(
            title: 'Smart Due',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              useMaterial3: true,
              brightness: Brightness.light,
              colorScheme: ColorScheme.fromSeed(
                seedColor: settings.accentColor,
                brightness: Brightness.light,
              ),
              appBarTheme: const AppBarTheme(centerTitle: true, elevation: 2),
            ),
            darkTheme: ThemeData(
              useMaterial3: true,
              brightness: Brightness.dark,
              colorScheme: ColorScheme.fromSeed(
                seedColor: settings.accentColor,
                brightness: Brightness.dark,
              ),
            ),
            themeMode: settings.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            localizationsDelegates: const [
              FlutterQuillLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [Locale('en')],
            builder: (context, child) {
              // ✅ Font scale পুরো অ্যাপে apply হচ্ছে
              final mediaQuery = MediaQuery.of(context);
              return MediaQuery(
                data: mediaQuery.copyWith(
                  textScaler: TextScaler.linear(settings.fontScale),
                ),
                child: child!,
              );
            },
            home: AppLockGate(child: const AuthWrapper()), // ✅ App lock wrap করা হলো
          );
        },
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SplashScreen();
        }

        if (snapshot.hasData) {
          return const HomeScreen();
        }

        return const LoginScreen();
      },
    );
  }
}