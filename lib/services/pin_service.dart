import 'dart:convert';
import 'package:crypto/crypto.dart';

class PinService {
  // ✅ PIN হ্যাশ করে সেভ করার জন্য — কখনো plain text PIN সেভ হবে না
  static String hashPin(String pin) {
    final bytes = utf8.encode('smart_due_salt_$pin');
    return sha256.convert(bytes).toString();
  }

  static bool verifyPin(String pin, String storedHash) {
    return hashPin(pin) == storedHash;
  }
}