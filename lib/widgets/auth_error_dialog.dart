import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../theme/app_colors.dart';

// ✅ AuthService এর মেথডগুলো এখন human-readable মেসেজের বদলে internal error
// code (যেমন 'already-registered', 'invalid-otp') রিটার্ন করে — এই ফাইলটা
// সেই code-কে বর্তমান app language অনুযায়ী (Settings এ বাংলা/English যা বাছাই
// করা আছে) localized মেসেজে রূপান্তর করে এবং একটা মাঝ-স্ক্রিন popup (SnackBar
// এর বদলে) দিয়ে দেখায় — Registration, Login, Forgot Password, Change
// Password — পুরো auth flow জুড়ে একই রকম দেখতে।
String resolveAuthErrorMessage(BuildContext context, String code) {
  final l10n = AppLocalizations.of(context)!;
  if (code.startsWith('unknown:')) {
    return l10n.authErrorUnknown(code.substring('unknown:'.length));
  }
  switch (code) {
    case 'already-registered':
      return l10n.authErrorAlreadyRegistered;
    case 'weak-password':
      return l10n.authErrorWeakPassword;
    case 'invalid-credentials':
      return l10n.authErrorInvalidCredentials;
    case 'invalid-phone-format':
      return l10n.authErrorInvalidPhoneFormat;
    case 'network-error':
      return l10n.authErrorNetwork;
    case 'too-many-requests':
      return l10n.authErrorTooManyRequests;
    case 'invalid-otp':
      return l10n.authErrorInvalidOtp;
    case 'otp-expired':
      return l10n.authErrorOtpExpired;
    case 'verification-failed':
      return l10n.authErrorVerificationFailed;
    case 'timeout':
      return l10n.authErrorTimeout;
    case 'registration-failed':
      return l10n.authErrorRegistrationFailed;
    case 'no-account-for-phone':
      return l10n.authErrorNoAccountForPhone;
    case 'password-reset-failed':
      return l10n.authErrorPasswordResetFailed;
    case 'login-incomplete':
      return l10n.authErrorLoginIncomplete;
    case 'login-failed':
      return l10n.authErrorLoginFailed;
    case 'session-not-found':
      return l10n.authErrorSessionNotFound;
    case 'wrong-current-password':
      return l10n.authErrorWrongCurrentPassword;
    case 'change-password-failed':
      return l10n.authErrorChangePasswordFailed;
    default:
      return l10n.authErrorUnknown(code);
  }
}

// ✅ আগে এই এররগুলো bottom SnackBar দিয়ে দেখানো হতো — এখন মাঝ-স্ক্রিন popup
// (icon সহ) দিয়ে দেখানো হয়, যাতে ভুল হওয়া কেন হলো সেটা ইউজারের চোখ এড়িয়ে না যায়।
Future<void> showAuthErrorDialog(BuildContext context, String code) {
  final colors = AppColors.of(context);
  final l10n = AppLocalizations.of(context)!;
  final message = resolveAuthErrorMessage(context, code);

  return showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: colors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: colors.due.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.error_outline_rounded, color: colors.due, size: 30),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 14.5,
            ),
          ),
        ],
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: Text(
            l10n.ok,
            style: TextStyle(color: colors.accent, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ),
  );
}
