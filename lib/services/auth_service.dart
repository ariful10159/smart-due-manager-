import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // ✅ User profile Firestore এ সেভ করা হচ্ছে
      await _firestore.collection('users').doc(credential.user!.uid).set({
        'name': name,
        'phone': phone,
        'createdAt': Timestamp.now(),
      });

      return null; // null মানে কোনো error নেই, সফল
    } on FirebaseAuthException catch (e) {
      return _mapAuthError(e);
    } catch (e) {
      return 'রেজিস্ট্রেশন ব্যর্থ হয়েছে: $e';
    }
  }

  // ✅ Login
  static Future<String?> login({
    required String phone,
    required String password,
  }) async {
    try {
      final email = _phoneToEmail(phone);

      await _auth.signInWithEmailAndPassword(email: email, password: password);

      return null;
    } on FirebaseAuthException catch (e) {
      return _mapAuthError(e);
    } catch (e) {
      return 'লগইন ব্যর্থ হয়েছে: $e';
    }
  }

  static Future<void> logout() async {
    await _auth.signOut();
  }

  // ✅ Firebase এর technical error message কে বাংলায় user-friendly বানানো
  static String _mapAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'এই ফোন নাম্বার দিয়ে ইতিমধ্যে অ্যাকাউন্ট আছে';
      case 'weak-password':
        return 'পাসওয়ার্ড খুব দুর্বল, কমপক্ষে ৬ ক্যারেক্টার দিন';
      case 'user-not-found':
        return 'এই ফোন নাম্বারে কোনো অ্যাকাউন্ট নেই, আগে Register করুন';
      case 'wrong-password':
      case 'invalid-credential':
        return 'ভুল পাসওয়ার্ড';
      case 'invalid-email':
        return 'ফোন নাম্বার সঠিক ফরম্যাটে দিন';
      default:
        return e.message ?? 'কিছু একটা ভুল হয়েছে';
    }
  }
}