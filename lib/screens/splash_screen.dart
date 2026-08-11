import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../theme/app_colors.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: colors.scaffoldBg,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 116,
                  height: 116,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: colors.accent.withValues(alpha: 0.25), width: 1.4),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(20),
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
                  child: Image.asset(
                    'assets/icon/app_icon_foreground.png',
                    width: 56,
                    height: 56,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
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
            const SizedBox(height: 40),
            SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2.2, color: colors.accent),
            ),
          ],
        ),
      ),
    );
  }
}
