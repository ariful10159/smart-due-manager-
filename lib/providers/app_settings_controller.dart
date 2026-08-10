import 'package:flutter/material.dart';

import '../models/app_settings.dart';
import '../services/settings_service.dart';

class AppSettingsController extends ChangeNotifier {
  AppSettings _settings = AppSettings.defaults();
  bool _isLoading = true;

  AppSettings get settings => _settings;
  bool get isLoading => _isLoading;

  Future<void> init() async {
    // ✅ প্রথমে local cache থেকে instant দেখানো, তারপর Firestore থেকে sync
    _settings = await SettingsService.loadLocalCache();
    _isLoading = false;
    notifyListeners();

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