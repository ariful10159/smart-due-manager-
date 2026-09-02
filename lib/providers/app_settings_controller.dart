import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/app_settings.dart';
import '../services/auth_service.dart';
import '../services/settings_service.dart';

class AppSettingsController extends ChangeNotifier {
  AppSettings _settings = AppSettings.defaults();
  bool _isLoading = true;
  String? _lastUid;
  StreamSubscription<User?>? _authSub;

  AppSettings get settings => _settings;
  bool get isLoading => _isLoading;

  Future<void> init() async {
    // ✅ প্রথমে local cache থেকে instant দেখানো — main() এই init() কে await করে
    // runApp() এর আগে, তাই এখানে শুধু দ্রুত local read রাখা হয়েছে।
    _settings = await SettingsService.loadLocalCache();
    _isLoading = false;
    notifyListeners();

    _lastUid = AuthService.currentUser?.uid;

    // ✅ Firestore fetch ইচ্ছাকৃতভাবে await করা হয়নি — এটা একটা network call যার
    // কোনো timeout নেই, main() এর ভেতরে await করলে network slow/hang হলে
    // runApp() কখনো ডাকা হয় না, ফলে ব্যবহারকারী শুধু কালো splash screen দেখে
    // (কোনো crash/exception ছাড়াই)। তাই এটা ব্যাকগ্রাউন্ডে sync হয়, UI দেখানোর পরে।
    unawaited(_syncFromFirestore());

    // ✅ init() মাত্র একবার app startup এ চলে — কিন্তু login/logout তো তার
    // পরে যেকোনো সময় হতে পারে (app restart ছাড়াই)। এই listener ছাড়া logout
    // করে আবার login করলে (একই বা ভিন্ন অ্যাকাউন্টে) settings আর re-fetch হতো
    // না, business name/owner name/address আগের (বা খালি) অবস্থাতেই থেকে যেত।
    _authSub = AuthService.authStateChanges.listen((user) {
      final newUid = user?.uid;
      if (newUid == _lastUid) return;
      _lastUid = newUid;

      if (newUid == null) {
        // ✅ Logout — এই ডিভাইসে অন্য কেউ লগইন করলে যেন আগের ইউজারের
        // business info/theme ভুলবশত না দেখে
        _settings = AppSettings.defaults();
        notifyListeners();
        unawaited(SettingsService.clearLocalCache());
        return;
      }

      // ✅ নতুন লগইন (একই বা ভিন্ন অ্যাকাউন্ট) — Firestore থেকে এই ইউজারের
      // আসল সেভ করা settings টেনে আনা হয়
      unawaited(_syncFromFirestore());
    });
  }

  Future<void> _syncFromFirestore() async {
    final fresh = await SettingsService.loadFromFirestore();
    _settings = fresh;
    notifyListeners();
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
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
    String? businessPhone,
    String? bkashNumber,
  }) =>
      update(_settings.copyWith(
        businessName: name,
        ownerName: ownerName,
        businessAddress: address,
        businessLogoUrl: logoUrl,
        businessPhone: businessPhone,
        bkashNumber: bkashNumber,
      ));
}