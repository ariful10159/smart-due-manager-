import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';
import 'home_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final error = await AuthService.login(
      phone: _phoneController.text.trim(),
      password: _passwordController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (error != null) {
      final colors = AppColors.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: colors.due,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(14),
          content: Text(error, style: const TextStyle(fontWeight: FontWeight.w600)),
        ),
      );
      return;
    }

    // ✅ লগইন সফল — সরাসরি Home এ পাঠিয়ে দেওয়া হচ্ছে,
    // authStateChanges stream এর উপর নির্ভর না করে
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (route) => false,
    );
  }

  InputDecoration _fieldDecoration({
    required AppColors colors,
    required String label,
    required IconData icon,
    required Color iconColor,
    String? hint,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: TextStyle(color: colors.textSecondary, fontSize: 13),
      hintStyle: TextStyle(color: colors.hintColor, fontSize: 13.5),
      prefixIcon: Padding(
        padding: const EdgeInsets.all(12),
        child: Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, color: iconColor, size: 16),
        ),
      ),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: colors.surfaceAlt,
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: colors.borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: colors.borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: colors.accent, width: 1.6),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: colors.due, width: 1.2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: colors.due, width: 1.6),
      ),
      errorStyle: TextStyle(color: colors.due, fontSize: 11.5),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: colors.scaffoldBg,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // ✅ Subtle dot-grid texture across the whole background
          Positioned.fill(
            child: CustomPaint(painter: _DotGridPainter(color: colors.textPrimary)),
          ),

          // ✅ Decorative glow blobs
          Positioned(
            top: -90,
            right: -70,
            child: _GlowBlob(size: 240, color: colors.accent.withValues(alpha: 0.22)),
          ),
          Positioned(
            top: 120,
            left: -100,
            child: _GlowBlob(size: 200, color: colors.accentAlt.withValues(alpha: 0.16)),
          ),

          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: IntrinsicHeight(
                      child: Column(
                        children: [
                          const SizedBox(height: 46),

                          // ✅ Hero logo block
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: 108,
                                height: 108,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: colors.accent.withValues(alpha: 0.25),
                                    width: 1.4,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.all(22),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [colors.accent, colors.accentAlt],
                                  ),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: colors.accent.withValues(alpha: 0.45),
                                      blurRadius: 34,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.account_balance_wallet_rounded,
                                  size: 38,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          ShaderMask(
                            shaderCallback: (bounds) => LinearGradient(
                              colors: [colors.textPrimary, colors.textSecondary],
                            ).createShader(bounds),
                            child: const Text(
                              "Smart Due",
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            l10n.loginTagline,
                            style: TextStyle(
                              fontSize: 13,
                              color: colors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),

                          const SizedBox(height: 36),

                          // ✅ Elevated glassy form card
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 22),
                            child: Container(
                              padding: const EdgeInsets.fromLTRB(20, 24, 20, 22),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [colors.surface, colors.surfaceAlt],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(color: colors.borderColor),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.35),
                                    blurRadius: 28,
                                    offset: const Offset(0, 16),
                                  ),
                                  BoxShadow(
                                    color: colors.accent.withValues(alpha: 0.06),
                                    blurRadius: 40,
                                    offset: const Offset(0, -6),
                                  ),
                                ],
                              ),
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          width: 4,
                                          height: 22,
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [colors.accent, colors.accentAlt],
                                              begin: Alignment.topCenter,
                                              end: Alignment.bottomCenter,
                                            ),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Text(
                                          l10n.welcomeBack,
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w800,
                                            color: colors.textPrimary,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(left: 14, top: 3),
                                      child: Text(
                                        l10n.loginToContinue,
                                        style: TextStyle(fontSize: 12, color: colors.textSecondary),
                                      ),
                                    ),
                                    const SizedBox(height: 24),

                                    TextFormField(
                                      controller: _phoneController,
                                      keyboardType: TextInputType.phone,
                                      style: TextStyle(color: colors.textPrimary, fontSize: 14.5),
                                      decoration: _fieldDecoration(
                                        colors: colors,
                                        label: l10n.phoneNumber,
                                        icon: Icons.phone_rounded,
                                        iconColor: colors.accent,
                                        hint: l10n.phoneHintExample,
                                      ),
                                      validator: (v) => v == null || v.trim().isEmpty
                                          ? l10n.enterPhoneNumber
                                          : null,
                                    ),
                                    const SizedBox(height: 16),

                                    TextFormField(
                                      controller: _passwordController,
                                      obscureText: _obscurePassword,
                                      style: TextStyle(color: colors.textPrimary, fontSize: 14.5),
                                      decoration: _fieldDecoration(
                                        colors: colors,
                                        label: l10n.passwordLabel,
                                        icon: Icons.lock_rounded,
                                        iconColor: colors.accentAlt,
                                        suffixIcon: IconButton(
                                          icon: Icon(
                                            _obscurePassword
                                                ? Icons.visibility_rounded
                                                : Icons.visibility_off_rounded,
                                            color: colors.textSecondary,
                                            size: 20,
                                          ),
                                          onPressed: () {
                                            setState(() => _obscurePassword = !_obscurePassword);
                                          },
                                        ),
                                      ),
                                      validator: (v) =>
                                          v == null || v.isEmpty ? l10n.enterPassword : null,
                                    ),

                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: TextButton(
                                        onPressed: _isLoading ? null : () {},
                                        style: TextButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                                          minimumSize: Size.zero,
                                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        ),
                                        child: Text(
                                          l10n.forgotPassword,
                                          style: TextStyle(
                                            color: colors.accent,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ),

                                    const SizedBox(height: 12),

                                    // ✅ Gradient login button
                                    SizedBox(
                                      height: 54,
                                      child: DecoratedBox(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(15),
                                          gradient: LinearGradient(
                                            colors: _isLoading
                                                ? [
                                                    colors.accent.withValues(alpha: 0.5),
                                                    colors.accentAlt.withValues(alpha: 0.5),
                                                  ]
                                                : [colors.accent, colors.accentAlt],
                                            begin: Alignment.centerLeft,
                                            end: Alignment.centerRight,
                                          ),
                                          boxShadow: _isLoading
                                              ? []
                                              : [
                                                  BoxShadow(
                                                    color: colors.accent.withValues(alpha: 0.4),
                                                    blurRadius: 18,
                                                    offset: const Offset(0, 10),
                                                  ),
                                                ],
                                        ),
                                        child: Material(
                                          color: Colors.transparent,
                                          child: InkWell(
                                            borderRadius: BorderRadius.circular(15),
                                            onTap: _isLoading ? null : _login,
                                            child: Center(
                                              child: _isLoading
                                                  ? const SizedBox(
                                                      width: 22,
                                                      height: 22,
                                                      child: CircularProgressIndicator(
                                                        strokeWidth: 2.2,
                                                        color: Colors.white,
                                                      ),
                                                    )
                                                  : Row(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        Text(
                                                          l10n.loginAction,
                                                          style: const TextStyle(
                                                            color: Colors.white,
                                                            fontWeight: FontWeight.w800,
                                                            fontSize: 15.5,
                                                            letterSpacing: 0.3,
                                                          ),
                                                        ),
                                                        const SizedBox(width: 8),
                                                        const Icon(
                                                          Icons.arrow_forward_rounded,
                                                          color: Colors.white,
                                                          size: 18,
                                                        ),
                                                      ],
                                                    ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 22),

                          // ✅ Register link
                          TextButton(
                            onPressed: _isLoading
                                ? null
                                : () {
                                    Navigator.of(context).pushReplacement(
                                      MaterialPageRoute(
                                        builder: (_) => const RegisterScreen(),
                                      ),
                                    );
                                  },
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            child: RichText(
                              text: TextSpan(
                                style: TextStyle(
                                  fontSize: 13,
                                  color: colors.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                                children: [
                                  TextSpan(text: l10n.newAccountQuestion),
                                  TextSpan(
                                    text: l10n.registerNow,
                                    style: TextStyle(
                                      color: colors.accent,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const Spacer(),

                          Padding(
                            padding: const EdgeInsets.only(bottom: 18, top: 10),
                            child: Text(
                              "Smart Due v1.0",
                              style: TextStyle(
                                fontSize: 10.5,
                                color: colors.hintColor,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// Decorative helpers
// ============================================================

class _GlowBlob extends StatelessWidget {
  const _GlowBlob({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}

class _DotGridPainter extends CustomPainter {
  _DotGridPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.035)
      ..style = PaintingStyle.fill;

    const spacing = 26.0;
    const radius = 1.1;

    for (double y = 0; y < size.height; y += spacing) {
      for (double x = 0; x < size.width; x += spacing) {
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DotGridPainter oldDelegate) => oldDelegate.color != color;
}
