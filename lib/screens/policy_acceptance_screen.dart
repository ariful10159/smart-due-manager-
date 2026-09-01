import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';
import 'login_screen.dart';
import 'privacy_policy_screen.dart';
import 'terms_of_service_screen.dart';

// ✅ PolicyAcceptanceGate যখন দেখে ইউজারের accepted version, admin panel এ
// পাবলিশ করা বর্তমান version এর চেয়ে পুরনো, তখন এই স্ক্রিন দেখায় — পুরো অ্যাপ
// ব্লক করে, accept না করা পর্যন্ত। Logout করার অপশনও রাখা হয়েছে, যাতে কেউ
// আটকে না পড়ে।
class PolicyAcceptanceScreen extends StatefulWidget {
  const PolicyAcceptanceScreen({super.key, required this.privacyVersion, required this.termsVersion});

  final int privacyVersion;
  final int termsVersion;

  @override
  State<PolicyAcceptanceScreen> createState() => _PolicyAcceptanceScreenState();
}

class _PolicyAcceptanceScreenState extends State<PolicyAcceptanceScreen> {
  bool _agreed = false;
  bool _accepting = false;

  Future<void> _accept() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    setState(() => _accepting = true);
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'acceptedPrivacyVersion': widget.privacyVersion,
        'acceptedPrivacyAt': Timestamp.now(),
        'acceptedTermsVersion': widget.termsVersion,
        'acceptedTermsAt': Timestamp.now(),
      });
      // ✅ Firestore আপডেট হওয়ার পর PolicyAcceptanceGate এর StreamBuilder
      // নিজে থেকেই rebuild হয়ে HomeScreen এ চলে যাবে — এখানে আলাদা navigation লাগে না।
    } finally {
      if (mounted) setState(() => _accepting = false);
    }
  }

  Future<void> _logout() async {
    await AuthService.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: colors.scaffoldBg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.policy_outlined, size: 56, color: Colors.orangeAccent),
              const SizedBox(height: 16),
              Text(
                l10n.policyUpdatedTitle,
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                l10n.policyUpdatedMessage,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              _ReviewRow(
                icon: Icons.privacy_tip_outlined,
                label: l10n.reviewPrivacyPolicy,
                colors: colors,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
                ),
              ),
              const SizedBox(height: 10),
              _ReviewRow(
                icon: Icons.gavel_outlined,
                label: l10n.reviewTermsOfService,
                colors: colors,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const TermsOfServiceScreen()),
                ),
              ),
              const SizedBox(height: 20),

              InkWell(
                onTap: () => setState(() => _agreed = !_agreed),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Checkbox(
                      value: _agreed,
                      activeColor: colors.accent,
                      onChanged: (v) => setState(() => _agreed = v ?? false),
                    ),
                    Expanded(
                      child: Text(
                        l10n.iHaveReviewedAgreement,
                        style: TextStyle(color: colors.textSecondary, fontSize: 13.5, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: (_agreed && !_accepting) ? _accept : null,
                  child: _accepting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                        )
                      : Text(l10n.acceptAndContinue),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _accepting ? null : _logout,
                child: Text(l10n.logout, style: TextStyle(color: colors.textSecondary)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReviewRow extends StatelessWidget {
  const _ReviewRow({required this.icon, required this.label, required this.colors, required this.onTap});

  final IconData icon;
  final String label;
  final AppColors colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: colors.surfaceAlt,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(icon, color: colors.accent, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w700, fontSize: 14),
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: colors.textSecondary, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
