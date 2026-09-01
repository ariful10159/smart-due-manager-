import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// ✅ ইউজারের গুরুত্বপূর্ণ action গুলো (customer/payment add-edit-delete) লগ করে,
// যাতে master admin panel-এর Audit log-এ কে কী করেছে দেখা যায়। শুধু create-only —
// ইউজার নিজের লগ এডিট/ডিলিট করতে পারবে না, admin ছাড়া কেউ পড়তেও পারবে না।
class ActivityLogService {
  static Future<void> log(String action, {Map<String, dynamic> details = const {}}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance.collection('userActivityLog').add({
        'userId': user.uid,
        'action': action,
        'details': details,
        'at': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      // ✅ Logging ব্যর্থ হলেও মূল কাজ (payment/customer save ইত্যাদি) যেন কখনো আটকে না যায়
    }
  }
}
