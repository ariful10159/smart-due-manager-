import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../models/customer_repository.dart';
import '../models/notebook_repository.dart';

// ✅ Google Play Data Safety policy অনুযায়ী account creation সাপোর্ট করা অ্যাপে
// in-app account/data deletion থাকা বাধ্যতামূলক — এই সার্ভিসটাই সেই ফ্লো চালায়।
// ধাপগুলো এই ক্রমেই হওয়া জরুরি: প্রথমে সব Firestore/Storage ডেটা মুছে ফেলা হয়
// (যতক্ষণ Auth session বেঁচে থাকে, নিরাপত্তা rules অনুযায়ী), সবশেষে Auth অ্যাকাউন্ট
// ডিলিট হয় — কারণ user.delete() এর পর ID token আর বৈধ থাকে না, তখন আর কোনো
// Firestore/Storage কল করা যাবে না।
class AccountDeletionService {
  // ✅ Firebase sensitive অপারেশনের (delete) জন্য "recent login" লাগে, তাই
  // ChangePasswordScreen এর মতোই আগে বর্তমান পাসওয়ার্ড দিয়ে reauthenticate করা হয়।
  static Future<String?> deleteAccountAndAllData({
    required String currentPassword,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.email == null) {
      return 'সেশন পাওয়া যায়নি, আবার লগইন করুন';
    }

    try {
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user
          .reauthenticateWithCredential(credential)
          .timeout(const Duration(seconds: 15));
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        return 'পাসওয়ার্ড সঠিক নয়';
      }
      return 'যাচাই ব্যর্থ হয়েছে, আবার চেষ্টা করুন (${e.code})';
    } on TimeoutException {
      return 'সার্ভারের সাথে সংযোগ করতে সমস্যা হচ্ছে, ইন্টারনেট চেক করে আবার চেষ্টা করুন';
    }

    try {
      // ✅ সব কাস্টমার (payments/reminders/smsLogs সহ) মুছে ফেলা — parallel
      final customerRepo = CustomerRepository();
      final customers = await customerRepo.fetchCustomersOnce();
      await Future.wait(
        customers.map((c) => customerRepo.deleteCustomerPermanently(c.id)),
      );

      // ✅ সব নোটবুক (pages সহ) মুছে ফেলা — parallel
      final notebookRepo = NotebookRepository();
      final notebooks = await notebookRepo.fetchNotebooksOnce();
      await Future.wait(
        notebooks.map((n) => notebookRepo.deleteNotebook(n.id)),
      );

      // ✅ Business logo (যদি আপলোড করা থাকে) — না থাকলে এই কল ব্যর্থ হবে,
      // সেটা স্বাভাবিক, তাই silently ignore করা হচ্ছে
      try {
        await FirebaseStorage.instance
            .ref('business_logos/${user.uid}.jpg')
            .delete();
      } catch (_) {}

      // ✅ users/{uid} ডকুমেন্ট (business profile, SMS টেমপ্লেট, App Lock PIN hash
      // ইত্যাদি সব settings এখানেই থাকে)
      final userDocRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
      try {
        await userDocRef.delete();
      } catch (_) {
        // ✅ firestore.rules ডিপ্লয় না হয়ে থাকলে self-delete ব্যর্থ হতে পারে —
        // সেক্ষেত্রে অন্তত ভেতরের সব data মুছে খালি রেখে দেওয়া হচ্ছে, যাতে
        // personal info (business name/phone/bkash number ইত্যাদি) থেকে না যায়।
        // merge: true — নাহলে 'disabled' ফিল্ড (যদি admin কখনো toggle করে থাকে)
        // payload থেকে বাদ পড়ে যেত, আর rules সেটাকে touch হিসেবে ধরে reject করত।
        try {
          await userDocRef.set({
            'settings': <String, dynamic>{},
            'accountDeletedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        } catch (_) {}
      }
    } catch (_) {
      return 'ডেটা মোছার সময় সমস্যা হয়েছে, ইন্টারনেট চেক করে আবার চেষ্টা করুন';
    }

    try {
      // ✅ user.delete() নিজে থেকেই sign-out করে দেয় — AppSettingsController এর
      // authStateChanges listener local cache ক্লিয়ার করে দেবে (logout এর মতোই)
      await user.delete().timeout(const Duration(seconds: 15));
      return null;
    } on TimeoutException {
      return 'সার্ভারের সাথে সংযোগ করতে সমস্যা হচ্ছে, ইন্টারনেট চেক করে আবার চেষ্টা করুন';
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        return 'নিরাপত্তার জন্য আবার লগইন করে চেষ্টা করুন';
      }
      return 'অ্যাকাউন্ট ডিলিট করা যায়নি (${e.code})';
    } catch (_) {
      return 'অ্যাকাউন্ট ডিলিট করা যায়নি, আবার চেষ্টা করুন';
    }
  }
}
