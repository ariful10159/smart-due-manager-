import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
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

  // 🎨 Shared dark navy palette — matches the rest of the app
  static const Color _scaffoldBg = Color(0xFF0F0F14);
  static const Color _surface = Color(0xFF1B1B24);
  static const Color _surfaceAlt = Color(0xFF20202B);
  static const Color _borderColor = Color(0xFF2C2C3A);
  static const Color _textPrimary = Colors.white;
  static const Color _textSecondary = Color(0xFF9A9AAE);
  static const Color _hintColor = Color(0xFF5C5C6E);
  static const Color _accent = Color(0xFF6366F1); // Indigo
  static const Color _accentAlt = Color(0xFF8B5CF6); // Violet
  static const Color _due = Color(0xFFEF4444);

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: _due,
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
    required String label,
    required IconData icon,
    required Color iconColor,
    String? hint,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: const TextStyle(color: _textSecondary, fontSize: 13),
      hintStyle: const TextStyle(color: _hintColor, fontSize: 13.5),
      prefixIcon: Padding(
        padding: const EdgeInsets.all(12),
        child: Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, color: iconColor, size: 16),
        ),
      ),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: _surfaceAlt,
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _accent, width: 1.6),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _due, width: 1.2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _due, width: 1.6),
      ),
      errorStyle: const TextStyle(color: _due, fontSize: 11.5),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _scaffoldBg,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // ✅ Subtle dot-grid texture across the whole background
          Positioned.fill(
            child: CustomPaint(painter: _DotGridPainter()),
          ),

          // ✅ Decorative glow blobs
          Positioned(
            top: -90,
            right: -70,
            child: _GlowBlob(size: 240, color: _accent.withOpacity(0.22)),
          ),
          Positioned(
            top: 120,
            left: -100,
            child: _GlowBlob(size: 200, color: _accentAlt.withOpacity(0.16)),
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
                                    color: _accent.withOpacity(0.25),
                                    width: 1.4,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.all(22),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [_accent, _accentAlt],
                                  ),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: _accent.withOpacity(0.45),
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
                            shaderCallback: (bounds) => const LinearGradient(
                              colors: [_textPrimary, Color(0xFFC7C7E0)],
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
                          const Text(
                            "আপনার হিসাব, আপনার নিয়ন্ত্রণে",
                            style: TextStyle(
                              fontSize: 13,
                              color: _textSecondary,
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
                                gradient: const LinearGradient(
                                  colors: [_surface, _surfaceAlt],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(color: _borderColor),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.35),
                                    blurRadius: 28,
                                    offset: const Offset(0, 16),
                                  ),
                                  BoxShadow(
                                    color: _accent.withOpacity(0.06),
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
                                            gradient: const LinearGradient(
                                              colors: [_accent, _accentAlt],
                                              begin: Alignment.topCenter,
                                              end: Alignment.bottomCenter,
                                            ),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        const Text(
                                          "Welcome Back",
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w800,
                                            color: _textPrimary,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const Padding(
                                      padding: EdgeInsets.only(left: 14, top: 3),
                                      child: Text(
                                        "Login করে চালিয়ে যান",
                                        style: TextStyle(fontSize: 12, color: _textSecondary),
                                      ),
                                    ),
                                    const SizedBox(height: 24),

                                    TextFormField(
                                      controller: _phoneController,
                                      keyboardType: TextInputType.phone,
                                      style: const TextStyle(color: _textPrimary, fontSize: 14.5),
                                      decoration: _fieldDecoration(
                                        label: "Phone Number",
                                        icon: Icons.phone_rounded,
                                        iconColor: _accent,
                                        hint: "01XXXXXXXXX",
                                      ),
                                      validator: (v) => v == null || v.trim().isEmpty
                                          ? "ফোন নাম্বার দিন"
                                          : null,
                                    ),
                                    const SizedBox(height: 16),

                                    TextFormField(
                                      controller: _passwordController,
                                      obscureText: _obscurePassword,
                                      style: const TextStyle(color: _textPrimary, fontSize: 14.5),
                                      decoration: _fieldDecoration(
                                        label: "Password",
                                        icon: Icons.lock_rounded,
                                        iconColor: _accentAlt,
                                        suffixIcon: IconButton(
                                          icon: Icon(
                                            _obscurePassword
                                                ? Icons.visibility_rounded
                                                : Icons.visibility_off_rounded,
                                            color: _textSecondary,
                                            size: 20,
                                          ),
                                          onPressed: () {
                                            setState(() => _obscurePassword = !_obscurePassword);
                                          },
                                        ),
                                      ),
                                      validator: (v) =>
                                          v == null || v.isEmpty ? "পাসওয়ার্ড দিন" : null,
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
                                        child: const Text(
                                          "Forgot Password?",
                                          style: TextStyle(
                                            color: _accent,
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
                                                    _accent.withOpacity(0.5),
                                                    _accentAlt.withOpacity(0.5),
                                                  ]
                                                : [_accent, _accentAlt],
                                            begin: Alignment.centerLeft,
                                            end: Alignment.centerRight,
                                          ),
                                          boxShadow: _isLoading
                                              ? []
                                              : [
                                                  BoxShadow(
                                                    color: _accent.withOpacity(0.4),
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
                                                      children: const [
                                                        Text(
                                                          "Login",
                                                          style: TextStyle(
                                                            color: Colors.white,
                                                            fontWeight: FontWeight.w800,
                                                            fontSize: 15.5,
                                                            letterSpacing: 0.3,
                                                          ),
                                                        ),
                                                        SizedBox(width: 8),
                                                        Icon(
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
                              text: const TextSpan(
                                style: TextStyle(
                                  fontSize: 13,
                                  color: _textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                                children: [
                                  TextSpan(text: "নতুন অ্যাকাউন্ট? "),
                                  TextSpan(
                                    text: "Register করুন",
                                    style: TextStyle(
                                      color: _accent,
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
                                color: _hintColor,
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
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.035)
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
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}