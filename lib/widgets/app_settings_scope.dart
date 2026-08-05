import 'package:flutter/material.dart';
import '../providers/app_settings_controller.dart';
import '../models/app_settings.dart';

class AppSettingsScope extends InheritedNotifier<AppSettingsController> {
  AppSettingsScope({
    super.key,
    required this.controller,
    required Widget child,
  }) : super(notifier: controller, child: child);

  final AppSettingsController controller;

  static AppSettingsController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppSettingsScope>();
    assert(scope != null, 'AppSettingsScope not found in widget tree');
    return scope!.controller; // ✅ সরাসরি নিজস্ব ফিল্ড থেকে, notifier-এর ওপর নির্ভর না করে
  }

  static AppSettings settingsOf(BuildContext context) => of(context).settings;
}