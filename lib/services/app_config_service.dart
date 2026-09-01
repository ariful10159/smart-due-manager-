import 'package:cloud_firestore/cloud_firestore.dart';

// ✅ Admin panel এর App Config পেজ (appConfig/main) থেকে maintenance mode,
// force update, privacy/terms override, contact/about/FAQ তথ্য পড়ার জন্য।
// Firestore rules এ এই ডকুমেন্ট public read (auth লাগে না) — login screen এও
// maintenance/force-update চেক করা যায় তাই।
class AppConfigService {
  static final _doc = FirebaseFirestore.instance.collection('appConfig').doc('main');

  static Stream<Map<String, dynamic>> watch() {
    return _doc.snapshots().map((snap) => snap.data() ?? {});
  }

  static Future<Map<String, dynamic>> fetchOnce() async {
    final snap = await _doc.get();
    return snap.data() ?? {};
  }

  // "1.2.3" স্টাইল ভার্সন স্ট্রিং তুলনা করে — [current] যদি [minRequired] এর
  // চেয়ে কম হয় true দেয়। অংশ কম থাকলে (যেমন "1.2" বনাম "1.2.3") বাকিটা 0 ধরা হয়।
  static bool isBelowMinVersion(String current, String minRequired) {
    final currentParts = current.trim().split('.').map((p) => int.tryParse(p) ?? 0).toList();
    final minParts = minRequired.trim().split('.').map((p) => int.tryParse(p) ?? 0).toList();
    final length = currentParts.length > minParts.length ? currentParts.length : minParts.length;

    for (var i = 0; i < length; i++) {
      final c = i < currentParts.length ? currentParts[i] : 0;
      final m = i < minParts.length ? minParts[i] : 0;
      if (c != m) return c < m;
    }
    return false;
  }
}
