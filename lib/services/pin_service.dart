import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';

/// ✅ App Lock PIN হ্যাশিং সার্ভিস
///
/// ফরম্যাট: `pinv2$iterations$base64Salt$base64DerivedHash`
/// প্রতিটা PIN সেট/পরিবর্তনের সময় নতুন র‍্যান্ডম সল্ট তৈরি হয় এবং PBKDF2-HMAC-SHA256
/// দিয়ে হ্যাশ করা হয়, যাতে একই PIN থাকলেও হ্যাশ আলাদা হয় এবং rainbow-table attack
/// কাজ না করে। পুরনো (single-pass SHA-256, fixed salt) ফরম্যাটের হ্যাশও verify করা
/// যায়, যাতে বিদ্যমান ইউজাররা লক-আউট না হন — সফল verify হলে কলার (AppLockScreen)
/// সেটাকে নতুন ফরম্যাটে migrate করে দেয়।
class PinService {
  static const String _formatPrefix = 'pinv2';
  // ✅ বেঞ্চমার্কে ~130ms (desktop JIT) — লো-এন্ড ফোনেও unlock experience দ্রুত রাখতে
  // মাঝারি মানের iteration count বেছে নেওয়া হয়েছে। iterations প্রতিটি হ্যাশেই
  // এমবেড করা থাকে (দেখুন hashPin), তাই ভবিষ্যতে বাড়ালেও পুরনো হ্যাশ verify করতে
  // কোনো সমস্যা হবে না।
  static const int _defaultIterations = 50000;
  static const int _saltBytes = 16;
  static const int _keyBytes = 32;

  /// ✅ নতুন PIN সেট বা পরিবর্তনের সময় ব্যবহার করুন — সবসময় নতুন (pinv2) ফরম্যাট তৈরি করে
  static String hashPin(String pin) {
    final salt = _generateSalt();
    final derived = _pbkdf2(pin, salt, _defaultIterations, _keyBytes);
    return '$_formatPrefix\$$_defaultIterations\$${base64.encode(salt)}\$${base64.encode(derived)}';
  }

  /// ✅ নতুন (pinv2) ও পুরনো — দুই ফরম্যাটের হ্যাশই যাচাই করতে পারে
  static bool verifyPin(String pin, String storedHash) {
    if (isLegacyFormat(storedHash)) {
      return _constantTimeEquals(_legacyHash(pin), storedHash);
    }

    final parts = storedHash.split('\$');
    if (parts.length != 4 || parts[0] != _formatPrefix) return false;

    final iterations = int.tryParse(parts[1]);
    if (iterations == null || iterations <= 0) return false;

    late final Uint8List salt;
    late final Uint8List expected;
    try {
      salt = base64.decode(parts[2]);
      expected = base64.decode(parts[3]);
    } catch (_) {
      return false;
    }

    final actual = _pbkdf2(pin, salt, iterations, expected.length);
    return _constantTimeEquals(base64.encode(actual), base64.encode(expected));
  }

  /// ✅ স্টোর করা হ্যাশটি পুরনো (migration-প্রয়োজন) ফরম্যাটে আছে কিনা
  static bool isLegacyFormat(String storedHash) {
    return !storedHash.startsWith('$_formatPrefix\$');
  }

  // ============================================
  // পুরনো ফরম্যাট — শুধুমাত্র read/verify করার জন্য রাখা হয়েছে, নতুন হ্যাশ তৈরিতে
  // আর ব্যবহার করা হয় না।
  // ============================================
  static String _legacyHash(String pin) {
    final bytes = utf8.encode('smart_due_salt_$pin');
    return sha256.convert(bytes).toString();
  }

  static Uint8List _generateSalt() {
    final random = Random.secure();
    return Uint8List.fromList(
      List<int>.generate(_saltBytes, (_) => random.nextInt(256)),
    );
  }

  // ✅ PBKDF2-HMAC-SHA256 (RFC 8018) — package:crypto এর Hmac/sha256 দিয়ে তৈরি,
  // কোনো নতুন dependency ছাড়াই।
  static Uint8List _pbkdf2(
    String pin,
    List<int> salt,
    int iterations,
    int keyLength,
  ) {
    final hmac = Hmac(sha256, utf8.encode(pin));
    const digestSize = 32; // sha256 output size
    final blockCount = (keyLength / digestSize).ceil();
    final result = BytesBuilder();

    for (var block = 1; block <= blockCount; block++) {
      var u = hmac.convert([...salt, ..._intToBytes(block)]).bytes;
      final t = List<int>.from(u);

      for (var i = 1; i < iterations; i++) {
        u = hmac.convert(u).bytes;
        for (var j = 0; j < t.length; j++) {
          t[j] ^= u[j];
        }
      }
      result.add(t);
    }

    return result.toBytes().sublist(0, keyLength);
  }

  static List<int> _intToBytes(int value) => [
        (value >> 24) & 0xff,
        (value >> 16) & 0xff,
        (value >> 8) & 0xff,
        value & 0xff,
      ];

  // ✅ Timing side-channel এড়াতে constant-time compare
  static bool _constantTimeEquals(String a, String b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return diff == 0;
  }
}
