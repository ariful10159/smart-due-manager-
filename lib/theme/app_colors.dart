import 'package:flutter/material.dart';
import '../widgets/app_settings_scope.dart';

class AppColors {
  final Color scaffoldBg;
  final Color surface;
  final Color surfaceAlt;
  final Color borderColor;
  final Color textPrimary;
  final Color textSecondary;
  final Color hintColor;
  final Color accent;
  final Color accentAlt;
  final Color due;
  final Color clear;
  final Color warn;
  final Color info;

  const AppColors({
    required this.scaffoldBg,
    required this.surface,
    required this.surfaceAlt,
    required this.borderColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.hintColor,
    required this.accent,
    required this.accentAlt,
    required this.due,
    required this.clear,
    required this.warn,
    required this.info,
  });

  // ✅ যেকোনো widget এর build() এর ভেতর থেকে কল করলেই dark/light অনুযায়ী সঠিক কালার পাবেন
  factory AppColors.of(BuildContext context) {
    final settings = AppSettingsScope.settingsOf(context);
    return settings.isDarkMode
        ? AppColors.dark(settings.accentColor)
        : AppColors.light(settings.accentColor);
  }

  // ✅ Navy-tinted ডার্ক থিম — আগে প্রায় কালো (near-black) লাগত, এখন স্পষ্ট নেভি ব্লু আন্ডারটোন
  factory AppColors.dark(Color accent) {
    return AppColors(
      scaffoldBg: const Color(0xFF0A0E1C),
      surface: const Color(0xFF121A2E),
      surfaceAlt: const Color(0xFF182240),
      borderColor: const Color(0xFF293654),
      textPrimary: Colors.white,
      textSecondary: const Color(0xFF95A0BD),
      hintColor: const Color(0xFF5D6980),
      accent: accent,
      accentAlt: const Color(0xFF8B5CF6),
      due: const Color(0xFFEF4444),
      clear: const Color(0xFF10B981),
      warn: const Color(0xFFF59E0B),
      info: const Color(0xFF3B82F6),
    );
  }

  factory AppColors.light(Color accent) {
    return AppColors(
      scaffoldBg: const Color(0xFFF4F4F9),
      surface: Colors.white,
      surfaceAlt: const Color(0xFFF0F0F6),
      borderColor: const Color(0xFFE2E2EC),
      textPrimary: const Color(0xFF16161D),
      textSecondary: const Color(0xFF6B6B7D),
      hintColor: const Color(0xFFA0A0B2),
      accent: accent,
      accentAlt: const Color(0xFF8B5CF6),
      due: const Color(0xFFDC2626),
      clear: const Color(0xFF059669),
      warn: const Color(0xFFD97706),
      info: const Color(0xFF2563EB),
    );
  }
}