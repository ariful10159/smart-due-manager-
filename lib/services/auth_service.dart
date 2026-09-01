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

  // ✅ বাংলাদেশি লোকাল ফরম্যাট (01XXXXXXXXX) কে Firebase Phone Auth এর
  // প্রয়োজনীয় E.164 ফরম্যাটে (+8801XXXXXXXXX) রূপান্তর
  static String _toE164(String phone) {
    final clean = phone.replaceAll(RegExp(r'[\s\-]'), '');
    if (clean.startsWith('+')) return clean;
    if (clean.startsWith('880')) return '+$clean';
    if (clean.startsWith('0')) return '+880${clean.substring(1)}';
    return '+880$clean';
  }

  // ✅ ফোন নাম্বারে OTP পাঠানো — এটা মূল _auth ইনস্ট্যান্স দিয়েই করা হয়,
  // কারণ শুধু কোড পাঠানো authStateChanges কে প্রভাবিত করে না
  static Future<void> sendOtp({
    required String phone,
    required void Function(String verificationId) onCodeSent,
    required void Function(PhoneAuthCredential credential) onAutoVerified,
    required void Function(String message) onError,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: _toE164(phone),
      timeout: const Duration(seconds: 60),
      verificationCompleted: onAutoVerified,
      verificationFailed: (e) => onError(_mapAuthError(e)),
      codeSent: (verificationId, _) => onCodeSent(verificationId),
      codeAutoRetrievalTimeout: (_) {},
    );
  }

  // ✅ Registration — phone credential দিয়ে sign-in করে সেই একই account এ
  // email/password credential link করা হয় (secondary Firebase app দিয়ে
  // isolate করার চেষ্টা আগে Play Integrity ভাঙত, তাই মূল _auth ব্যবহার করা
  // হচ্ছে)। ফলে একটাই account এ phone + password দুটো sign-in method থাকে —
  // password দিয়ে normal login, আর ভবিষ্যতে phone verify করে password
  // reset — দুটোই সম্ভব হয়, কোনো backend/Cloud Function ছাড়াই।
  static Future<String?> _registerWithPhoneCredential({
    required String name,
    required String phone,
    required String password,
    required PhoneAuthCredential credential,
  }) async {
    try {
      final phoneUserCredential = await _auth
          .signInWithCredential(credential)
          .timeout(const Duration(seconds: 15));

      final user = phoneUserCredential.user;
      if (user == null) {
        return 'ভেরিফিকেশন ব্যর্থ হয়েছে, আবার চেষ্টা করুন';
      }

      final emailCredential = EmailAuthProvider.credential(
        email: _phoneToEmail(phone),
        password: password,
      );
      await user.linkWithCredential(emailCredential).timeout(const Duration(seconds: 15));

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

      await _firestore.collection('users').doc(user.uid).set({
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

  // ✅ ম্যানুয়ালি OTP কোড দিয়ে ভেরিফাই করে রেজিস্ট্রেশন সম্পন্ন করা
  static Future<String?> verifyOtpAndRegister({
    required String name,
    required String phone,
    required String password,
    required String verificationId,
    required String smsCode,
  }) {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    return _registerWithPhoneCredential(
      name: name,
      phone: phone,
      password: password,
      credential: credential,
    );
  }

  // ✅ Android অটো-রিট্রিভালে (SMS নিজে থেকে ধরা পড়লে) কোড টাইপ না
  // করেই সরাসরি রেজিস্ট্রেশন সম্পন্ন করা
  static Future<String?> registerWithAutoVerifiedCredential({
    required String name,
    required String phone,
    required String password,
    required PhoneAuthCredential credential,
  }) {
    return _registerWithPhoneCredential(
      name: name,
      phone: phone,
      password: password,
      credential: credential,
    );
  }

  // ✅ ভুলে যাওয়া পাসওয়ার্ড রিসেট — phone verify করে (registration এর সময়
  // যেটা account এর সাথে link করা হয়েছিল) সরাসরি সেই account এ sign-in করে
  // নতুন পাসওয়ার্ড সেট করা হয়। phone number টা কোনো registered account এর
  // সাথে link করা না থাকলে Firebase একটা নতুন ফাঁকা phone-only user বানিয়ে
  // ফেলত — সেটা এড়াতে providerData চেক করে account আছে কিনা যাচাই করা হয়।
  static Future<String?> _resetPasswordWithCredential({
    required String newPassword,
    required PhoneAuthCredential credential,
  }) async {
    try {
      final userCredential = await _auth
          .signInWithCredential(credential)
          .timeout(const Duration(seconds: 15));

      final user = userCredential.user;
      if (user == null) {
        return 'ভেরিফিকেশন ব্যর্থ হয়েছে, আবার চেষ্টা করুন';
      }

      final hasPasswordAccount = user.providerData.any(
        (p) => p.providerId == EmailAuthProvider.PROVIDER_ID,
      );
      if (!hasPasswordAccount) {
        await user.delete();
        return 'এই ফোন নাম্বার দিয়ে কোনো অ্যাকাউন্ট নেই, আগে রেজিস্ট্রেশন করুন';
      }

      await user.updatePassword(newPassword).timeout(const Duration(seconds: 15));
      return null;
    } on TimeoutException {
      return 'সার্ভারের সাথে সংযোগ করতে সমস্যা হচ্ছে, ইন্টারনেট চেক করে আবার চেষ্টা করুন';
    } on FirebaseAuthException catch (e) {
      return _mapAuthError(e);
    } catch (_) {
      return 'পাসওয়ার্ড পরিবর্তন ব্যর্থ হয়েছে, আবার চেষ্টা করুন';
    }
  }

  static Future<String?> resetPasswordWithOtp({
    required String newPassword,
    required String verificationId,
    required String smsCode,
  }) {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    return _resetPasswordWithCredential(newPassword: newPassword, credential: credential);
  }

  static Future<String?> resetPasswordWithAutoVerifiedCredential({
    required String newPassword,
    required PhoneAuthCredential credential,
  }) {
    return _resetPasswordWithCredential(newPassword: newPassword, credential: credential);
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
      case 'quota-exceeded':
        return 'অনেকবার চেষ্টা করা হয়েছে, কিছুক্ষণ পর আবার চেষ্টা করুন';
      case 'invalid-verification-code':
        return 'OTP কোডটি সঠিক নয়, আবার চেষ্টা করুন';
      case 'invalid-verification-id':
      case 'session-expired':
        return 'OTP এর মেয়াদ শেষ হয়ে গেছে, আবার পাঠান';
      case 'invalid-phone-number':
        return 'ফোন নাম্বার সঠিক ফরম্যাটে দিন';
      case 'credential-already-in-use':
        return 'এই ফোন নাম্বার দিয়ে ইতিমধ্যে অ্যাকাউন্ট আছে';
      default:
        return 'কিছু একটা ভুল হয়েছে, আবার চেষ্টা করুন (${e.code})';
    }
  }
}