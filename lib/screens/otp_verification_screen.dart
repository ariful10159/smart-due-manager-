import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart' show PhoneAuthCredential;
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';
import '../widgets/auth_error_dialog.dart';

// ✅ Registration ও "forgot password" — দুই জায়গাতেই phone OTP verify করার
// UI/flow হুবহু একই (send, resend timer, auto-verify, manual code entry)।
// শুধু verify সফল হলে ঠিক কী করতে হবে সেটা আলাদা (account তৈরি vs password
// reset), তাই সেটা callback দিয়ে ইনজেক্ট করা হয়েছে।
class OtpVerificationScreen extends StatefulWidget {
  const OtpVerificationScreen({
    super.key,
    required this.phone,
    required this.onVerify,
    required this.onAutoVerify,
    required this.verifyButtonLabel,
  });

  final String phone;
  final Future<String?> Function(String verificationId, String smsCode) onVerify;
  final Future<String?> Function(PhoneAuthCredential credential) onAutoVerify;
  final String verifyButtonLabel;

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();

  String? _verificationId;
  Timer? _resendTimer;
  int _resendSeconds = 60;

  bool _sendingCode = true;
  bool _verifying = false;
  bool _autoVerifying = false;
  String? _sendErrorMessage;

  @override
  void initState() {
    super.initState();
    _sendCode();
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    _codeController.dispose();
    super.dispose();
  }

