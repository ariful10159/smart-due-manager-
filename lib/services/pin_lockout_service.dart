import 'package:shared_preferences/shared_preferences.dart';

/// ✅ App Lock PIN ভুল বারবার দিলে সাময়িক লকআউট — brute-force আটকাতে।
/// প্রতি ৫টা ভুল চেষ্টার পর একটা cooldown শুরু হয়, cooldown বাড়তেই থাকে যতক্ষণ
/// ভুল চলতে থাকে (৩০s → ১ মিনিট → ২ মিনিট ... সর্বোচ্চ ৫ মিনিট)। SharedPreferences এ
/// persist করা হয় বলে অ্যাপ বন্ধ করে আবার খুললেও লকআউট এড়ানো যায় না।
class PinLockoutService {
  static const _attemptsKey = 'app_lock_failed_attempts';
  static const _lockoutUntilKey = 'app_lock_lockout_until_ms';
  static const _maxAttemptsBeforeLockout = 5;
  static const _lockoutTiers = [
    Duration(seconds: 30),
    Duration(minutes: 1),
    Duration(minutes: 2),
    Duration(minutes: 5),
  ];

  static Future<DateTime?> getLockoutUntil() async {
    final prefs = await SharedPreferences.getInstance();
    final ms = prefs.getInt(_lockoutUntilKey);
    if (ms == null) return null;
    final until = DateTime.fromMillisecondsSinceEpoch(ms);
    return until.isAfter(DateTime.now()) ? until : null;
  }

  /// ✅ ভুল PIN দেওয়ার পর কল করতে হবে। লকআউট শুরু হলে তার end time রিটার্ন করে।
  static Future<DateTime?> recordFailedAttempt() async {
    final prefs = await SharedPreferences.getInstance();
    final attempts = (prefs.getInt(_attemptsKey) ?? 0) + 1;
    await prefs.setInt(_attemptsKey, attempts);

    if (attempts % _maxAttemptsBeforeLockout != 0) return null;

    final tier = (attempts ~/ _maxAttemptsBeforeLockout) - 1;
    final duration = _lockoutTiers[tier.clamp(0, _lockoutTiers.length - 1)];
    final until = DateTime.now().add(duration);
    await prefs.setInt(_lockoutUntilKey, until.millisecondsSinceEpoch);
    return until;
  }

  /// ✅ সঠিক PIN দেওয়ার পর কল করতে হবে — কাউন্টার রিসেট।
  static Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_attemptsKey);
    await prefs.remove(_lockoutUntilKey);
  }
}
