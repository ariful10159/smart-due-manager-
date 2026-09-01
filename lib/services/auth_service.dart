import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'app_config_service.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static User? get currentUser => _auth.currentUser;

  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ✅ Phone number কে Firebase Auth এর জন্য fake email এ রূপান্তর
  static String _phoneToEmail(String phone) {
    final cleanPhone = phone.replaceAll(RegExp(r'[\s\-]'), '');
    return '$cleanPhone@smartdue.local';
  }

  // ✅ Registration — নতুন account তৈরি + Firestore এ user profile সেভ
  static Future<String?> register({
    required String name,
    required String phone,
    required String password,
  }) async {
    try {
      final email = _phoneToEmail(phone);

      final credential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password)
          .timeout(const Duration(seconds: 15));

      // ✅ Registration স্ক্রিনের checkbox দিয়ে যেহেতু ইতিমধ্যে বর্তমান Privacy
      // Policy/Terms এ সম্মত হয়েই এসেছে, নতুন অ্যাকাউন্টকে সাথে সাথেই up-to-date
      // হিসেবে মার্ক করা হয় — নাহলে লগইনের পরপরই আবার PolicyAcceptanceGate দেখাত।
      int privacyVersion = 0;
      int termsVersion = 0;
      try {
        final config = await AppConfigService.fetchOnce();
        privacyVersion = (config['privacyVersion'] as num?)?.toInt() ?? 0;
        termsVersion = (config['termsVersion'] as num?)?.toInt() ?? 0;
      } catch (_) {
        // ✅ Config fetch fail করলেও registration আটকাবে না — version 0 থাকবে,
        // পরে PolicyAcceptanceGate ঠিকমতো handle করে নেবে।
      }

      await _firestore.collection('users').doc(credential.user!.uid).set({
        'name': name,
        'phone': phone,
        'createdAt': Timestamp.now(),
        'acceptedPrivacyVersion': privacyVersion,
        'acceptedPrivacyAt': Timestamp.now(),
        'acceptedTermsVersion': termsVersion,
        'acceptedTermsAt': Timestamp.now(),
      }).timeout(const Duration(seconds: 15));

      return null;
    } on TimeoutException {
      return 'সার্ভারের সাথে সংযোগ করতে সমস্যা হচ্ছে, ইন্টারনেট চেক করে আবার চেষ্টা করুন';
    } on FirebaseAuthException catch (e) {
      return _mapAuthError(e);
    } catch (_) {
      return 'রেজিস্ট্রেশন ব্যর্থ হয়েছে, আবার চেষ্টা করুন';
    }
  }

  // ✅ Login
  static Future<String?> login({
    required String phone,
    required String password,
  }) async {
    try {
      final email = _phoneToEmail(phone);

      final credential = await _auth
          .signInWithEmailAndPassword(email: email, password: password)
          .timeout(const Duration(seconds: 15));

      // ✅ Race-condition ফিক্স: signIn() সফল হলেও Android প্লাগিনে
      // currentUser getter কখনো কখনো native সাইড থেকে সিঙ্ক হতে দেরি করে।
      if (_auth.currentUser == null) {
        await _auth.authStateChanges().firstWhere(
          (user) => user != null,
        ).timeout(
          const Duration(seconds: 5),
          onTimeout: () => credential.user,
        );
      }

      if (_auth.currentUser == null && credential.user == null) {
        return 'লগইন সম্পন্ন হয়নি, আবার চেষ্টা করুন';
      }

      return null;
    } on TimeoutException {
      return 'সার্ভারের সাথে সংযোগ করতে সমস্যা হচ্ছে, ইন্টারনেট চেক করে আবার চেষ্টা করুন';
    } on FirebaseAuthException catch (e) {
      return _mapAuthError(e);
    } catch (_) {
      return 'লগইন ব্যর্থ হয়েছে, আবার চেষ্টা করুন';
    }
  }

  // ✅ Logout — timeout সহ, যাতে কখনো চিরকাল আটকে না থাকে
  static Future<void> logout() async {
    try {
      await _auth.signOut().timeout(const Duration(seconds: 10));
    } on TimeoutException {
      // ✅ timeout হলেও silently এগিয়ে যাওয়া হচ্ছে,
      // UI পরের ধাপেই সরাসরি LoginScreen এ নিয়ে যাবে
    } catch (_) {
      // অন্য যেকোনো এরর হলেও silently এগিয়ে যাওয়া হচ্ছে,
      // কারণ লোকাল সেশন সাধারণত signOut() কল হওয়ার সাথে সাথেই ক্লিয়ার হয়ে যায়
    }
  }

  static String _mapAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'এই ফোন নাম্বার দিয়ে ইতিমধ্যে অ্যাকাউন্ট আছে';
      case 'weak-password':
        return 'পাসওয়ার্ড খুব দুর্বল, কমপক্ষে ৬ ক্যারেক্টার দিন';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'ফোন নাম্বার অথবা পাসওয়ার্ড সঠিক নয়';
      case 'invalid-email':
        return 'ফোন নাম্বার সঠিক ফরম্যাটে দিন';
      case 'network-request-failed':
        return 'ইন্টারনেট সংযোগ পাওয়া যাচ্ছে না, চেক করে আবার চেষ্টা করুন';
      case 'too-many-requests':
        return 'অনেকবার চেষ্টা করা হয়েছে, কিছুক্ষণ পর আবার চেষ্টা করুন';
      default:
        return 'কিছু একটা ভুল হয়েছে, আবার চেষ্টা করুন';
    }
  }
}