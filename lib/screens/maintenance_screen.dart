import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

// ✅ appConfig/main.maintenanceEnabled == true হলে AppConfigGate এই স্ক্রিন দেখায়।
// maintenanceUntil শুধু ETA হিসেবে দেখানো হয় — সময় পার হয়ে গেলেও admin ম্যানুয়ালি
// toggle off না করা পর্যন্ত এই স্ক্রিন সরে না।
class MaintenanceScreen extends StatelessWidget {
  const MaintenanceScreen({super.key, this.message, this.until});

  final String? message;
  final Timestamp? until;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final displayMessage = (message?.trim().isNotEmpty ?? false) ? message!.trim() : l10n.maintenanceDefaultMessage;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.construction_rounded, size: 56, color: Colors.orangeAccent),
                const SizedBox(height: 16),
                Text(
                  l10n.maintenanceTitle,
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  displayMessage,
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                if (until != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    l10n.maintenanceEtaLabel(_formatEta(until!.toDate())),
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatEta(DateTime dt) {
    String pad(int n) => n.toString().padLeft(2, '0');
    return '${dt.year}-${pad(dt.month)}-${pad(dt.day)} ${pad(dt.hour)}:${pad(dt.minute)}';
  }
}
