import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

// ✅ Admin panel থেকে users/{uid}.disabled = true হলে এই gate ইউজারকে
// অ্যাপ ব্যবহার করতে দেয় না, sign-out করার অপশন দেখায়।
class AccountStatusGate extends StatelessWidget {
  const AccountStatusGate({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return child;

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
      builder: (context, snapshot) {
        final disabled = snapshot.data?.data()?['disabled'] as bool? ?? false;

        if (!disabled) return child;

        final l10n = AppLocalizations.of(context)!;
        return Scaffold(
          body: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.block, size: 56, color: Colors.redAccent),
                    const SizedBox(height: 16),
                    Text(
                      l10n.accountDisabledTitle,
                      style: Theme.of(context).textTheme.titleLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.accountDisabledMessage,
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: () => FirebaseAuth.instance.signOut(),
                      child: Text(l10n.logout),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
