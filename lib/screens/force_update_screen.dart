import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_localizations.dart';

// ✅ ইনস্টল করা app version, appConfig/main.minRequiredVersion এর নিচে থাকলে
// এবং forceUpdateEnabled == true থাকলে AppConfigGate এই স্ক্রিন দেখায় — পুরো
// অ্যাপ ব্লক করে, Update Now ছাড়া আর কোনো উপায় নেই।
class ForceUpdateScreen extends StatelessWidget {
  const ForceUpdateScreen({super.key, required this.minRequiredVersion, this.playStoreUrl});

  final String minRequiredVersion;
  final String? playStoreUrl;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.system_update_rounded, size: 56, color: Colors.blueAccent),
                const SizedBox(height: 16),
                Text(
                  l10n.forceUpdateTitle,
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.forceUpdateMessage(minRequiredVersion),
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                if ((playStoreUrl ?? '').trim().isNotEmpty)
                  FilledButton(
                    onPressed: () => launchUrl(Uri.parse(playStoreUrl!.trim()), mode: LaunchMode.externalApplication),
                    child: Text(l10n.updateNowButton),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
