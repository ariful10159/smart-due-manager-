import 'dart:io' show Platform;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ✅ Master admin panel-এর Dashboard-এ "App versions" breakdown দেখানোর জন্য —
// Force Update চালু করার আগে admin যেন জানতে পারে সেটা কতজনকে block করবে। প্রতি
// app-open এ না লিখে দিনে একবার লেখে (SharedPreferences এ শেষ লেখার তারিখ রেখে),
// অকারণে বারবার Firestore write এড়াতে। ব্যর্থ হলেও silently skip করে — এটা কোনো
// critical ফিচার না, app-এর normal ব্যবহারে কোনো প্রভাব ফেলবে না।
class AppVersionReportService {
  static const _lastReportedKey = 'app_version_last_reported_date';

  static Future<void> reportIfNeeded() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final today = DateTime.now().toIso8601String().substring(0, 10); // YYYY-MM-DD
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getString(_lastReportedKey) == today) return;

      final info = await PackageInfo.fromPlatform();
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'appVersion': '${info.version}+${info.buildNumber}',
        'platform': _platformName(),
        'appVersionReportedAt': FieldValue.serverTimestamp(),
      });

      await prefs.setString(_lastReportedKey, today);
    } catch (_) {
      // ব্যর্থ হলে SharedPreferences-এ তারিখ সেভ হয় না, তাই পরের app-open এ আবার চেষ্টা হবে।
    }
  }

  static String _platformName() {
    if (kIsWeb) return 'web';
    try {
      return Platform.operatingSystem;
    } catch (_) {
      return 'unknown';
    }
  }
}
