import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';

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

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final error = await AuthService.register(
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      password: _passwordController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.redAccent.shade400,
          elevation: 8,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: Row(
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.white, size: 26),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  error,
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
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
                color: primaryColor.withValues(alpha: 0.18),
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
                color: primaryColor.withValues(alpha: 0.08),
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
                            color: theme.cardColor,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: primaryColor.withValues(alpha: 0.12),
                                blurRadius: 24,
                                offset: const Offset(0, 8),
                              )
                            ],
                            border: Border.all(color: primaryColor.withValues(alpha: 0.2), width: 1.5),
                          ),
                          child: Icon(
                            Icons.person_add_alt_1_rounded,
                            size: 44,
                            color: primaryColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // --- Title & Subtitle Hero Section ---
                      Text(
                        "Create Account",
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: theme.colorScheme.onSurface,
                          letterSpacing: -0.5,
                          fontSize: 28,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Join us and manage your transactions smartly",
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 36),

                      // ─── 💳 ULTRA PRECISE LUXURY CARD CONTAINER ───
                      Container(
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 32,
                              offset: const Offset(0, 16),
                            ),
                          ],
                          border: Border.all(color: Colors.grey.shade200.withValues(alpha: 0.6), width: 1),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            children: [
                              // 1. Full Name Input
                              TextFormField(
                                controller: _nameController,
                                textInputAction: TextInputAction.next,
                                style: const TextStyle(fontWeight: FontWeight.w600),
                                decoration: InputDecoration(
                                  labelText: "Full Name",
                                  labelStyle: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w500),
                                  prefixIcon: Icon(Icons.person_outline_rounded, color: primaryColor.withValues(alpha: 0.7)),
                                  contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide(color: primaryColor, width: 2),
                                  ),
                                ),
                                validator: (v) => v == null || v.trim().isEmpty ? "আপনার নাম দিন" : null,
                              ),
                              const SizedBox(height: 20),

                              // 2. Phone Number Input
                              TextFormField(
                                controller: _phoneController,
                                keyboardType: TextInputType.phone,
                                textInputAction: TextInputAction.next,
                                style: const TextStyle(fontWeight: FontWeight.w600),
                                decoration: InputDecoration(
                                  labelText: "Phone Number",
                                  hintText: "01XXXXXXXXX",
                                  hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                                  labelStyle: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w500),
                                  prefixIcon: Icon(Icons.phone_outlined, color: primaryColor.withValues(alpha: 0.7)),
                                  contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide(color: primaryColor, width: 2),
                                  ),
                                ),
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) return "ফোন নাম্বার দিন";
                                  if (v.trim().length < 11) return "সঠিক ১১ ডিজিটের ফোন নাম্বার দিন";
                                  return null;
                                },
                              ),
                              const SizedBox(height: 20),

                              // 3. Password Input
                              TextFormField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                textInputAction: TextInputAction.next,
                                style: const TextStyle(fontWeight: FontWeight.w600),
                                decoration: InputDecoration(
                                  labelText: "Password",
                                  labelStyle: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w500),
                                  prefixIcon: Icon(Icons.lock_outline_rounded, color: primaryColor.withValues(alpha: 0.7)),
                                  contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide(color: primaryColor, width: 2),
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                      color: Colors.grey.shade500,
                                    ),
                                    onPressed: () {
                                      setState(() => _obscurePassword = !_obscurePassword);
                                    },
                                  ),
                                ),
                                validator: (v) {
                                  if (v == null || v.isEmpty) return "পাসওয়ার্ড দিন";
                                  if (v.length < 6) return "কমপক্ষে ৬ ক্যারেক্টার দিন";
                                  return null;
                                },
                              ),
                              const SizedBox(height: 20),

                              // 4. Confirm Password Input
                              TextFormField(
                                controller: _confirmPasswordController,
                                obscureText: _obscureConfirmPassword,
                                textInputAction: TextInputAction.done,
                                style: const TextStyle(fontWeight: FontWeight.w600),
                                decoration: InputDecoration(
                                  labelText: "Confirm Password",
                                  labelStyle: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w500),
                                  prefixIcon: Icon(Icons.lock_reset_rounded, color: primaryColor.withValues(alpha: 0.7)),
                                  contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide(color: primaryColor, width: 2),
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscureConfirmPassword
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                      color: Colors.grey.shade500,
                                    ),
                                    onPressed: () {
                                      setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
                                    },
                                  ),
                                ),
                                validator: (v) {
                                  if (v != _passwordController.text) {
                                    return "পাসওয়ার্ড মিলছে না";
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // ─── 🚀 HIGH-GLOSS PREMIUM ELITE ACTION BUTTON ───
                      Container(
                        height: 56,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          gradient: LinearGradient(
                            colors: [
                              primaryColor,
                              primaryColor.withBlue(220).withGreen(100),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: primaryColor.withValues(alpha: 0.35),
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
                          onPressed: _isLoading ? null : _register,
                          child: _isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Text(
                                  "Get Started",
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
                            "আগে থেকেই অ্যাকাউন্ট আছে? ",
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 14, fontWeight: FontWeight.w500),
                          ),
                          GestureDetector(
                            onTap: _isLoading
                                ? null
                                : () {
                                    Navigator.of(context).pushReplacement(
                                      MaterialPageRoute(
                                        builder: (_) => const LoginScreen(),
                                      ),
                                    );
                                  },
                            child: Text(
                              "Login করুন",
                              style: TextStyle(
                                color: primaryColor,
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