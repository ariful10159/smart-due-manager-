import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_settings.dart';
import 'auth_service.dart';

class SettingsService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const _prefsKey = 'app_settings_cache';

  // ✅ দ্রুত লোড হওয়ার জন্য প্রথমে local cache থেকে পড়া হয়
  static Future<AppSettings> loadLocalCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw == null) return AppSettings.defaults();
      return AppSettings.fromMap(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return AppSettings.defaults();
    }
  }

  static Future<void> _saveLocalCache(AppSettings settings) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, jsonEncode(settings.toMap()));
    } catch (_) {
      // non-critical
    }
  }

  // ✅ Firestore থেকে ফ্রেশ সেটিংস আনা হয় (ব্যাকগ্রাউন্ডে)
  static Future<AppSettings> loadFromFirestore() async {
    final uid = AuthService.currentUser?.uid;
    if (uid == null) return AppSettings.defaults();

    try {
      final doc = await _firestore
          .collection('users')
          .doc(uid)
          .get()
          .timeout(const Duration(seconds: 15));
      final data = doc.data();
      final settingsMap = data?['settings'] as Map<String, dynamic>?;

      final settings = settingsMap != null
          ? AppSettings.fromMap(settingsMap)
          : AppSettings.defaults();

      await _saveLocalCache(settings);
      return settings;
    } catch (_) {
      return loadLocalCache();
    }
  }

  static Future<void> saveSettings(AppSettings settings) async {
    await _saveLocalCache(settings);

    final uid = AuthService.currentUser?.uid;
    if (uid == null) return;

    await _firestore.collection('users').doc(uid).set(
      {'settings': settings.toMap()},
      SetOptions(merge: true),
    );
  }
}