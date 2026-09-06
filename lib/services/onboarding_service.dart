import 'package:shared_preferences/shared_preferences.dart';

// ✅ অ্যাপ প্রথমবার ইনস্টল/ওপেন করা হলে (এবং তখনো লগইন করা না থাকলে) একবার
// onboarding walkthrough দেখানো হয় — এই ফ্ল্যাগটা দিয়ে ট্র্যাক করা হয় সেটা
// আগে দেখানো হয়েছে কিনা, যাতে প্রতিবার অ্যাপ খুললে বা লগআউট করলে আবার না দেখায়।
class OnboardingService {
  static const _prefsKey = 'onboarding_seen';

  static Future<bool> hasSeenOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefsKey) ?? false;
  }

  static Future<void> markOnboardingSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKey, true);
  }
}
