import 'dart:async';

import 'package:flutter/material.dart';

import '../models/app_settings.dart';
import '../services/settings_service.dart';

class AppSettingsController extends ChangeNotifier {
  AppSettings _settings = AppSettings.defaults();
  bool _isLoading = true;

  AppSettings get settings => _settings;
  bool get isLoading => _isLoading;

  Future<void> init() async {
    // ✅ প্রথমে local cache থেকে instant দেখানো — main() এই init() কে await করে
    // runApp() এর আগে, তাই এখানে শুধু দ্রুত local read রাখা হয়েছে।
    _settings = await SettingsService.loadLocalCache();
    _isLoading = false;
    notifyListeners();

    // ✅ Firestore fetch ইচ্ছাকৃতভাবে await করা হয়নি — এটা একটা network call যার
    // কোনো timeout নেই, main() এর ভেতরে await করলে network slow/hang হলে
    // runApp() কখনো ডাকা হয় না, ফলে ব্যবহারকারী শুধু কালো splash screen দেখে
    // (কোনো crash/exception ছাড়াই)। তাই এটা ব্যাকগ্রাউন্ডে sync হয়, UI দেখানোর পরে।
    unawaited(_syncFromFirestore());
  }

  Future<void> _syncFromFirestore() async {
    final fresh = await SettingsService.loadFromFirestore();
    _settings = fresh;
    notifyListeners();
  }

  Future<void> update(AppSettings newSettings) async {
    _settings = newSettings;
    notifyListeners();
    await SettingsService.saveSettings(newSettings);
  }

  Future<void> updateAccentColor(int colorValue) =>
      update(_settings.copyWith(accentColorValue: colorValue));

  Future<void> updateDarkMode(bool isDark) =>
      update(_settings.copyWith(isDarkMode: isDark));

  Future<void> updateCurrency(String symbol) =>
      update(_settings.copyWith(currencySymbol: symbol));

  Future<void> updateLanguage(String languageCode) =>
      update(_settings.copyWith(languageCode: languageCode));

  Future<void> updateBusinessInfo({
    required String name,
    required String address,
    String? ownerName,
    String? logoUrl,
  }) =>
      update(_settings.copyWith(
        businessName: name,
        ownerName: ownerName,
        businessAddress: address,
        businessLogoUrl: logoUrl,
      ));
}