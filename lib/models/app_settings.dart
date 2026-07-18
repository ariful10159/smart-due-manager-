import 'package:flutter/material.dart';

class AppSettings {
  final int accentColorValue;
  final bool isDarkMode;
  final String currencySymbol;
  final String businessName;
  final String businessAddress;
  final String? businessLogoUrl;

  // ✅ নতুন যোগ করা ফিল্ডগুলো
  final String smsReminderTemplate;
  final double fontScale;
  final bool appLockEnabled;
  final String? appLockPinHash;

  const AppSettings({
    required this.accentColorValue,
    required this.isDarkMode,
    required this.currencySymbol,
    required this.businessName,
    required this.businessAddress,
    this.businessLogoUrl,
    required this.smsReminderTemplate,
    required this.fontScale,
    required this.appLockEnabled,
    this.appLockPinHash,
  });

  Color get accentColor => Color(accentColorValue);

  factory AppSettings.defaults() => const AppSettings(
        accentColorValue: 0xFF6366F1,
        isDarkMode: true,
        currencySymbol: '৳',
        businessName: 'Smart Due',
        businessAddress: '',
        businessLogoUrl: null,
        smsReminderTemplate:
            'প্রিয় {name}, আপনার বকেয়া {amount} টাকা। অনুগ্রহ করে {due_date} এর মধ্যে পরিশোধ করুন। ধন্যবাদ — {business_name}',
        fontScale: 1.0,
        appLockEnabled: false,
        appLockPinHash: null,
      );

  factory AppSettings.fromMap(Map<String, dynamic> map) {
    final defaults = AppSettings.defaults();
    return AppSettings(
      accentColorValue: (map['accentColorValue'] as num?)?.toInt() ??
          defaults.accentColorValue,
      isDarkMode: map['isDarkMode'] as bool? ?? defaults.isDarkMode,
      currencySymbol:
          map['currencySymbol'] as String? ?? defaults.currencySymbol,
      businessName: map['businessName'] as String? ?? defaults.businessName,
      businessAddress:
          map['businessAddress'] as String? ?? defaults.businessAddress,
      businessLogoUrl: map['businessLogoUrl'] as String?,
      smsReminderTemplate: map['smsReminderTemplate'] as String? ??
          defaults.smsReminderTemplate,
      fontScale: (map['fontScale'] as num?)?.toDouble() ?? defaults.fontScale,
      appLockEnabled:
          map['appLockEnabled'] as bool? ?? defaults.appLockEnabled,
      appLockPinHash: map['appLockPinHash'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'accentColorValue': accentColorValue,
      'isDarkMode': isDarkMode,
      'currencySymbol': currencySymbol,
      'businessName': businessName,
      'businessAddress': businessAddress,
      'businessLogoUrl': businessLogoUrl,
      'smsReminderTemplate': smsReminderTemplate,
      'fontScale': fontScale,
      'appLockEnabled': appLockEnabled,
      'appLockPinHash': appLockPinHash,
    };
  }

  AppSettings copyWith({
    int? accentColorValue,
    bool? isDarkMode,
    String? currencySymbol,
    String? businessName,
    String? businessAddress,
    String? businessLogoUrl,
    String? smsReminderTemplate,
    double? fontScale,
    bool? appLockEnabled,
    String? appLockPinHash,
    bool clearPin = false,
  }) {
    return AppSettings(
      accentColorValue: accentColorValue ?? this.accentColorValue,
      isDarkMode: isDarkMode ?? this.isDarkMode,
      currencySymbol: currencySymbol ?? this.currencySymbol,
      businessName: businessName ?? this.businessName,
      businessAddress: businessAddress ?? this.businessAddress,
      businessLogoUrl: businessLogoUrl ?? this.businessLogoUrl,
      smsReminderTemplate: smsReminderTemplate ?? this.smsReminderTemplate,
      fontScale: fontScale ?? this.fontScale,
      appLockEnabled: appLockEnabled ?? this.appLockEnabled,
      appLockPinHash: clearPin ? null : (appLockPinHash ?? this.appLockPinHash),
    );
  }

  static const List<int> presetColors = [
    0xFF6366F1,
    0xFF8B5CF6,
    0xFF3B82F6,
    0xFF10B981,
    0xFFF59E0B,
    0xFFEF4444,
    0xFFEC4899,
    0xFF14B8A6,
  ];

  static const List<String> currencyOptions = ['৳', '\$', '€', '₹', '£'];

  static const List<double> fontScaleOptions = [0.9, 1.0, 1.1, 1.2, 1.35];

  // ✅ SMS টেমপ্লেটে ব্যবহারযোগ্য placeholder গুলো
  static const List<String> smsPlaceholders = [
    '{name}',
    '{amount}',
    '{due_date}',
    '{business_name}',
    '{phone}',
  ];
}