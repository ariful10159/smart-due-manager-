import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';
import 'otp_verification_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _continue() {
    if (!_formKey.currentState!.validate()) return;

    final l10n = AppLocalizations.of(context)!;
    final phone = _phoneController.text.trim();
    final newPassword = _passwordController.text.trim();

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => OtpVerificationScreen(
          phone: phone,
          verifyButtonLabel: l10n.verifyAndResetPassword,
          onVerify: (verificationId, smsCode) => AuthService.resetPasswordWithOtp(
            newPassword: newPassword,
            verificationId: verificationId,
            smsCode: smsCode,
          ),
          onAutoVerify: (credential) => AuthService.resetPasswordWithAutoVerifiedCredential(
            newPassword: newPassword,
            credential: credential,
          ),
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration({
    required AppColors colors,
    required String label,
    required IconData icon,
    String? hint,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      hintStyle: TextStyle(color: colors.hintColor, fontSize: 14),
      labelStyle: TextStyle(color: colors.textSecondary, fontWeight: FontWeight.w500),
      prefixIcon: Icon(icon, color: colors.accent.withValues(alpha: 0.8)),
      suffixIcon: suffixIcon,
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colors.borderColor, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colors.accent, width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final l10n = AppLocalizations.of(context)!;

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
                      child: Icon(Icons.lock_reset_rounded, size: 44, color: colors.accent),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    l10n.forgotPasswordTitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: colors.textPrimary,
                      letterSpacing: -0.5,
                      fontSize: 28,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.resetPasswordDesc,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: colors.textSecondary, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 36),

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
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            textInputAction: TextInputAction.next,
                            style: TextStyle(fontWeight: FontWeight.w600, color: colors.textPrimary),
                            decoration: _fieldDecoration(
                              colors: colors,
                              label: l10n.phoneNumber,
                              hint: l10n.phoneHintExample,
                              icon: Icons.phone_outlined,
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return l10n.enterPhoneNumber;
                              if (v.trim().length < 11) return l10n.enterValid11DigitPhone;
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),

                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            textInputAction: TextInputAction.next,
                            style: TextStyle(fontWeight: FontWeight.w600, color: colors.textPrimary),
                            decoration: _fieldDecoration(
                              colors: colors,
                              label: l10n.newPasswordLabel,
                              icon: Icons.lock_outline_rounded,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                  color: colors.textSecondary,
                                ),
                                onPressed: () {
                                  setState(() => _obscurePassword = !_obscurePassword);
                                },
                              ),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) return l10n.enterPassword;
                              if (v.length < 6) return l10n.minSixCharacters;
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),

                          TextFormField(
                            controller: _confirmPasswordController,
                            obscureText: _obscureConfirmPassword,
                            textInputAction: TextInputAction.done,
                            style: TextStyle(fontWeight: FontWeight.w600, color: colors.textPrimary),
                            decoration: _fieldDecoration(
                              colors: colors,
                              label: l10n.confirmNewPasswordLabel,
                              icon: Icons.lock_reset_rounded,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureConfirmPassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  color: colors.textSecondary,
                                ),
                                onPressed: () {
                                  setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
                                },
                              ),
                            ),
                            validator: (v) {
                              if (v != _passwordController.text) {
                                return l10n.passwordsDontMatch;
                              }
                              return null;
                            },
                          ),
                        ],
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
                      onPressed: _continue,
                      child: Text(
                        l10n.continueAction,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.7,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
