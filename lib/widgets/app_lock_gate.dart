import 'package:flutter/material.dart';

import '../screens/app_lock_screen.dart';
import '../widgets/app_settings_scope.dart';

class AppLockGate extends StatefulWidget {
  const AppLockGate({super.key, required this.child});

  final Widget child;

  @override
  State<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends State<AppLockGate> with WidgetsBindingObserver {
  bool _unlocked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // ✅ অ্যাপ ব্যাকগ্রাউন্ডে গেলে আবার লক হয়ে যাবে
    if (state == AppLifecycleState.paused) {
      final settings = AppSettingsScope.of(context).settings;
      if (settings.appLockEnabled) {
        setState(() => _unlocked = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = AppSettingsScope.of(context).settings;

    if (!settings.appLockEnabled || _unlocked) {
      return widget.child;
    }

    return AppLockScreen(
      mode: AppLockMode.unlock,
      onUnlocked: () => setState(() => _unlocked = true),
    );
  }
}