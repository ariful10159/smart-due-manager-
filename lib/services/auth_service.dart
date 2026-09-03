import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../screens/report_screen.dart';
import 'app_config_service.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static User? get currentUser => _auth.currentUser;

  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ✅ ফোন নম্বর দিয়ে লগইন করলে Firebase auth এ ইমেইল হিসেবে
  // "<phone>@smartdue.local" সেভ থাকে — এখান থেকে শুধু ফোন নম্বর অংশটুকু বের
  // করে দেয়, যাতে বিভিন্ন স্ক্রিনে (Change Password, Delete Account, Drawer)
  // ইউজারকে দেখানো যায় কোন অ্যাকাউন্টে আছেন — ভুল অ্যাকাউন্ট মনে করে সংবেদনশীল
  // কাজ (পাসওয়ার্ড বদল/অ্যাকাউন্ট ডিলিট) করে ফেলা এড়াতে
  static String? get currentPhone {
    final email = _auth.currentUser?.email;
    if (email == null || email.isEmpty) return null;
    return email.split('@').first;
  }

  // ✅ ফোন নাম্বার যেভাবেই টাইপ করা হোক (01XXXXXXXXX, +8801XXXXXXXXX,
  // 8801XXXXXXXXX, মাঝে space/dash সহ) — সবসময় একই canonical local ফরম্যাটে
  // (01XXXXXXXXX) normalize করা হয়। আগে এই normalization ছিল না, ফলে কেউ
  // +8801XXXXXXXXX দিয়ে register করে পরে 01XXXXXXXXX দিয়ে login করতে গেলে (বা
  // উল্টো) সম্পূর্ণ ভিন্ন fake email/account রিসলভ হতো এবং login ব্যর্থ হতো।
  static String _normalizePhone(String phone) {
    var clean = phone.replaceAll(RegExp(r'[\s\-]'), '');
    if (clean.startsWith('+880')) {
      clean = '0${clean.substring(4)}';
    } else if (clean.startsWith('880')) {
      clean = '0${clean.substring(3)}';
    }
    return clean;
  }

  // ✅ Phone number কে Firebase Auth এর জন্য fake email এ রূপান্তর
  static String _phoneToEmail(String phone) {
    return '${_normalizePhone(phone)}@smartdue.local';
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
        return 'verification-failed';
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
        'phone': _normalizePhone(phone),
        'createdAt': Timestamp.now(),
        'acceptedPrivacyVersion': privacyVersion,
        'acceptedPrivacyAt': Timestamp.now(),
        'acceptedTermsVersion': termsVersion,
        'acceptedTermsAt': Timestamp.now(),
      }).timeout(const Duration(seconds: 15));

      return null;
    } on TimeoutException {
      return 'timeout';
    } on FirebaseAuthException catch (e) {
      return _mapAuthError(e);
    } catch (_) {
      return 'registration-failed';
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
        return 'verification-failed';
      }

      final hasPasswordAccount = user.providerData.any(
        (p) => p.providerId == EmailAuthProvider.PROVIDER_ID,
      );
      if (!hasPasswordAccount) {
        await user.delete();
        return 'no-account-for-phone';
      }

      await user.updatePassword(newPassword).timeout(const Duration(seconds: 15));
      return null;
    } on TimeoutException {
      return 'timeout';
    } on FirebaseAuthException catch (e) {
      return _mapAuthError(e);
    } catch (_) {
      return 'password-reset-failed';
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
        return 'login-incomplete';
      }

      return null;
    } on TimeoutException {
      return 'timeout';
    } on FirebaseAuthException catch (e) {
      return _mapAuthError(e);
    } catch (_) {
      return 'login-failed';
    }
  }

  // ✅ Logout — timeout সহ, যাতে কখনো চিরকাল আটকে না থাকে
  static Future<void> logout() async {
    // ✅ Report স্ক্রিনের static cache পরের ইউজারের কাছে আগের ইউজারের ডেটা
    // দেখিয়ে না ফেলে, তাই একই ডিভাইসে account বদলালে এটা ক্লিয়ার হওয়া জরুরি
    ReportScreen.clearCache();
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

  // ✅ Logged-in অবস্থায় পাসওয়ার্ড পরিবর্তন — Firebase sensitive অপারেশনের
  // (updatePassword) জন্য "recent login" দাবি করে, তাই আগে বর্তমান পাসওয়ার্ড
  // দিয়ে reauthenticate করা হয়। EmailAuthProvider এর email হিসেবে
  // user.email ব্যবহার করা হচ্ছে (যেটা login-এর সময়ও _phoneToEmail দিয়ে
  // বানানো একই ফোন-ভিত্তিক ইমেইল) — আলাদা করে ফোন নাম্বার লাগে না।
  static Future<String?> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null || user.email == null) {
        return 'session-not-found';
      }

      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user
          .reauthenticateWithCredential(credential)
          .timeout(const Duration(seconds: 15));
      await user.updatePassword(newPassword).timeout(const Duration(seconds: 15));
      return null;
    } on TimeoutException {
      return 'timeout';
    } on FirebaseAuthException catch (e) {
      // ✅ _mapAuthError এর wrong-password কোডে "ফোন নাম্বার" প্রসঙ্গ থাকে,
      // যা এই ফর্মে (ফোন নাম্বার ইনপুট নেই) বিভ্রান্তিকর — তাই আলাদা কোড
      if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        return 'wrong-current-password';
      }
      return _mapAuthError(e);
    } catch (_) {
      return 'change-password-failed';
    }
  }

  // ✅ এই মেথডটা এখন human-readable বাংলা মেসেজের বদলে একটা internal error
  // code (String) রিটার্ন করে — UI layer (প্রতিটা স্ক্রিন) এই code-কে
  // AppLocalizations দিয়ে বর্তমান app language (বাংলা/English, Settings এ
  // বেছে নেওয়া) অনুযায়ী মেসেজে রূপান্তর করে (দেখুন widgets/auth_error_dialog.dart)।
  // আগে এখানে সরাসরি বাংলা string hardcode করা ছিল, ফলে ইউজার English
  // সিলেক্ট করলেও auth এরর মেসেজ সবসময় বাংলাতেই দেখাত।
  static String _mapAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
      // ✅ একই নাম্বার দিয়ে দ্বিতীয়বার registration করলে OTP ভেরিফাই হওয়ার
      // পর এই কোডটাই আসে (linkWithCredential — account-এ আগে থেকেই email/
      // password provider linked থাকায়)।
      case 'credential-already-in-use':
      case 'provider-already-linked':
        return 'already-registered';
      case 'weak-password':
        return 'weak-password';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'invalid-credentials';
      case 'invalid-email':
      case 'invalid-phone-number':
        return 'invalid-phone-format';
      case 'network-request-failed':
        return 'network-error';
      case 'too-many-requests':
      case 'quota-exceeded':
        return 'too-many-requests';
      case 'invalid-verification-code':
        return 'invalid-otp';
      case 'invalid-verification-id':
      case 'session-expired':
        return 'otp-expired';
      default:
        return 'unknown:${e.code}';
    }
  }
}