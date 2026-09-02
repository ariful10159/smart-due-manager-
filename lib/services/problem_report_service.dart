import 'dart:io' show Platform;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:package_info_plus/package_info_plus.dart';

// ✅ ইউজার "Report a Problem" থেকে যে সমস্যা রিপোর্ট করে সেটা এখানে লেখা হয়।
// রিপোর্টার এর নাম/ফোন সরাসরি ডকুমেন্টে denormalize করে রাখা হয়েছে, যাতে
// master admin panel এ কোন ইউজার রিপোর্ট করেছে সেটা আলাদা করে users
// collection lookup না করেই সাথে সাথে দেখা যায়।
class ProblemReportService {
  static Future<void> submit({
    required String category,
    required String description,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    String userName = '';
    String userPhone = user.email?.split('@').first ?? '';
    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      userName = (userDoc.data()?['name'] as String? ?? '').trim();
      final storedPhone = (userDoc.data()?['phone'] as String? ?? '').trim();
      if (storedPhone.isNotEmpty) userPhone = storedPhone;
    } catch (_) {
      // ✅ প্রোফাইল না পাওয়া গেলেও রিপোর্ট সাবমিট আটকাবে না
    }

    String appVersion = 'unknown';
    try {
      final info = await PackageInfo.fromPlatform();
      appVersion = '${info.version}+${info.buildNumber}';
    } catch (_) {
      // ✅ ব্যর্থ হলেও রিপোর্ট সাবমিট আটকাবে না
    }

    await FirebaseFirestore.instance.collection('problemReports').add({
      'userId': user.uid,
      'userName': userName,
      'userPhone': userPhone,
      'category': category,
      'description': description,
      'appVersion': appVersion,
      'platform': _platformName(),
      'status': 'open',
      'createdAt': FieldValue.serverTimestamp(),
    });
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
