import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../theme/app_colors.dart';

// ✅ প্রথমবার অ্যাপ খোলা (এবং লগইন করা না থাকা) ইউজারকে একটামাত্র স্ক্রিনে
// অ্যাপের মূল ভ্যালু বুঝিয়ে দেওয়ার জন্য — আগে multi-page walkthrough ছিল,
// কিন্তু একটা সিঙ্গেল, দ্রুত দেখা যায় এমন স্ক্রিনই যথেষ্ট মনে হওয়ায় এক পেজে
// নামিয়ে আনা হলো। একটামাত্র AnimationController দিয়ে icon → title →
// subtitle → feature chips → button — এই ক্রমে staggered entrance অ্যানিমেশন,
// আর icon-এর পেছনে একটা ধীর, চিরস্থায়ী "breathing" glow।
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.onDone});

  final VoidCallback onDone;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> with TickerProviderStateMixin {
  late final AnimationController _entrance;
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000))..forward();
    _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 2600))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _entrance.dispose();
    _pulse.dispose();
    super.dispose();
  }

  // ✅ _entrance এর [start,end] অংশটুকু 0..1 এ নরমালাইজ করে দেয়, যাতে প্রতিটা
  // উপাদান একই কন্ট্রোলারে নিজের নিজের সময়ে (staggered) অ্যানিমেট হতে পারে
  double _t(double start, double end, [Curve curve = Curves.easeOutCubic]) {
    final v = _entrance.value;
    if (v <= start) return 0;
    if (v >= end) return 1;
    return curve.transform((v - start) / (end - start));
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final l10n = AppLocalizations.of(context)!;

    final features = [
      (Icons.account_balance_wallet_rounded, l10n.onboardingFeature1),
      (Icons.notifications_active_rounded, l10n.onboardingFeature2),
      (Icons.receipt_long_rounded, l10n.onboardingFeature3),
    ];

    return Scaffold(
      backgroundColor: colors.scaffoldBg,
      body: AnimatedBuilder(
        animation: Listenable.merge([_entrance, _pulse]),
        builder: (context, _) {
          // ✅ easeOutBack ইচ্ছাকৃতভাবে 1.0 ছাড়িয়ে যায় (একটু "বাউন্স" পাওয়ার
          // জন্য) — তাই scale এ clamp না করে সরাসরি ব্যবহার করা হচ্ছে, কিন্তু
          // opacity তে অবশ্যই clamp করতে হবে (নাহলে ঋণাত্মক/১-এর বেশি opacity এরর দেয়)
          final iconScale = _t(0.0, 0.62, Curves.easeOutBack);
          final iconOpacity = _t(0.0, 0.32).clamp(0.0, 1.0);
          final glowAlpha = 0.16 + _pulse.value * 0.12;

          final titleT = _t(0.30, 0.62);
          final subtitleT = _t(0.42, 0.72);
          final chipsT = _t(0.55, 0.85);
          final buttonT = _t(0.72, 1.0);

          return Stack(
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(0, -0.5),
                      radius: 1.2,
                      colors: [colors.accent.withValues(alpha: glowAlpha), colors.scaffoldBg],
                      stops: const [0.0, 0.75],
                    ),
                  ),
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    children: [
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Opacity(
                              opacity: iconOpacity,
                              child: Transform.scale(
                                scale: iconScale,
                                child: Container(
                                  width: 132,
                                  height: 132,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [colors.accent, colors.accentAlt],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: colors.accent.withValues(alpha: 0.4),
                                        blurRadius: 36,
                                        spreadRadius: 2,
                                        offset: const Offset(0, 16),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.account_balance_wallet_rounded,
                                    size: 58,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 40),
                            Opacity(
                              opacity: titleT,
                              child: Transform.translate(
                                offset: Offset(0, (1 - titleT) * 16),
                                child: Text(
                                  l10n.onboardingTitle,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 27,
                                    fontWeight: FontWeight.w900,
                                    color: colors.textPrimary,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            Opacity(
                              opacity: subtitleT,
                              child: Transform.translate(
                                offset: Offset(0, (1 - subtitleT) * 16),
                                child: Text(
                                  l10n.onboardingSubtitle,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 15,
                                    height: 1.55,
                                    color: colors.textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 30),
                            Opacity(
                              opacity: chipsT,
                              child: Transform.translate(
                                offset: Offset(0, (1 - chipsT) * 16),
                                child: Wrap(
                                  alignment: WrapAlignment.center,
                                  spacing: 10,
                                  runSpacing: 10,
                                  children: features.map((f) {
                                    return Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                                      decoration: BoxDecoration(
                                        color: colors.surface,
                                        borderRadius: BorderRadius.circular(999),
                                        border: Border.all(color: colors.borderColor),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(f.$1, size: 15, color: colors.accent),
                                          const SizedBox(width: 6),
                                          Text(
                                            f.$2,
                                            style: TextStyle(
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.w700,
                                              color: colors.textPrimary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Opacity(
                        opacity: buttonT,
                        child: Transform.translate(
                          offset: Offset(0, (1 - buttonT) * 20),
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 20),
                            child: SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(18),
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [colors.accent, colors.accentAlt],
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
                                  onPressed: widget.onDone,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        l10n.onboardingGetStarted,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          letterSpacing: 0.4,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
                                    ],
                                  ),
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
            ],
          );
        },
      ),
    );
  }
}
