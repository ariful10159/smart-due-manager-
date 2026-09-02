import 'package:flutter/material.dart';

class AppSettings {
  final int accentColorValue;
  final bool isDarkMode;
  final String currencySymbol;
  final String businessName;
  final String ownerName;
  final String businessAddress;
  final String? businessLogoUrl;
  // ✅ লগইন নাম্বার থেকে আলাদা — দোকানের যোগাযোগের নাম্বার, কাস্টমার কল-ব্যাক
  // করতে চাইলে বা SMS/PDF এ দেখানোর জন্য
  final String businessPhone;
  // ✅ কাস্টমার কোথায় টাকা পাঠাবে তা SMS/PDF এ দেখানোর জন্য দোকানের bKash/Nagad নাম্বার
  final String bkashNumber;

  // ✅ নতুন যোগ করা ফিল্ডগুলো
  final String smsReminderTemplate;
  // ✅ কাস্টমারের বকেয়া সম্পূর্ণ পরিশোধ (৳0) হয়ে গেলে due-reminder টেমপ্লেটের
  // বদলে এই ধন্যবাদ টেমপ্লেট ব্যবহার হয়
  final String fullPaymentThankYouTemplate;
  // ✅ আংশিক পেমেন্ট (কিছু টাকা দিলেন, কিছু বকেয়া থেকে গেল) হলে due-reminder এর
  // বদলে এই টেমপ্লেট ব্যবহার হয় — কত টাকা দিলেন ও কত বাকি রইল, দুটোই জানানো হয়
  final String partialPaymentThankYouTemplate;
  final double fontScale;
  final bool appLockEnabled;
  final String? appLockPinHash;
  // ✅ 'bn' বা 'en' — পুরো অ্যাপের ভাষা নিয়ন্ত্রণ করে
  final String languageCode;

  const AppSettings({
    required this.accentColorValue,
    required this.isDarkMode,
    required this.currencySymbol,
    required this.businessName,
    this.ownerName = '',
    required this.businessAddress,
    this.businessLogoUrl,
    this.businessPhone = '',
    this.bkashNumber = '',
    required this.smsReminderTemplate,
    required this.fullPaymentThankYouTemplate,
    required this.partialPaymentThankYouTemplate,
    required this.fontScale,
    required this.appLockEnabled,
    this.appLockPinHash,
    required this.languageCode,
  });

  Color get accentColor => Color(accentColorValue);

  factory AppSettings.defaults() => const AppSettings(
        accentColorValue: 0xFFEF4444, // Red — matches app's default theme
        isDarkMode: true,
        currencySymbol: '৳',
        businessName: 'Smart Due',
        ownerName: '',
        businessAddress: '',
        businessLogoUrl: null,
        businessPhone: '',
        bkashNumber: '',
        smsReminderTemplate:
            'প্রিয় {name}, আপনার বকেয়া {amount} টাকা। অনুগ্রহ করে {due_date} এর মধ্যে পরিশোধ করুন। ধন্যবাদ — {business_name}',
        fullPaymentThankYouTemplate:
            'প্রিয় {name}, আপনার সম্পূর্ণ বকেয়া পরিশোধ হয়ে গেছে। আমাদের সাথে থাকার জন্য অনেক ধন্যবাদ! — {business_name}',
        partialPaymentThankYouTemplate:
            'প্রিয় {name}, আপনার {paid_amount} টাকা পেমেন্ট পেয়েছি, ধন্যবাদ! আপনার বাকি বকেয়া {remaining_due} টাকা। — {business_name}',
        fontScale: 1.0,
        appLockEnabled: false,
        appLockPinHash: null,
        languageCode: 'en',
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
      businessPhone: map['businessPhone'] as String? ?? defaults.businessPhone,
      bkashNumber: map['bkashNumber'] as String? ?? defaults.bkashNumber,
      smsReminderTemplate: map['smsReminderTemplate'] as String? ??
          defaults.smsReminderTemplate,
      fullPaymentThankYouTemplate: map['fullPaymentThankYouTemplate'] as String? ??
          defaults.fullPaymentThankYouTemplate,
      partialPaymentThankYouTemplate:
          map['partialPaymentThankYouTemplate'] as String? ??
              defaults.partialPaymentThankYouTemplate,
      fontScale: (map['fontScale'] as num?)?.toDouble() ?? defaults.fontScale,
      appLockEnabled:
          map['appLockEnabled'] as bool? ?? defaults.appLockEnabled,
      appLockPinHash: map['appLockPinHash'] as String?,
      languageCode: map['languageCode'] as String? ?? defaults.languageCode,
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
      'businessPhone': businessPhone,
      'bkashNumber': bkashNumber,
      'smsReminderTemplate': smsReminderTemplate,
      'fullPaymentThankYouTemplate': fullPaymentThankYouTemplate,
      'partialPaymentThankYouTemplate': partialPaymentThankYouTemplate,
      'fontScale': fontScale,
      'appLockEnabled': appLockEnabled,
      'appLockPinHash': appLockPinHash,
      'languageCode': languageCode,
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
    String? businessPhone,
    String? bkashNumber,
    String? smsReminderTemplate,
    String? fullPaymentThankYouTemplate,
    String? partialPaymentThankYouTemplate,
    double? fontScale,
    bool? appLockEnabled,
    String? appLockPinHash,
    bool clearPin = false,
    String? languageCode,
  }) {
    return AppSettings(
      accentColorValue: accentColorValue ?? this.accentColorValue,
      isDarkMode: isDarkMode ?? this.isDarkMode,
      currencySymbol: currencySymbol ?? this.currencySymbol,
      businessName: businessName ?? this.businessName,
      ownerName: ownerName ?? this.ownerName,
      businessAddress: businessAddress ?? this.businessAddress,
      businessLogoUrl: businessLogoUrl ?? this.businessLogoUrl,
      businessPhone: businessPhone ?? this.businessPhone,
      bkashNumber: bkashNumber ?? this.bkashNumber,
      smsReminderTemplate: smsReminderTemplate ?? this.smsReminderTemplate,
      fullPaymentThankYouTemplate:
          fullPaymentThankYouTemplate ?? this.fullPaymentThankYouTemplate,
      partialPaymentThankYouTemplate: partialPaymentThankYouTemplate ??
          this.partialPaymentThankYouTemplate,
      fontScale: fontScale ?? this.fontScale,
      appLockEnabled: appLockEnabled ?? this.appLockEnabled,
      appLockPinHash: clearPin ? null : (appLockPinHash ?? this.appLockPinHash),
      languageCode: languageCode ?? this.languageCode,
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
    '{business_phone}',
    '{bkash_number}',
  ];

  // ✅ Full-payment thank-you টেমপ্লেটে {amount}/{due_date} অর্থহীন (বকেয়া ৳0),
  // তাই এখানে আলাদা, ছোট placeholder লিস্ট
  static const List<String> thankYouPlaceholders = [
    '{name}',
    '{business_name}',
    '{phone}',
    '{business_phone}',
  ];

  // ✅ Partial-payment টেমপ্লেটে কত টাকা দিলেন ও কত বাকি রইল — দুটো আলাদা
  // placeholder লাগে ({amount} এখানে ব্যবহার হয় না, কারণ "বকেয়া" vs "এইমাত্র যা দিলেন"
  // গুলিয়ে ফেলার সুযোগ থাকে)
  static const List<String> partialPaymentPlaceholders = [
    '{name}',
    '{paid_amount}',
    '{remaining_due}',
    '{business_name}',
    '{phone}',
    '{business_phone}',
    '{bkash_number}',
  ];
}