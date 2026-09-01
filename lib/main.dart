import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart' show FlutterQuillLocalizations;

import 'firebase_options.dart';
import 'l10n/app_localizations.dart';
import 'providers/app_settings_controller.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/splash_screen.dart';
import 'services/notification_service.dart';
import 'widgets/app_settings_scope.dart';
import 'widgets/app_lock_gate.dart'; // ✅ AppLockGate ইমপোর্ট করা হলো
import 'widgets/account_status_gate.dart'; // ✅ Admin panel থেকে disabled হলে ব্লক করার জন্য
import 'widgets/app_config_gate.dart'; // ✅ Admin panel থেকে maintenance/force-update ব্লক করার জন্য
import 'widgets/policy_acceptance_gate.dart'; // ✅ পলিসি আপডেট হলে re-accept করানোর জন্য

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // ✅ Crashlytics ওয়েবে সাপোর্টেড না, তাই শুধু native প্ল্যাটফর্মে চালু করা হয়
  if (!kIsWeb) {
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
  }

  await NotificationService.init();

  // ✅ App Settings controller ইনিশিয়ালাইজ করা হচ্ছে (theme, currency, business info)
  final settingsController = AppSettingsController();
  await settingsController.init();

  runApp(SmartDueApp(settingsController: settingsController));

  // ✅ runApp() এর পরে — এই permission dialog গুলো await করলে (main() এর ভেতরে
  // থাকলে) কিছু ডিভাইসে/Android ভার্সনে Flutter এর প্রথম frame আঁকার আগেই আটকে
  // যেতে পারে, ফলে ব্যবহারকারী শুধু কালো স্ক্রিন দেখে
  unawaited(NotificationService.requestPermissions());
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
              AppLocalizations.delegate,
              FlutterQuillLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [Locale('en'), Locale('bn')],
            locale: Locale(settings.languageCode),
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
            // ✅ AppConfigGate সবচেয়ে বাইরে — login এর আগেও maintenance/force-update ব্লক করার জন্য
            home: AppConfigGate(child: AppLockGate(child: const AuthWrapper())),
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
          return const AccountStatusGate(child: PolicyAcceptanceGate(child: HomeScreen()));
        }

        return const LoginScreen();
      },
    );
  }
}