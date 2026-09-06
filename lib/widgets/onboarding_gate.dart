import 'package:flutter/material.dart';

import '../screens/onboarding_screen.dart';
import '../screens/splash_screen.dart';
import '../services/onboarding_service.dart';

// ✅ লগইন করা না থাকলে AuthWrapper সরাসরি LoginScreen দেখায় — এই গেটটা তার
// ঠিক আগে বসে, যাতে ব্যবহারকারী আগে কখনো onboarding walkthrough না দেখে
// থাকলে সেটা একবার দেখানো যায়। ইতিমধ্যে লগইন করা থাকা ইউজার (persisted
// session) এই গেট স্পর্শই করে না, কারণ AuthWrapper তাদের জন্য HomeScreen
// দেখায় — শুধু নতুন/লগড-আউট অবস্থার ইউজারই এটা দেখেন।
class OnboardingGate extends StatefulWidget {
  const OnboardingGate({super.key, required this.child});

  final Widget child;

  @override
  State<OnboardingGate> createState() => _OnboardingGateState();
}

class _OnboardingGateState extends State<OnboardingGate> {
  bool? _hasSeen;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final seen = await OnboardingService.hasSeenOnboarding();
    if (!mounted) return;
    setState(() => _hasSeen = seen);
  }

  Future<void> _complete() async {
    await OnboardingService.markOnboardingSeen();
    if (!mounted) return;
    setState(() => _hasSeen = true);
  }

  @override
  Widget build(BuildContext context) {
    if (_hasSeen == null) return const SplashScreen();
    if (_hasSeen == false) return OnboardingScreen(onDone: _complete);
    return widget.child;
  }
}