  void _startResendTimer() {
    _resendSeconds = 60;
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_resendSeconds <= 1) {
        timer.cancel();
        setState(() => _resendSeconds = 0);
      } else {
        setState(() => _resendSeconds -= 1);
      }
    });
  }

  Future<void> _sendCode() async {
    setState(() {
      _sendingCode = true;
      _autoVerifying = false;
      _sendErrorMessage = null;
      _verificationId = null;
    });

    await AuthService.sendOtp(
      phone: widget.phone,
      onCodeSent: (verificationId) {
        if (!mounted) return;
        setState(() {
          _verificationId = verificationId;
          _sendingCode = false;
        });
        _startResendTimer();
      },
      onAutoVerified: (credential) async {
        if (!mounted) return;
        setState(() {
          _sendingCode = false;
          _autoVerifying = true;
        });
        final error = await widget.onAutoVerify(credential);
        if (!mounted) return;
        setState(() => _autoVerifying = false);
        if (error != null) {
          _showError(error);
        } else {
          // ✅ AuthWrapper (root route) auth state বদলে HomeScreen দেখানোর
          // জন্য প্রস্তুত, কিন্তু সেটা এখনো navigation stack এর নিচে চাপা
          // পড়ে আছে — তাই root এ ফিরিয়ে নিয়ে সেটা visible করা হচ্ছে
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      },
      onError: (message) {
        if (!mounted) return;
        setState(() {
          _sendingCode = false;
          _sendErrorMessage = message;
        });
        _showError(message);
      },
    );
  }

  Future<void> _resendCode() async {
    if (_resendSeconds > 0 || _sendingCode) return;
    await _sendCode();
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.otpResentSuccess)),
    );
  }

  Future<void> _verify() async {
    if (!_formKey.currentState!.validate()) return;
    if (_verificationId == null) return;

    setState(() => _verifying = true);

    final error = await widget.onVerify(_verificationId!, _codeController.text.trim());

    if (!mounted) return;
    setState(() => _verifying = false);

    if (error != null) {
      _showError(error);
    } else {
      // ✅ AuthWrapper (root route) auth state বদলে HomeScreen দেখানোর জন্য
      // প্রস্তুত, কিন্তু সেটা এখনো navigation stack এর নিচে চাপা পড়ে আছে —
      // তাই root এ ফিরিয়ে নিয়ে সেটা visible করা হচ্ছে
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  // ✅ আগে bottom SnackBar দিয়ে দেখানো হতো — এখন মাঝ-স্ক্রিন popup (icon সহ)
  // দিয়ে দেখানো হয়, আর message এখন AuthService থেকে আসা internal error code
  // (যেমন 'already-registered') — showAuthErrorDialog সেটাকে বর্তমান app
  // language অনুযায়ী localized টেক্সটে রূপান্তর করে দেখায়।
  void _showError(String code) {
    showAuthErrorDialog(context, code);
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final l10n = AppLocalizations.of(context)!;
    final isBusy = _sendingCode || _verifying || _autoVerifying;

    return Scaffold(
      backgroundColor: colors.scaffoldBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: colors.textPrimary),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: colors.surface,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: colors.accent.withValues(alpha: 0.12),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          )
                        ],
                        border: Border.all(color: colors.accent.withValues(alpha: 0.2), width: 1.5),
                      ),
                      child: Icon(Icons.sms_outlined, size: 44, color: colors.accent),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    l10n.otpVerificationTitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: colors.textPrimary,
                      letterSpacing: -0.5,
                      fontSize: 24,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.otpSentTo(widget.phone),
                    textAlign: TextAlign.center,
                    style: TextStyle(color: colors.textSecondary, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 36),

                  if (_sendingCode) ...[
                    const Center(child: CircularProgressIndicator()),
                    const SizedBox(height: 16),
                    Text(
                      l10n.sendingOtp,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: colors.textSecondary, fontWeight: FontWeight.w500),
                    ),
                  ] else if (_autoVerifying) ...[
                    const Center(child: CircularProgressIndicator()),
                    const SizedBox(height: 16),
                    Text(
                      l10n.autoVerifyingOtp,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: colors.textSecondary, fontWeight: FontWeight.w500),
                    ),
                  ] else if (_sendErrorMessage != null) ...[
                    Icon(Icons.error_outline_rounded, size: 48, color: colors.due),
                    const SizedBox(height: 16),
                    Text(
                      resolveAuthErrorMessage(context, _sendErrorMessage!),
                      textAlign: TextAlign.center,
                      style: TextStyle(color: colors.textSecondary, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      height: 56,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        gradient: LinearGradient(
                          colors: [colors.accent, colors.accentAlt],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                        ),
                        onPressed: _sendCode,
                        child: Text(
                          l10n.resendCode,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Text(
                          l10n.changePhoneNumber,
                          style: TextStyle(
                            color: colors.textSecondary,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            decoration: TextDecoration.underline,
                            decorationThickness: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ] else ...[
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [colors.surface, colors.surfaceAlt],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 32,
                            offset: const Offset(0, 16),
                          ),
                        ],
                        border: Border.all(color: colors.borderColor, width: 1),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: TextFormField(
                          controller: _codeController,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          maxLength: 6,
                          autofocus: true,
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            color: colors.textPrimary,
                            fontSize: 22,
                            letterSpacing: 8,
                          ),
                          decoration: InputDecoration(
                            counterText: '',
                            labelText: l10n.otpCodeLabel,
                            hintText: l10n.otpCodeHint,
                            hintStyle: TextStyle(color: colors.hintColor, fontSize: 14),
                            labelStyle: TextStyle(color: colors.textSecondary, fontWeight: FontWeight.w500),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(color: colors.borderColor, width: 1.5),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(color: colors.accent, width: 2),
                            ),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return l10n.enterOtpCode;
                            if (v.trim().length != 6) return l10n.enterValid6DigitOtp;
                            return null;
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    Container(
                      height: 56,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        gradient: LinearGradient(
                          colors: [colors.accent, colors.accentAlt],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: colors.accent.withValues(alpha: 0.35),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                        ),
                        onPressed: isBusy ? null : _verify,
                        child: _verifying
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : Text(
                                widget.verifyButtonLabel,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 0.4,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          l10n.didntReceiveCode,
                          style: TextStyle(color: colors.textSecondary, fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                        GestureDetector(
                          onTap: _resendSeconds > 0 || isBusy ? null : _resendCode,
                          child: Text(
                            _resendSeconds > 0 ? l10n.resendCodeIn(_resendSeconds) : l10n.resendCode,
                            style: TextStyle(
                              color: _resendSeconds > 0 ? colors.hintColor : colors.accent,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              decoration: _resendSeconds > 0 ? null : TextDecoration.underline,
                              decorationThickness: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: GestureDetector(
                        onTap: isBusy ? null : () => Navigator.of(context).pop(),
                        child: Text(
                          l10n.changePhoneNumber,
                          style: TextStyle(
                            color: colors.textSecondary,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            decoration: TextDecoration.underline,
                            decorationThickness: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
