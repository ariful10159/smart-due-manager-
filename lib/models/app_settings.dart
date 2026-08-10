import 'package:flutter/material.dart';

class AppSettings {
  final int accentColorValue;
  final bool isDarkMode;
  final String currencySymbol;
  final String businessName;
  final String ownerName;
  final String businessAddress;
  final String? businessLogoUrl;

  // ✅ নতুন যোগ করা ফিল্ডগুলো
  final String smsReminderTemplate;
  // ✅ কাস্টমারের বকেয়া সম্পূর্ণ পরিশোধ (৳0) হয়ে গেলে due-reminder টেমপ্লেটের
  // বদলে এই ধন্যবাদ টেমপ্লেট ব্যবহার হয়
  final String fullPaymentThankYouTemplate;
  final double fontScale;
  final bool appLockEnabled;
  final String? appLockPinHash;

  const AppSettings({
    required this.accentColorValue,
    required this.isDarkMode,
    required this.currencySymbol,
    required this.businessName,
    this.ownerName = '',
    required this.businessAddress,
    this.businessLogoUrl,
    required this.smsReminderTemplate,
    required this.fullPaymentThankYouTemplate,
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
        ownerName: '',
        businessAddress: '',
        businessLogoUrl: null,
        smsReminderTemplate:
            'প্রিয় {name}, আপনার বকেয়া {amount} টাকা। অনুগ্রহ করে {due_date} এর মধ্যে পরিশোধ করুন। ধন্যবাদ — {business_name}',
        fullPaymentThankYouTemplate:
            'প্রিয় {name}, আপনার সম্পূর্ণ বকেয়া পরিশোধ হয়ে গেছে। আমাদের সাথে থাকার জন্য অনেক ধন্যবাদ! — {business_name}',
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
      ownerName: map['ownerName'] as String? ?? defaults.ownerName,
      businessAddress:
          map['businessAddress'] as String? ?? defaults.businessAddress,
      businessLogoUrl: map['businessLogoUrl'] as String?,
      smsReminderTemplate: map['smsReminderTemplate'] as String? ??
          defaults.smsReminderTemplate,
      fullPaymentThankYouTemplate: map['fullPaymentThankYouTemplate'] as String? ??
          defaults.fullPaymentThankYouTemplate,
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
      'ownerName': ownerName,
      'businessAddress': businessAddress,
      'businessLogoUrl': businessLogoUrl,
      'smsReminderTemplate': smsReminderTemplate,
      'fullPaymentThankYouTemplate': fullPaymentThankYouTemplate,
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
    String? ownerName,
    String? businessAddress,
    String? businessLogoUrl,
    String? smsReminderTemplate,
    String? fullPaymentThankYouTemplate,
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
      ownerName: ownerName ?? this.ownerName,
      businessAddress: businessAddress ?? this.businessAddress,
      businessLogoUrl: businessLogoUrl ?? this.businessLogoUrl,
      smsReminderTemplate: smsReminderTemplate ?? this.smsReminderTemplate,
      fullPaymentThankYouTemplate:
          fullPaymentThankYouTemplate ?? this.fullPaymentThankYouTemplate,
      fontScale: fontScale ?? this.fontScale,
      appLockEnabled: appLockEnabled ?? this.appLockEnabled,
      appLockPinHash: clearPin ? null : (appLockPinHash ?? this.appLockPinHash),
    );
  }

  static const List<int> presetColors = [
    0xFF6366F1, // Indigo
    0xFF8B5CF6, // Violet
    0xFF3B82F6, // Blue
    0xFF0EA5E9, // Sky
    0xFF06B6D4, // Cyan
    0xFF14B8A6, // Teal
    0xFF10B981, // Emerald
    0xFF22C55E, // Green
    0xFFEAB308, // Yellow
    0xFFF59E0B, // Amber
    0xFFF97316, // Orange
    0xFFEF4444, // Red
    0xFFF43F5E, // Rose
    0xFFEC4899, // Pink
    0xFFD946EF, // Fuchsia
    0xFF64748B, // Slate
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

  // ✅ Full-payment thank-you টেমপ্লেটে {amount}/{due_date} অর্থহীন (বকেয়া ৳0),
  // তাই এখানে আলাদা, ছোট placeholder লিস্ট
  static const List<String> thankYouPlaceholders = [
    '{name}',
    '{business_name}',
    '{phone}',
  ];
}