import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';
import 'login_screen.dart';
import 'otp_verification_screen.dart';
import 'privacy_policy_screen.dart';
import 'terms_of_service_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreedToTerms = false;

  final _privacyPolicyTap = TapGestureRecognizer();
  final _termsOfServiceTap = TapGestureRecognizer();

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _privacyPolicyTap.dispose();
    _termsOfServiceTap.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    final l10n = AppLocalizations.of(context)!;

    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.agreeToTermsRequired)),
      );
      return;
    }

    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text.trim();

    // ✅ সরাসরি অ্যাকাউন্ট তৈরি না করে আগে ফোন নাম্বার OTP দিয়ে ভেরিফাই করা হয়
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => OtpVerificationScreen(
          phone: phone,
          verifyButtonLabel: l10n.verifyAndCreateAccount,
          onVerify: (verificationId, smsCode) => AuthService.verifyOtpAndRegister(
            name: name,
            phone: phone,
            password: password,
            verificationId: verificationId,
            smsCode: smsCode,
          ),
          onAutoVerify: (credential) => AuthService.registerWithAutoVerifiedCredential(
            name: name,
            phone: phone,
            password: password,
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

  Widget _buildAgreementRow(AppColors colors, AppLocalizations l10n) {
    final linkStyle = TextStyle(
      color: colors.accent,
      fontWeight: FontWeight.w700,
      fontSize: 13,
      decoration: TextDecoration.underline,
      decorationColor: colors.accent,
    );
    final textStyle = TextStyle(color: colors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: Checkbox(
            value: _agreedToTerms,
            activeColor: colors.accent,
            visualDensity: VisualDensity.compact,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            onChanged: (v) => setState(() => _agreedToTerms = v ?? false),
          ),
        ),
        const SizedBox(width: 10),
        // ✅ ইচ্ছাকৃতভাবে পুরো টেক্সটকে GestureDetector দিয়ে wrap করা হয়নি — তাহলে
        // Privacy Policy/Terms লিংকে ট্যাপ করলে সেটার নিজস্ব TapGestureRecognizer এর
        // পাশাপাশি বাইরের GestureDetector ও একসাথে ফায়ার করত, checkbox ভুলবশত টগল
        // হয়ে যেত। তাই checkbox toggle শুধু checkbox থেকেই হয়।
        Expanded(
          child: Text.rich(
            TextSpan(
              style: textStyle,
              children: [
                TextSpan(text: l10n.agreementPrefix),
                TextSpan(
                  text: l10n.privacyPolicy,
                  style: linkStyle,
                  recognizer: _privacyPolicyTap
                    ..onTap = () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
                        ),
                ),
                TextSpan(text: l10n.agreementConnector),
                TextSpan(
                  text: l10n.termsOfService,
                  style: linkStyle,
                  recognizer: _termsOfServiceTap
                    ..onTap = () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const TermsOfServiceScreen()),
                        ),
                ),
                TextSpan(text: l10n.agreementSuffix),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: colors.scaffoldBg,
      body: Stack(
        children: [
          // ─── 🎨 LUXURY BACKGROUND BLOB LIGHTS ───
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colors.accent.withValues(alpha: 0.18),
              ),
            ),
          ),
          Positioned(
            bottom: -150,
            left: -100,
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colors.accentAlt.withValues(alpha: 0.08),
              ),
            ),
          ),

          // ─── 📦 MAIN INTERFACE SCROLL VIEW ───
          SafeArea(
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
                      // --- Premium Branding Icon ---
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
                          child: Icon(
                            Icons.person_add_alt_1_rounded,
                            size: 44,
                            color: colors.accent,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // --- Title & Subtitle Hero Section ---
                      Text(
                        l10n.createAccountTitle,
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
                        l10n.joinUsDesc,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 36),

                      // ─── 💳 ULTRA PRECISE LUXURY CARD CONTAINER ───
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
                              // 1. Full Name Input
                              TextFormField(
                                controller: _nameController,
                                textInputAction: TextInputAction.next,
                                style: TextStyle(fontWeight: FontWeight.w600, color: colors.textPrimary),
                                decoration: _fieldDecoration(
                                  colors: colors,
                                  label: l10n.fullName,
                                  icon: Icons.person_outline_rounded,
                                ),
                                validator: (v) => v == null || v.trim().isEmpty ? l10n.enterYourName : null,
                              ),
                              const SizedBox(height: 20),

                              // 2. Phone Number Input
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

                              // 3. Password Input
                              TextFormField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                textInputAction: TextInputAction.next,
                                style: TextStyle(fontWeight: FontWeight.w600, color: colors.textPrimary),
                                decoration: _fieldDecoration(
                                  colors: colors,
                                  label: l10n.passwordLabel,
                                  icon: Icons.lock_outline_rounded,
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
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

                              // 4. Confirm Password Input
                              TextFormField(
                                controller: _confirmPasswordController,
                                obscureText: _obscureConfirmPassword,
                                textInputAction: TextInputAction.done,
                                style: TextStyle(fontWeight: FontWeight.w600, color: colors.textPrimary),
                                decoration: _fieldDecoration(
                                  colors: colors,
                                  label: l10n.confirmPasswordLabel,
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
                      const SizedBox(height: 20),

                      // ─── ✅ PRIVACY POLICY / TERMS AGREEMENT CHECKBOX ───
                      _buildAgreementRow(colors, l10n),
                      const SizedBox(height: 20),

                      // ─── 🚀 HIGH-GLOSS PREMIUM ELITE ACTION BUTTON ───
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
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          onPressed: _register,
                          child: Text(
                            l10n.getStarted,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.7,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),

                      // ─── 🔗 MINIMALIST CLEAN FOOTER ───
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            l10n.alreadyHaveAccount,
                            style: TextStyle(color: colors.textSecondary, fontSize: 14, fontWeight: FontWeight.w500),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute(
                                  builder: (_) => const LoginScreen(),
                                ),
                              );
                            },
                            child: Text(
                              l10n.loginNow,
                              style: TextStyle(
                                color: colors.accent,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                decoration: TextDecoration.underline,
                                decorationThickness: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
