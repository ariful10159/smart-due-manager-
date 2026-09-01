import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../screens/policy_acceptance_screen.dart';
import '../services/app_config_service.dart';

// ✅ লগইন করার পর, HomeScreen দেখানোর আগে — admin panel এ পাবলিশ করা বর্তমান
// Privacy Policy/Terms version এর সাথে ইউজারের সবশেষ accepted version মিলিয়ে
// দেখে। কম হলে PolicyAcceptanceScreen দেখায়, accept না করা পর্যন্ত অ্যাপ ব্যবহার
// করা যায় না। কোনো version কখনো পাবলিশ না হলে (দুটোই 0) এই চেক স্কিপ হয়ে যায় —
// তাই বিল্ট-ইন ডিফল্ট পলিসি ব্যবহারকারীদের এটা প্রভাবিত করে না।
class PolicyAcceptanceGate extends StatelessWidget {
  const PolicyAcceptanceGate({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return child;

    return StreamBuilder<Map<String, dynamic>>(
      stream: AppConfigService.watch(),
      builder: (context, configSnapshot) {
        final config = configSnapshot.data ?? {};
        final currentPrivacyVersion = (config['privacyVersion'] as num?)?.toInt() ?? 0;
        final currentTermsVersion = (config['termsVersion'] as num?)?.toInt() ?? 0;

        if (currentPrivacyVersion == 0 && currentTermsVersion == 0) return child;

        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
          builder: (context, userSnapshot) {
            // ✅ প্রথম snapshot এখনো আসেনি (নেটওয়ার্ক ডিলে) — fail-open, চেক করার মতো
            // ডেটা এখনো নেই। কিন্তু snapshot এসে গেলে (even if the doc doesn't exist —
            // exists=false, data()=null) সেটাকে "কখনো accept করেনি" (version 0) ধরে
            // চেক চালিয়ে যাওয়া হয় — আগে ভুলবশত এই কেসেও fail-open করে ফেলছিল, যার ফলে
            // Firestore-এ users ডকুমেন্ট না থাকা পুরনো/টেস্ট account গুলো কখনোই gate এ পড়ত না।
            if (userSnapshot.connectionState == ConnectionState.waiting) return child;

            final userData = userSnapshot.data?.data() ?? {};
            final acceptedPrivacy = (userData['acceptedPrivacyVersion'] as num?)?.toInt() ?? 0;
            final acceptedTerms = (userData['acceptedTermsVersion'] as num?)?.toInt() ?? 0;

            final needsAcceptance =
                acceptedPrivacy < currentPrivacyVersion || acceptedTerms < currentTermsVersion;

            if (!needsAcceptance) return child;

            return PolicyAcceptanceScreen(
              privacyVersion: currentPrivacyVersion,
              termsVersion: currentTermsVersion,
            );
          },
        );
      },
    );
  }
}
